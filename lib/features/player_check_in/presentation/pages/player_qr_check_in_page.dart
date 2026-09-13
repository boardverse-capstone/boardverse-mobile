import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import 'package:boardverse/features/lobby_management/lobby_routes.dart';
import '../../data/services/qr_image_decoder.dart';
import '../cubit/player_check_in_cubit.dart';

/// Trang check-in tại quán cho Player (BR §21A.7, chiều 2 của check-in 2
/// chiều).
///
/// Hỗ trợ 2 chế độ:
/// - **Camera scanner** (mặc định khi được cấp quyền): dùng `mobile_scanner`
///   để detect QR code 16-char alphanumeric do POS tạo → tự động submit.
/// - **Fallback**: hiển thị QR code reservation để staff quét hoặc đối chiếu
///   khi camera không khả dụng.
///
/// Sau khi backend confirm thành công → hiển thị dialog xác nhận "Check-in
/// thành công" trước khi navigate sang `InGameSessionPage`.
class PlayerQrCheckInPage extends StatelessWidget {
  final String reservationId;
  final String lobbyShareCode;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  /// Callback được gọi sau khi check-in thành công.
  final VoidCallback? onCheckInSuccess;

  const PlayerQrCheckInPage({
    super.key,
    required this.reservationId,
    required this.lobbyShareCode,
    required this.cafeName,
    required this.gameName,
    this.tableNumber = 1,
    this.onCheckInSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlayerCheckInCubit.create(),
      child: _PlayerQrCheckInView(
        reservationId: reservationId,
        lobbyShareCode: lobbyShareCode,
        cafeName: cafeName,
        gameName: gameName,
        tableNumber: tableNumber,
        onCheckInSuccess: onCheckInSuccess,
      ),
    );
  }
}

/// Mode hiển thị của page.
enum _Mode { scanning, fallback }

class _PlayerQrCheckInView extends StatefulWidget {
  final String reservationId;
  final String lobbyShareCode;
  final String cafeName;
  final String gameName;
  final int tableNumber;
  final VoidCallback? onCheckInSuccess;

  const _PlayerQrCheckInView({
    required this.reservationId,
    required this.lobbyShareCode,
    required this.cafeName,
    required this.gameName,
    required this.tableNumber,
    this.onCheckInSuccess,
  });

  @override
  State<_PlayerQrCheckInView> createState() => _PlayerQrCheckInViewState();
}

class _PlayerQrCheckInViewState extends State<_PlayerQrCheckInView> {
  final _tokenController = TextEditingController();

  /// Regex 16-char alphanumeric uppercase (loại trừ 0/1/I/O theo spec backend).
  static final _tokenRegex = RegExp(
    r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{16}$',
  );

  /// Regex để extract token từ URL hoặc JSON (ví dụ: ?token=XXXX hoặc "token":"XXXX")
  static final _tokenExtractRegex = RegExp(
    r'[?&"]?token[&="]?([ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{16})',
    caseSensitive: false,
  );

  /// True khi đã pre-fill input từ cache (chỉ chạy 1 lần).
  bool _cachePrefilled = false;

  /// Mode hiện tại của page.
  _Mode _mode = _Mode.scanning;

  /// Controller cho mobile_scanner — null khi ở mode fallback.
  MobileScannerController? _scannerController;

  /// True khi đã gọi `submitToken` lần đầu từ scan → pause scanner
  /// để tránh submit nhiều lần trong khi đợi response.
  bool _submittedFromScan = false;

  /// True khi đang xin permission lần đầu → hiển thị loading.
  bool _requestingPermission = true;

  @override
  void initState() {
    super.initState();
    _initPermissionAndCache();
  }

  Future<void> _initPermissionAndCache() async {
    // Pre-fill từ cache (nếu có) — best-effort, không block UI.
    final cubit = context.read<PlayerCheckInCubit>();
    final cached = await cubit.loadCachedToken();
    if (!mounted) return;
    if (cached != null && _tokenController.text.isEmpty) {
      _tokenController.text = cached;
      _tokenController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tokenController.text.length),
      );
    }
    _cachePrefilled = true;

    // Xin camera permission.
    await _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    if (!mounted) return;
    setState(() => _requestingPermission = true);

    try {
      var status = await Permission.camera.status;
      if (status.isDenied || status.isRestricted) {
        status = await Permission.camera.request();
      }

      if (!mounted) return;

      if (status.isGranted || status.isLimited) {
        _startScanner();
      } else {
        _showPermissionDeniedDialog();
      }
    } catch (e) {
      if (!mounted) return;
      _showPermissionDeniedDialog();
    } finally {
      if (mounted) {
        setState(() => _requestingPermission = false);
      }
    }
  }

  void _startScanner() {
    _scannerController?.dispose();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      formats: const [BarcodeFormat.qrCode],
      // Bật torch để cải thiện quét trong điều kiện ánh sáng yếu
      torchEnabled: false,
      // Tìm camera sau
      facing: CameraFacing.back,
    );
    if (mounted) {
      setState(() => _mode = _Mode.scanning);
    }
  }

  void _stopScanner() {
    _scannerController?.dispose();
    _scannerController = null;
  }

  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;
    setState(() => _mode = _Mode.fallback);

    final cubit = context.read<PlayerCheckInCubit>();
    if (cubit.state is PlayerCheckInSubmitting) return;
    final status = await Permission.camera.status;
    if (!status.isPermanentlyDenied) return;

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Camera bị chặn'),
        content: const Text(
          'Bạn đã chặn quyền camera. Hãy vào Cài đặt → Ứng dụng → '
          'BoardVerse → Quyền để bật lại. Trong lúc chờ, bạn có thể '
          'đưa mã QR bên dưới cho nhân viên quét.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Đóng'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              openAppSettings();
            },
            child: const Text('Mở cài đặt'),
          ),
        ],
      ),
    );
  }

  void _switchToFallback() {
    _stopScanner();
    if (mounted) {
      setState(() => _mode = _Mode.fallback);
    }
  }

  void _switchToScanning() async {
    final status = await Permission.camera.status;
    if (!status.isGranted && !status.isLimited) {
      if (!mounted) return;
      context.showTopSnackBar(
        'Cần cấp quyền camera để quét QR.',
        isError: true,
      );
      await _requestCameraPermission();
      return;
    }
    if (mounted) {
      _startScanner();
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _stopScanner();
    super.dispose();
  }

  void _onScanDetected(BarcodeCapture capture) {
    if (_submittedFromScan) return;
    final cubit = context.read<PlayerCheckInCubit>();
    if (cubit.state is PlayerCheckInSubmitting) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null) continue;

      // Debug: log raw value để check format QR
      debugPrint('[QR Scan] Raw value: "$value"');
      debugPrint('[QR Scan] Barcode format: ${barcode.format}');

      String? token;
      final normalized = value.trim().toUpperCase();

      // Thử 1: Direct match 16-char token
      if (_tokenRegex.hasMatch(normalized)) {
        token = normalized;
      }
      // Thử 2: Extract từ URL hoặc URI bất kỳ.
      // POS QR payload là deep-link: `boardverse://check-in?token=XXXXX`
      // Theo `.agents/docs/apis_docs/cafe-pos.md` — handle cả scheme này.
      // Regex match `token=XXXX` không phụ thuộc scheme nên handle mọi
      // variant: `boardverse://...?token=`, `https://...?token=`, JSON, v.v.
      final match = _tokenExtractRegex.firstMatch(normalized);
      if (match != null) {
        token = match.group(1);
        debugPrint('[QR Scan] Extracted token: $token');
      }

      // Nếu vẫn không extract được, vẫn hiển thị trong text field
      // để user có thể nhập tay nếu cần
      if (token != null) {
        _submittedFromScan = true;
        _scannerController?.stop();

        _tokenController.text = token;
        _tokenController.selection = TextSelection.fromPosition(
          TextPosition(offset: _tokenController.text.length),
        );

        cubit.submitToken(token);
      } else {
        // Hiển thị raw value trong text field để user xem và xử lý
        debugPrint('[QR Scan] No valid token found, showing raw value');
        _tokenController.text = normalized;
        _tokenController.selection = TextSelection.fromPosition(
          TextPosition(offset: _tokenController.text.length),
        );
      }
      return;
    }
  }

  Future<void> _pasteFromClipboard(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!context.mounted) return;
      context.showTopSnackBar(
        'Clipboard trống. Hãy copy mã QR từ màn hình POS trước.',
        isError: true,
      );
      return;
    }
    setState(() {
      _tokenController.text = text.toUpperCase();
      _tokenController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tokenController.text.length),
      );
    });
  }

  void _submit(BuildContext context) {
    final cubit = context.read<PlayerCheckInCubit>();
    final raw = _tokenController.text.trim();
    if (raw.isEmpty) {
      cubit.submitToken('');
      return;
    }
    cubit.submitToken(raw);
  }

  /// Mở ImagePicker → chọn ảnh QR → decode bằng ML Kit → extract token.
  ///
  /// Dùng cho test/debug khi:
  /// - Không có camera (emulator)
  /// - Muốn quét QR từ screenshot POS thay vì đưa điện thoại qua lại
  ///
  /// Luồng:
  /// 1. Validate token bằng `_tokenRegex` / `_tokenExtractRegex` (giống
  ///    camera scanner)
  /// 2. Pause scanner nếu đang chạy để tránh submit 2 lần
  /// 3. Submit qua cubit như bình thường
  Future<void> _pickAndDecodeQrImage() async {
    if (_decodingImage) return;
    _decodingImage = true;

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        // Không cần maxWidth vì ML Kit tự scale; chỉ để tránh OOM.
        maxWidth: 2048,
      );
      if (image == null) {
        // User huỷ picker — không làm gì.
        return;
      }

      debugPrint('[QR Upload] Picked image: ${image.path}');

      final raw = await QrImageDecoder.decodeFromFile(image.path);
      if (raw == null || raw.trim().isEmpty) {
        if (!mounted) return;
        context.showTopSnackBar(
          'Không tìm thấy mã QR trong ảnh. Hãy chọn ảnh khác rõ hơn.',
          isError: true,
        );
        return;
      }

      debugPrint('[QR Upload] Raw value: "$raw"');

      final normalized = raw.trim().toUpperCase();

      // Dùng cùng logic extract token với camera scanner để đảm bảo
      // nhất quán (handle direct match, URL với token=, JSON, v.v.).
      String? token;
      if (_tokenRegex.hasMatch(normalized)) {
        token = normalized;
      } else {
        final match = _tokenExtractRegex.firstMatch(normalized);
        if (match != null) {
          token = match.group(1);
          debugPrint('[QR Upload] Extracted token: $token');
        }
      }

      if (token == null) {
        if (!mounted) return;
        context.showTopSnackBar(
          'Mã QR trong ảnh không đúng định dạng (cần 16 ký tự alphanumeric).',
          isError: true,
        );
        // Vẫn điền raw value vào text field để user xem.
        _tokenController.text = normalized;
        _tokenController.selection = TextSelection.fromPosition(
          TextPosition(offset: _tokenController.text.length),
        );
        return;
      }

      // Pause scanner (nếu đang chạy) để tránh submit trùng.
      if (_scannerController != null) {
        await _scannerController!.stop();
      }

      _submittedFromScan = true;
      _tokenController.text = token;
      _tokenController.selection = TextSelection.fromPosition(
        TextPosition(offset: _tokenController.text.length),
      );

      if (!mounted) return;
      context.read<PlayerCheckInCubit>().submitToken(token);
    } catch (e, stack) {
      debugPrint('[QR Upload] Error: $e\n$stack');
      if (!mounted) return;
      context.showTopSnackBar(
        'Lỗi khi đọc ảnh: ${e.toString()}',
        isError: true,
      );
    } finally {
      _decodingImage = false;
    }
  }

  /// True khi đang decode ảnh — disable nút để tránh double-tap.
  bool _decodingImage = false;

  /// Hiển thị dialog xác nhận trước khi navigate sang `InGameSessionPage`.
  Future<bool> _showSuccessDialog(
    BuildContext context,
    PlayerCheckInSuccess state,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.success, width: 3),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Expanded(
              child: Text(
                'Check-in thành công!',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.cafeName,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.gameName,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Đã check-in lúc ${_formatTime(state.result.checkedInAt)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Vào phiên chơi'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatTime(DateTime time) {
    final local = time.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _onSuccess(PlayerCheckInSuccess state) async {
    final shouldNavigate = await _showSuccessDialog(context, state);
    if (!mounted || !shouldNavigate) {
      _submittedFromScan = false;
      _scannerController?.start();
      return;
    }

    widget.onCheckInSuccess?.call();

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pushReplacementNamed(
      LobbyRoutes.inGameSession,
      arguments: InGameSessionPageArgs(
        bookingId: state.result.reservationId.isNotEmpty
            ? state.result.reservationId
            : widget.reservationId,
        cafeName: widget.cafeName,
        gameName: widget.gameName,
        tableNumber: widget.tableNumber,
        skipCheckIn: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(_mode == _Mode.scanning ? 'Quét QR từ quán' : 'Mã check-in'),
        elevation: 0,
        actions: [
          if (!_requestingPermission)
            IconButton(
              tooltip: _mode == _Mode.scanning
                  ? 'Hiển thị mã cho staff'
                  : 'Quét bằng camera',
              icon: Icon(
                _mode == _Mode.scanning
                    ? Icons.qr_code
                    : Icons.qr_code_scanner,
              ),
              onPressed: () {
                if (_mode == _Mode.scanning) {
                  _switchToFallback();
                } else {
                  _switchToScanning();
                }
              },
            ),
        ],
      ),
      body: BlocConsumer<PlayerCheckInCubit, PlayerCheckInState>(
        listener: (context, state) {
          if (state is PlayerCheckInSuccess) {
            _onSuccess(state);
          }
          if (state is PlayerCheckInFailure) {
            context.showTopSnackBar(state.message, isError: true);
            _submittedFromScan = false;
            _scannerController?.start();

            setState(() {
              if (_tokenController.text.trim().toUpperCase() !=
                  state.lastToken) {
                _tokenController.text = state.lastToken;
              }
            });
          }
        },
        builder: (context, state) {
          final isSubmitting = state is PlayerCheckInSubmitting;
          final lastError = state is PlayerCheckInFailure ? state : null;

          if (lastError != null &&
              _cachePrefilled &&
              _tokenController.text.trim().toUpperCase() !=
                  lastError.lastToken) {
            _tokenController.text = lastError.lastToken;
          }

          return SafeArea(
            child: Column(
              children: [
                _HeaderCard(
                  cafeName: widget.cafeName,
                  gameName: widget.gameName,
                  isDark: isDark,
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_requestingPermission)
                          const _PermissionLoading()
                        else if (_mode == _Mode.scanning)
                          _ScannerSection(
                            controller: _scannerController!,
                            onDetect: _onScanDetected,
                            onSwitchToFallback: _switchToFallback,
                          )
                        else
                          _FallbackSection(
                            lobbyShareCode: widget.lobbyShareCode,
                            tokenController: _tokenController,
                            isSubmitting: isSubmitting,
                            errorText: lastError?.message,
                            onChanged: (_) => setState(() {}),
                            onPaste: () => _pasteFromClipboard(context),
                            onSubmit: () => _submit(context),
                            onUploadImage: _pickAndDecodeQrImage,
                            isUploading: _decodingImage,
                            isDark: isDark,
                          ),
                        const SizedBox(height: AppSpacing.lg),
                        const _HelperFooter(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Header card — neo-brutalism gradient banner hiển thị cafe + game.
class _HeaderCard extends StatelessWidget {
  final String cafeName;
  final String gameName;
  final bool isDark;

  const _HeaderCard({
    required this.cafeName,
    required this.gameName,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.radiusLgAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.4),
            blurRadius: 0,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.22),
              borderRadius: AppRadius.radiusMdAll,
            ),
            child: const Icon(
              AppIcons.qrScan,
              size: 22,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quét mã QR để check-in',
                  style: TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$cafeName • $gameName',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading state khi đang xin camera permission.
class _PermissionLoading extends StatelessWidget {
  const _PermissionLoading();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đang xin quyền camera...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section scanner — camera preview với overlay hướng dẫn.
class _ScannerSection extends StatefulWidget {
  final MobileScannerController controller;
  final void Function(BarcodeCapture) onDetect;
  final VoidCallback onSwitchToFallback;

  const _ScannerSection({
    required this.controller,
    required this.onDetect,
    required this.onSwitchToFallback,
  });

  @override
  State<_ScannerSection> createState() => _ScannerSectionState();
}

class _ScannerSectionState extends State<_ScannerSection> {
  bool _torchEnabled = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Đưa mã QR của quán vào khung',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
                letterSpacing: 0.6,
              ),
            ),
            // Nút bật/tắt đèn flash
            IconButton(
              onPressed: () async {
                await widget.controller.toggleTorch();
                setState(() {
                  _torchEnabled = !_torchEnabled;
                });
              },
              icon: Icon(
                _torchEnabled ? Icons.flash_on : Icons.flash_off,
                color: _torchEnabled ? Colors.amber : AppColors.textSecondary,
              ),
              tooltip: _torchEnabled ? 'Tắt đèn flash' : 'Bật đèn flash',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary,
                width: 3,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                MobileScanner(
                  controller: widget.controller,
                  onDetect: widget.onDetect,
                  errorBuilder: (_, error, _) => _ScannerError(
                    error: error,
                    onSwitchToFallback: widget.onSwitchToFallback,
                  ),
                ),
                Center(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.white,
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: widget.onSwitchToFallback,
          icon: const Icon(Icons.qr_code, size: 18),
          label: const Text(
            'Hiển thị mã QR của tôi cho staff',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ],
    );
  }
}

/// Lấy message lỗi chi tiết từ MobileScannerException.
String _getErrorMessage(MobileScannerException error) {
  switch (error.errorCode) {
    case MobileScannerErrorCode.permissionDenied:
      return 'Quyền camera bị từ chối.\nVui lòng bật quyền camera trong Cài đặt.';
    case MobileScannerErrorCode.unsupported:
      return 'Thiết bị không hỗ trợ quét QR.';
    case MobileScannerErrorCode.genericError:
      return 'Lỗi không xác định.\nHãy đưa mã QR của bạn cho nhân viên quét.';
    case MobileScannerErrorCode.controllerAlreadyInitialized:
      return 'Camera đang được sử dụng bởi ứng dụng khác.';
    default:
      return error.errorDetails?.message ??
          'Lỗi camera không xác định.\nHãy đưa mã QR của bạn cho nhân viên quét.';
  }
}

/// Hiển thị khi camera scanner gặp lỗi.
class _ScannerError extends StatelessWidget {
  final MobileScannerException error;
  final VoidCallback onSwitchToFallback;

  const _ScannerError({required this.error, required this.onSwitchToFallback});

  @override
  Widget build(BuildContext context) {
    // Lấy message chi tiết để debug
    final errorMsg = _getErrorMessage(error);

    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: AppColors.white,
              size: 48,
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Không thể truy cập camera',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: onSwitchToFallback,
              icon: const Icon(Icons.qr_code, size: 18),
              label: const Text('Hiển thị mã QR'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section fallback — hiển thị QR reservation + text field để paste token
/// + nút upload ảnh QR để test/debug.
class _FallbackSection extends StatelessWidget {
  final String lobbyShareCode;
  final TextEditingController tokenController;
  final bool isSubmitting;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPaste;
  final VoidCallback? onSubmit;
  final VoidCallback? onUploadImage;
  final bool isUploading;
  final bool isDark;

  const _FallbackSection({
    required this.lobbyShareCode,
    required this.tokenController,
    required this.isSubmitting,
    required this.errorText,
    required this.onChanged,
    required this.onPaste,
    required this.onSubmit,
    required this.onUploadImage,
    required this.isUploading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentToken = tokenController.text.trim().toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // QR code reservation để staff quét
        Text(
          'Mã QR của bạn - đưa cho nhân viên quét',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.radiusMdAll,
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: QrImageView(
                  data: lobbyShareCode,
                  version: QrVersions.auto,
                  size: 160,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mã reservation',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    lobbyShareCode,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    icon: Icon(Icons.copy, color: colors.primary, size: 18),
                    tooltip: 'Sao chép mã',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: lobbyShareCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã sao chép: $lobbyShareCode'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Hoặc nhập mã POS
        Text(
          'Hoặc dán mã QR từ POS (16 ký tự)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: errorText != null
                        ? AppColors.error
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.border),
                    width: errorText != null ? 3 : 2.5,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                child: TextField(
                  controller: tokenController,
                  enabled: !isSubmitting,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmit?.call(),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 3,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLength: 16,
                  decoration: const InputDecoration(
                    hintText: 'ABCDEFGHJKLMNPQR',
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9]'),
                    ),
                    _UpperCaseFormatter(),
                    LengthLimitingTextInputFormatter(16),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _PasteButton(onPressed: isSubmitting ? null : onPaste),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            errorText!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SubmitButton(
          isSubmitting: isSubmitting,
          enabled: currentToken.isNotEmpty,
          onPressed: onSubmit,
        ),
        const SizedBox(height: AppSpacing.md),
        // Nút upload ảnh QR — phục vụ test/debug. Decode QR từ ảnh bằng
        // Google ML Kit, sau đó submit như bình thường. Hữu ích khi không
        // có camera (emulator) hoặc muốn quét QR từ screenshot POS.
        OutlinedButton.icon(
          onPressed: (isSubmitting || isUploading) ? null : onUploadImage,
          icon: isUploading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
              : const Icon(Icons.image_outlined, size: 18),
          label: Text(
            isUploading ? 'Đang đọc ảnh...' : 'Tải ảnh QR từ thiết bị',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () {
            // Switch back to scanner mode
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text(
            'Quay lại chế độ quét camera',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ],
    );
  }
}

class _PasteButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _PasteButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.surfaceDark : AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.content_paste_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'Dán',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final bool enabled;
  final VoidCallback? onPressed;

  const _SubmitButton({
    required this.isSubmitting,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: (enabled && !isSubmitting) ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md + 2),
          decoration: BoxDecoration(
            color: enabled && !isSubmitting
                ? AppColors.primary
                : (isDark
                    ? AppColors.surfaceDark
                    : AppColors.surface),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2.5,
            ),
            boxShadow: enabled && !isSubmitting
                ? [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.4),
                      blurRadius: 0,
                      offset: const Offset(4, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSubmitting)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
                )
              else
                const Icon(
                  Icons.login_rounded,
                  size: 18,
                  color: AppColors.white,
                ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isSubmitting ? 'Đang check-in...' : 'Check-in tại quán',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  color: enabled && !isSubmitting
                      ? AppColors.white
                      : (isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelperFooter extends StatelessWidget {
  const _HelperFooter();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark
            : AppColors.surface,
        borderRadius: AppRadius.radiusMdAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.info,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  'Cần hỗ trợ?',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Nếu camera không hoạt động, hãy đưa mã QR bên trên cho nhân '
                  'viên để được check-in. Hoặc nhờ nhân viên quét mã trên màn '
                  'hình POS.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
