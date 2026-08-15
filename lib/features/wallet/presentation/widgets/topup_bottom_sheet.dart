import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/neo_brutalism_theme.dart';
import '../cubit/topup_cubit.dart';
import '../cubit/topup_state.dart';
import 'qr_network_image.dart';

/// Bottom sheet nạp BVC inline — được mở từ màn hình đặt cọc khi user
/// thiếu BVC. Mục tiêu: user không phải rời context, sau khi thanh toán
/// có thể tự động tiếp tục đặt cọc.
///
/// **Flow**:
/// 1. User ấn "Nạp BVC ngay" → mở bottom sheet này.
/// 2. User chọn số tiền (gợi ý: số tiền còn thiếu + buffer) hoặc nhập tay.
/// 3. Bấm "Tiếp tục thanh toán" → `TopUpCubit.createTopUp()` tạo đơn.
/// 4. Hiển thị QR SePay + countdown + auto-polling 5s/lần.
/// 5. Top-up thành công → cubit emit `TopUpSuccess` → bottom sheet:
///    - Hiển thị success dialog.
///    - Auto-close sau 1.5s.
///    - Gọi `onSuccess()` callback → trigger auto re-quote + confirm
///      ở màn hình cha.
///
/// **Quy tắc style**:
/// - Neo-brutalism: border + hard offset shadow + icon badges đậm.
/// - Layout nhỏ gọn (maxHeight 85% screen) — không thay thế toàn bộ UX.
/// - Tất cả shadow dùng màu semantic, không dùng đen thuần.
class TopUpBottomSheet extends StatefulWidget {
  /// Số BVC user đang thiếu (chỉ để hiển thị thông tin).
  final int missingBvc;

  /// Số tiền VND mặc định (gợi ý cho input). Thường là
  /// `missingBvc * 1000 + buffer`.
  final int initialAmountVnd;

  /// Callback khi top-up thành công. Màn hình cha sẽ gọi
  /// `refreshBalanceAndConfirm(autoConfirm: ...)` để tiếp tục flow đặt cọc.
  final VoidCallback onSuccess;

  const TopUpBottomSheet({
    super.key,
    required this.missingBvc,
    required this.initialAmountVnd,
    required this.onSuccess,
  });

  /// Helper mở bottom sheet với cubit lifecycle đúng.
  ///
  /// Caller KHÔNG cần wrap BlocProvider — hàm này tự tạo `TopUpCubit` mới
  /// cho session này (TopUpCubit là factory, mỗi lần mở = cubit mới).
  /// Khi bottom sheet đóng → cubit được `close()` để cleanup polling timer.
  static Future<void> show({
    required BuildContext context,
    required int missingBvc,
    required int initialAmountVnd,
    required VoidCallback onSuccess,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetCtx) => BlocProvider(
        create: (_) => TopUpCubit.newInstance(),
        child: TopUpBottomSheet(
          missingBvc: missingBvc,
          initialAmountVnd: initialAmountVnd,
          onSuccess: onSuccess,
        ),
      ),
    );
  }

  @override
  State<TopUpBottomSheet> createState() => _TopUpBottomSheetState();
}

class _TopUpBottomSheetState extends State<TopUpBottomSheet> {
  final TextEditingController _customAmountController = TextEditingController();
  int _selectedAmountVnd = 0;
  bool _isDownloadingQr = false;

  @override
  void initState() {
    super.initState();
    _selectedAmountVnd = widget.initialAmountVnd;
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  int get _currentAmountVnd {
    if (_customAmountController.text.isNotEmpty) {
      return int.tryParse(
            _customAmountController.text.replaceAll(',', ''),
            radix: 10,
          ) ??
          _selectedAmountVnd;
    }
    return _selectedAmountVnd;
  }

  void _selectPackage(int amountVnd) {
    setState(() {
      _selectedAmountVnd = amountVnd;
      _customAmountController.clear();
    });
  }

  void _startTopUp() {
    final amountToSend = _currentAmountVnd;
    final messenger = ScaffoldMessenger.of(context);

    if (amountToSend < 10000) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Số tiền tối thiểu là 10.000 VND'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (amountToSend % 1000 != 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Số tiền phải chia hết cho 1.000'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    context.read<TopUpCubit>().createTopUp(
          amountVnd: amountToSend,
          onSuccess: () {
            // Polling phát hiện thanh toán → đã emit TopUpSuccess.
            // BlocConsumer listener bên dưới sẽ tự xử lý (show dialog + close).
            // Không cần làm gì thêm ở đây.
          },
        );
  }

  Future<void> _handleDownloadQr(TopUpAwaitingPayment state) async {
    final messenger = ScaffoldMessenger.of(context);
    final cubit = context.read<TopUpCubit>();
    setState(() => _isDownloadingQr = true);
    try {
      final result = await cubit.downloadCurrentQr();
      if (!mounted) return;
      if (result.success) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Đã lưu QR vào Photos (${result.fileName}). '
              'Mở app ngân hàng → Quét QR để thanh toán.',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Không thể tải QR.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingQr = false);
    }
  }

  Future<void> _handleManualCheck() async {
    final cubit = context.read<TopUpCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await cubit.manualCheckStatus();
    if (!mounted) return;
    if (!ok && cubit.state is TopUpAwaitingPayment) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Chưa nhận được thanh toán. Vui lòng đợi thêm vài giây.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.borderDark : AppColors.border;

    return BlocConsumer<TopUpCubit, TopUpState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is TopUpFailed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.reason),
              backgroundColor: AppColors.error,
            ),
          );
        }
        if (state is TopUpSuccess) {
          // Đợi dialog hiển thị 1.4s rồi auto-close sheet → callback onSuccess.
          // Capture Navigator trước khi vào async gap để tránh dùng
          // BuildContext sau khi widget có thể đã unmount.
          final navigator = Navigator.of(context);
          Future.delayed(const Duration(milliseconds: 1400), () {
            if (mounted) {
              navigator.pop();
              widget.onSuccess();
            }
          });
        }
      },
      buildWhen: (prev, curr) {
        // Chỉ rebuild khi đổi state (giảm rebuild cho countdown).
        return prev.runtimeType != curr.runtimeType;
      },
      builder: (context, state) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.background,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: NeoBrutalismTheme.borderWidthBold,
                  ),
                  left: BorderSide(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
                  right: BorderSide(color: borderColor, width: NeoBrutalismTheme.borderWidthBold),
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
                  // ── Drag handle ────────────────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: borderColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ── Header ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 2),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'NẠP BVC ĐỂ ĐẶT CỌC',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Text(
                                'Thiếu ${widget.missingBvc} BVC — '
                                'nạp đủ để tiếp tục',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Đóng',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // ── Body ───────────────────────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: _buildBody(context, state, borderColor),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, TopUpState state, Color borderColor) {
    // Sau khi tạo đơn thành công → hiển thị QR + countdown + polling.
    if (state is TopUpAwaitingPayment) {
      return _AwaitingPaymentView(
        state: state,
        onDownload: () => _handleDownloadQr(state),
        isDownloading: _isDownloadingQr,
        onManualCheck: _handleManualCheck,
        borderColor: borderColor,
      );
    }

    // Đang xử lý tạo đơn.
    if (state is TopUpCreating) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    // Đang check status (polling) — TopUpCubit không emit state này
    // (polling là silent) nên block này defensive-only. Nếu sau này
    // cubit emit thêm state, render spinner fallback.

    // Top-up thành công — hiển thị success card ngay trong sheet (auto-close 1.4s).
    if (state is TopUpSuccess) {
      return _SuccessView(
        amountBvc: state.amountBvc,
        newBalance: state.newBalance,
        borderColor: borderColor,
      );
    }

    // Đã hủy → quay về form.
    if (state is TopUpCancelled) {
      return _PackageForm(
        customAmountController: _customAmountController,
        selectedAmountVnd: _selectedAmountVnd,
        onSelectPackage: _selectPackage,
        onStart: _startTopUp,
        borderColor: borderColor,
      );
    }

    // Initial → form chọn gói.
    return _PackageForm(
      customAmountController: _customAmountController,
      selectedAmountVnd: _selectedAmountVnd,
      onSelectPackage: _selectPackage,
      onStart: _startTopUp,
      borderColor: borderColor,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// Form chọn gói nạp + nhập số tiền tùy ý + button xác nhận.
class _PackageForm extends StatelessWidget {
  final TextEditingController customAmountController;
  final int selectedAmountVnd;
  final ValueChanged<int> onSelectPackage;
  final VoidCallback onStart;
  final Color borderColor;

  const _PackageForm({
    required this.customAmountController,
    required this.selectedAmountVnd,
    required this.onSelectPackage,
    required this.onStart,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final packages = TopUpPackages.suggestedAmountsVnd;

    // TextWatcher: dùng StatefulBuilder để rebuild khi controller thay đổi.
    return StatefulBuilder(
      builder: (context, setLocal) {
        final customRaw = customAmountController.text.replaceAll(',', '');
        final hasCustom = customRaw.isNotEmpty;
        final currentAmountVnd = hasCustom
            ? int.tryParse(customRaw) ?? selectedAmountVnd
            : selectedAmountVnd;
        final currentAmountBvc = currentAmountVnd ~/ 1000;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Section: Suggested packages ──
            Text(
              'GÓI GỢI Ý',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.4,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final vnd = packages[index];
                final isSelected = !hasCustom && vnd == selectedAmountVnd;
                return _PackageChip(
                  amountVnd: vnd,
                  amountBvc: vnd ~/ 1000,
                  isSelected: isSelected,
                  onTap: () => onSelectPackage(vnd),
                  borderColor: borderColor,
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Section: Custom amount ──
            Text(
              'HOẶC NHẬP SỐ TIỀN KHÁC',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: customAmountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _ThousandsFormatter(),
              ],
              onChanged: (_) => setLocal(() {}),
              decoration: InputDecoration(
                hintText: 'Tối thiểu 10.000 VND',
                filled: true,
                fillColor: theme.colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: borderColor, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: borderColor, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                ),
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Summary ──
            Container(
              padding: AppSpacing.paddingAllMd,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.primary,
                  width: NeoBrutalismTheme.borderWidthBold,
                ),
                boxShadow: NeoBrutalismTheme.lightShadow(
                  shadowColor:
                      AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'BẠN SẼ NHẬN',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currentAmountBvc',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'BVC',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── Action button ──
            _PrimaryActionButton(
              label: 'TIẾP TỤC THANH TOÁN',
              icon: Icons.qr_code_2_rounded,
              onPressed: currentAmountVnd >= 10000 ? onStart : null,
              borderColor: borderColor,
            ),
            const SizedBox(height: AppSpacing.sm),
            Center(
              child: Text(
                '1 BVC = 1.000 VND • Tỷ lệ quy đổi cố định',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// View hiển thị QR + countdown + polling state cho awaiting payment.
class _AwaitingPaymentView extends StatefulWidget {
  final TopUpAwaitingPayment state;
  final VoidCallback onDownload;
  final VoidCallback onManualCheck;
  final bool isDownloading;
  final Color borderColor;

  const _AwaitingPaymentView({
    required this.state,
    required this.onDownload,
    required this.onManualCheck,
    required this.isDownloading,
    required this.borderColor,
  });

  @override
  State<_AwaitingPaymentView> createState() => _AwaitingPaymentViewState();
}

class _AwaitingPaymentViewState extends State<_AwaitingPaymentView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tickCtrl;

  @override
  void initState() {
    super.initState();
    _tickCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _tickCtrl.repeat();
  }

  @override
  void dispose() {
    _tickCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quote = widget.state.quote;
    final remaining = widget.state.deadline.difference(DateTime.now());
    final isExpired = remaining.isNegative;
    final mm = isExpired
        ? 0
        : remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = isExpired
        ? 0
        : remaining.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Status header ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: isExpired ? AppColors.error : AppColors.warning,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.borderColor,
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExpired ? Icons.timer_off : Icons.timer_outlined,
                    size: 16,
                    color: isExpired
                        ? AppColors.white
                        : AppColors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExpired ? 'HẾT HẠN' : '$mm:$ss',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                      color: isExpired
                          ? AppColors.white
                          : AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── QR card ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.borderColor,
              width: NeoBrutalismTheme.borderWidthBold,
            ),
            boxShadow: NeoBrutalismTheme.lightShadow(
              shadowColor: AppColors.black.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'QUÉT QR ĐỂ THANH TOÁN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Số tiền: ${_formatVnd(quote.amountVnd)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Mã đơn: ${quote.orderId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.black,
                    width: 2,
                  ),
                ),
                // `QrNetworkImage` tự xử lý:
                // 1. Download ảnh QR từ `qrUrl` bằng Dio + Chrome UA
                //    (bypass CDN block "Dart" UA — xem `QrImageLoader`).
                // 2. Render bằng `Image.memory`.
                // 3. Nếu load fail → fallback `QrImageView(paymentUrl)`.
                // 4. Nếu cả 2 fail → icon placeholder.
                child: QrNetworkImage(
                  qrUrl: quote.qrUrl,
                  paymentUrl: quote.paymentUrl,
                  qrImageBase64: quote.qrImageBase64,
                  size: 200,
                  backgroundColor: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Mở app ngân hàng và quét QR này',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Action row: Download + Manual check ──
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _SecondaryActionButton(
                label: widget.isDownloading ? 'ĐANG TẢI...' : 'TẢI QR',
                icon: widget.isDownloading
                    ? Icons.hourglass_top_rounded
                    : Icons.download_rounded,
                onPressed: widget.isDownloading ? null : widget.onDownload,
                color: AppColors.primary,
                borderColor: widget.borderColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 1,
              child: _SecondaryActionButton(
                label: 'CHECK',
                icon: Icons.refresh_rounded,
                onPressed: widget.onManualCheck,
                color: AppColors.textPrimary,
                borderColor: widget.borderColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Polling hint ──
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.info,
              width: NeoBrutalismTheme.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.info,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.autorenew_rounded,
                  size: 12,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(
                child: Text(
                  'Đang tự động kiểm tra mỗi 5 giây. '
                  'Khi thanh toán thành công, sheet sẽ tự đóng và tiếp tục đặt cọc.',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Success card hiển thị sau khi thanh toán thành công (trước khi auto-close).
class _SuccessView extends StatelessWidget {
  final int amountBvc;
  final int newBalance;
  final Color borderColor;

  const _SuccessView({
    required this.amountBvc,
    required this.newBalance,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 3),
              boxShadow: NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.success.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.white,
              size: 56,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'NẠP BVC THÀNH CÔNG!',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '+$amountBvc BVC đã được cộng vào ví',
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          Text(
            'Số dư mới: $newBalance BVC',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Đang tiếp tục đặt cọc...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip gói nạp (compact version cho bottom sheet).
class _PackageChip extends StatelessWidget {
  final int amountVnd;
  final int amountBvc;
  final bool isSelected;
  final VoidCallback onTap;
  final Color borderColor;

  const _PackageChip({
    required this.amountVnd,
    required this.amountBvc,
    required this.isSelected,
    required this.onTap,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : borderColor,
              width: isSelected ? 3 : 2,
            ),
            boxShadow: isSelected
                ? NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.primary.withValues(alpha: 0.4),
                  )
                : NeoBrutalismTheme.lightShadow(
                    shadowColor: AppColors.black.withValues(alpha: 0.04),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$amountBvc',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                'BVC',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ),
              Text(
                _shortVnd(amountVnd),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.white
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortVnd(int v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(0)}M VND';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K VND';
    return '$v VND';
  }
}

/// Primary action button (full width, primary color).
class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color borderColor;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? AppColors.primary : AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidthBold,
        ),
        boxShadow: isEnabled
            ? NeoBrutalismTheme.lightShadow(
                shadowColor: AppColors.primary.withValues(alpha: 0.5),
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isEnabled ? AppColors.white : AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled
                        ? AppColors.white
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary action button (outlined, semantic color).
class _SecondaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color borderColor;

  const _SecondaryActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: NeoBrutalismTheme.borderWidth,
        ),
        boxShadow: NeoBrutalismTheme.lightShadow(
          shadowColor: color.withValues(alpha: 0.2),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatVnd(int amount) {
  final str = amount.toString();
  final result = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) {
      result.write(',');
    }
    result.write(str[i]);
  }
  return '$result VNĐ';
}

/// Thousands separator formatter (same as TopUpPage).
class _ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;

    final str = number.toString();
    final result = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(',');
      }
      result.write(str[i]);
    }
    final formatted = result.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}