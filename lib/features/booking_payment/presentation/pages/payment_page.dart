import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';
import '../widgets/booking_ui_helpers.dart';
import '../widgets/countdown_banner.dart';
import '../widgets/info_row.dart';
import 'booking_success_page.dart';

/// Trang thanh toán — hiển thị countdown, mở gateway, đợi kết quả.
class PaymentPage extends StatefulWidget {
  final String bookingId;
  final String cafeId;
  final double depositAmount;
  final DateTime deadline;
  final DepositConfigEntity? config;
  final PaymentMethod method;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.cafeId,
    required this.depositAmount,
    required this.deadline,
    required this.config,
    this.method = PaymentMethod.sandboxMock,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late final PaymentCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<PaymentCubit>();
    _init();
  }

  Future<void> _init() async {
    DepositConfigEntity? config = widget.config;
    if (config == null) {
      final repo = getIt<BookingRepository>();
      final result = await repo.getDepositConfig(widget.cafeId);
      config = result.fold((_) => null, (c) => c);
    }
    if (!mounted) return;
    _cubit.start(
      bookingId: widget.bookingId,
      amount: widget.depositAmount,
      method: widget.method,
      deadline: widget.deadline,
      config: config ?? _placeholderConfig(),
    );
  }

  DepositConfigEntity _placeholderConfig() => DepositConfigEntity(
        cafeId: widget.cafeId,
        firstHourPrice: 100000,
        entryFee: 80000,
        maxDeposit: 50000,
        defaultDeposit: 50000,
        graceMinutes: 15,
        currency: 'VND',
      );

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  bool get _canPopSafely {
    final s = _cubit.state;
    return s is! PaymentOpening && s is! PaymentProcessing;
  }

  Future<bool> _confirmCancel(BuildContext ctx) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        icon: Icon(
          Icons.warning_amber_rounded,
          size: AppIcons.xxl,
          color: AppColors.warning,
        ),
        title: const Text('Hủy thanh toán?'),
        content: const Text(
          'Nếu hủy bây giờ, đơn đặt chỗ sẽ bị huỷ và bạn mất slot đã giữ. '
          'Bạn có chắc muốn hủy không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Hủy thanh toán'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onCancelPayment(BuildContext ctx) async {
    final confirmed = await _confirmCancel(ctx);
    if (!confirmed) return;
    await _cubit.cancelByUser('User cancelled payment');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<PaymentCubit, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    BookingSuccessPage(bookingId: state.bookingId),
              ),
            );
          }
          if (state is PaymentFailed || state is PaymentTimeout) {
            _showFailDialog(context, state);
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: _canPopSafely,
            onPopInvokedWithResult: (didPop, result) async {
              if (didPop) return;
              if (!_canPopSafely) return;
              final confirmed = await _confirmCancel(context);
              if (confirmed && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Thanh toán cọc'),
                automaticallyImplyLeading: false,
                leading: _canPopSafely
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () async {
                          final confirmed = await _confirmCancel(context);
                          if (confirmed && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                      )
                    : null,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CountdownBanner(
                      deadline: widget.deadline,
                      onExpired: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildAmountCard(theme, state),
                    const SizedBox(height: AppSpacing.md),
                    _buildAction(context, state),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmountCard(ThemeData theme, PaymentState state) {
    final methodColor =
        BookingUiHelpers.paymentMethodColor(widget.method, context);
    final methodIcon = BookingUiHelpers.paymentMethodIcon(widget.method);

    return Container(
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: AppElevation.shadowXxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.10),
                  theme.colorScheme.primary.withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.radiusLg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.radiusSmAll,
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        size: AppIcons.md,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Số tiền cần thanh toán',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  BookingUiHelpers.formatVnd(widget.depositAmount),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                InfoRow(
                  icon: Icons.confirmation_number_rounded,
                  label: 'Mã đơn',
                  value: widget.bookingId,
                  iconColor: AppColors.secondary,
                  copyable: true,
                ),
                InfoRow(
                  icon: Icons.schedule_rounded,
                  label: 'Hạn chót',
                  value: BookingUiHelpers.formatDateTime(widget.deadline,
                      pattern: 'HH:mm — dd/MM'),
                  iconColor: AppColors.warning,
                ),
                InfoRow(
                  icon: methodIcon,
                  label: 'Phương thức',
                  value: widget.method.displayName,
                  iconColor: methodColor,
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.08),
                    borderRadius: AppRadius.radiusXsAll,
                    border:
                        Border.all(color: AppColors.info.withValues(alpha: 0.30)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: AppIcons.md, color: AppColors.info),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'Trong môi trường phát triển, cổng thanh toán là giả lập — '
                          'sau vài giây hệ thống sẽ tự động xác nhận thành công.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(BuildContext context, PaymentState state) {
    if (state is PaymentOpening || state is PaymentProcessing) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              state is PaymentProcessing
                  ? 'Đang xử lý thanh toán...'
                  : 'Đang mở cổng thanh toán...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      );
    }
    if (state is PaymentAwaitingCallback) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.credit_card_rounded),
            label: const Text('Đang chờ cổng thanh toán...'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _onCancelPayment(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      );
    }
    if (state is PaymentIdle) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _init,
            icon: const Icon(Icons.lock_outline_rounded),
            label: const Text('Mở cổng thanh toán'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(
            onPressed: () => _onCancelPayment(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.5)),
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _showFailDialog(BuildContext context, PaymentState state) {
    final isTimeout = state is PaymentTimeout;
    final message = isTimeout
        ? 'Đã hết thời gian giữ chỗ. Đơn đã được huỷ tự động.'
        : (state as PaymentFailed).reason;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogRadius),
        icon: Icon(
          isTimeout ? Icons.timer_off_rounded : Icons.error_outline_rounded,
          size: AppIcons.xxl,
          color: AppColors.warning,
        ),
        title: Text(isTimeout ? 'Hết hạn' : 'Thanh toán thất bại'),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            child: const Text('Về trang chính'),
          ),
        ],
      ),
    );
  }
}
