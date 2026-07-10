import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import '../cubit/payment_cubit.dart';
import '../cubit/payment_state.dart';
import '../widgets/countdown_banner.dart';
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
    // Ưu tiên dùng config truyền vào, nếu không có thì fetch lại qua repo.
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
              backgroundColor: Theme.of(dialogCtx).colorScheme.error,
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
                builder: (_) => BookingSuccessPage(bookingId: state.bookingId),
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
                        icon: const Icon(Icons.arrow_back),
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CountdownBanner(
                      deadline: widget.deadline,
                      onExpired: () {},
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Số tiền cần thanh toán',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatVnd(widget.depositAmount),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const Divider(height: 24),
                            _row(theme, 'Mã đơn', widget.bookingId),
                            _row(
                              theme,
                              'Hạn chót',
                              DateFormat('HH:mm — dd/MM').format(widget.deadline),
                            ),
                            _row(theme, 'Phương thức', widget.method.displayName),
                            const SizedBox(height: 16),
                            Text(
                              'Trong môi trường phát triển, cổng thanh toán là giả lập — '
                              'sau vài giây hệ thống sẽ tự động xác nhận thành công.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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

  Widget _buildAction(BuildContext context, PaymentState state) {
    if (state is PaymentOpening || state is PaymentProcessing) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state is PaymentAwaitingCallback) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: null,
            icon: const Icon(Icons.credit_card),
            label: const Text('Đang chờ cổng thanh toán...'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _onCancelPayment(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
            icon: const Icon(Icons.lock_outline),
            label: const Text('Mở cổng thanh toán'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _onCancelPayment(context),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Hủy thanh toán'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
        icon: Icon(
          isTimeout ? Icons.timer_off : Icons.error_outline,
          size: 48,
          color: Colors.orange.shade700,
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

  Widget _row(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatVnd(double v) {
    final f = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    return '${f.format(v).trim()} đ';
  }
}
