import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/core/di/injection.dart';
import 'package:boardverse/core/theme/theme.dart';
import 'package:boardverse/core/widgets/top_snack_bar.dart';
import 'package:boardverse/features/lobby_management/lobby_routes.dart';
import '../cubit/player_check_in_cubit.dart';

/// Page arguments cho [PlayerQrCheckInPage].
class PlayerQrCheckInPageArgs {
  final String reservationId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const PlayerQrCheckInPageArgs({
    required this.reservationId,
    required this.cafeName,
    required this.gameName,
    this.tableNumber = 1,
  });
}

/// Trang nhập/paste QR token hiển thị trên POS — dùng cho player self
/// check-in (BR §21A.7, chiều 2 của check-in 2 chiều).
///
/// **Note về scope**:
/// - Backend `/api/check-in/scan-qr` yêu cầu **Player** quét QR do POS tạo
///   (16-char alphanumeric uppercase). Thiết bị không có camera scanner
///   (mobile hiện tại chưa add `mobile_scanner`) — vì vậy trang này cho
///   phép paste token thủ công. Token có thể được copy từ màn hình POS,
///   từ email/zalo POS gửi, hoặc từ QR Code Reader app khác.
/// - Sau khi scan thành công → navigate sang `InGameSessionPage` với
///   `skipCheckIn: true` (đã check-in).
class PlayerQrCheckInPage extends StatelessWidget {
  final String reservationId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const PlayerQrCheckInPage({
    super.key,
    required this.reservationId,
    required this.cafeName,
    required this.gameName,
    this.tableNumber = 1,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PlayerCheckInCubit>(),
      child: _PlayerQrCheckInView(
        reservationId: reservationId,
        cafeName: cafeName,
        gameName: gameName,
        tableNumber: tableNumber,
      ),
    );
  }
}

class _PlayerQrCheckInView extends StatefulWidget {
  final String reservationId;
  final String cafeName;
  final String gameName;
  final int tableNumber;

  const _PlayerQrCheckInView({
    required this.reservationId,
    required this.cafeName,
    required this.gameName,
    required this.tableNumber,
  });

  @override
  State<_PlayerQrCheckInView> createState() => _PlayerQrCheckInViewState();
}

class _PlayerQrCheckInViewState extends State<_PlayerQrCheckInView> {
  final _tokenController = TextEditingController();

  /// Token đang hiển thị (giữ lại giá trị cũ khi rebuild do state change).
  String get _currentToken => _tokenController.text.trim().toUpperCase();

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
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

  void _onSuccess(BuildContext context, PlayerCheckInSuccess state) {
    if (!state.result.reservationId.isNotEmpty &&
        state.result.reservationId != widget.reservationId) {
      // Defensive: backend scan thành công cho reservation khác với context
      // hiện tại — vẫn cho vào phiên chơi vì session đã được tạo.
    }
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
        title: const Text('Quét QR từ quán'),
        elevation: 0,
      ),
      body: BlocConsumer<PlayerCheckInCubit, PlayerCheckInState>(
        listener: (context, state) {
          if (state is PlayerCheckInSuccess) {
            _onSuccess(context, state);
          }
          if (state is PlayerCheckInFailure) {
            // Lỗi — giữ nguyên input, không pop.
            context.showTopSnackBar(state.message, isError: true);
            setState(() {
              // Restore lại đúng giá trị token đã submit (trong trường
              // hợp format mismatch đã bị reject trước khi gọi API).
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

          // Auto-fill từ error state để user retry không phải gõ lại.
          if (lastError != null &&
              _tokenController.text.trim().toUpperCase() !=
                  lastError.lastToken) {
            _tokenController.text = lastError.lastToken;
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeaderCard(
                    cafeName: widget.cafeName,
                    gameName: widget.gameName,
                    isDark: isDark,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _InstructionStep(
                    step: 1,
                    title: 'Lấy mã QR từ quán',
                    body:
                        'Nhờ nhân viên quán tạo mã QR trên màn hình POS, '
                        'sau đó copy mã gồm 16 ký tự in hoa (A–Z, 2–9).',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _InstructionStep(
                    step: 2,
                    title: 'Dán mã vào ô bên dưới',
                    body:
                        'Nhấn nút "Dán từ bộ nhớ tạm" hoặc nhập thủ công '
                        'rồi bấm "Check-in".',
                    color: AppColors.secondary,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  _TokenInputField(
                    controller: _tokenController,
                    isSubmitting: isSubmitting,
                    onChanged: (_) => setState(() {}),
                    onPaste: () => _pasteFromClipboard(context),
                    onSubmit: () => _submit(context),
                    errorText: lastError?.message,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  _SubmitButton(
                    isSubmitting: isSubmitting,
                    enabled: _currentToken.isNotEmpty,
                    onPressed: () => _submit(context),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  const _HelperFooter(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

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
                Text(
                  'Tự check-in tại quán',
                  style: const TextStyle(
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

class _InstructionStep extends StatelessWidget {
  final int step;
  final String title;
  final String body;
  final Color color;

  const _InstructionStep({
    required this.step,
    required this.title,
    required this.body,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 2,
            ),
          ),
          child: Text(
            '$step',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.white,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TokenInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool isSubmitting;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPaste;
  final VoidCallback? onSubmit;
  final String? errorText;

  const _TokenInputField({
    required this.controller,
    required this.isSubmitting,
    required this.onChanged,
    required this.onPaste,
    required this.onSubmit,
    required this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Mã QR từ POS (16 ký tự)',
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
                  controller: controller,
                  enabled: !isSubmitting,
                  onChanged: onChanged,
                  onSubmitted: (_) => onSubmit?.call(),
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
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
                  'Nếu quán chưa tạo QR, hãy nhờ nhân viên vào POS → bấm '
                  '"Tạo QR check-in" và đưa màn hình cho bạn quét. Mã có '
                  'thời hạn 30 phút.',
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
