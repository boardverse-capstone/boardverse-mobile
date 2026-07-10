import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../cubit/booking_summary_cubit.dart';
import '../cubit/booking_summary_state.dart';
import '../widgets/deposit_breakdown_card.dart';
import '../widgets/payment_method_selector.dart';

/// Trang tóm tắt trước khi thanh toán — hiển thị breakdown giá, phương thức
/// thanh toán, gọi cubit tạo booking rồi push `PaymentPage`.
class BookingSummaryPage extends StatefulWidget {
  final String lobbyId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;
  final int seatCount;
  final List<String> memberIds;

  /// Id booking đã được auto-create từ Luồng A (lobby đầy). Khi có giá trị,
  /// summary page có thể hiển thị badge "Đã được tạo tự động" hoặc skip bước
  /// createBooking. (Hiện tại chỉ dùng cho UI label, không dùng để skip bước
  /// vì server đã tạo sẵn — phase sau sẽ resume flow dùng trực tiếp id này.)
  final String? autoBookingId;

  const BookingSummaryPage({
    super.key,
    required this.lobbyId,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.scheduledTime,
    required this.seatCount,
    required this.memberIds,
    this.autoBookingId,
  });

  @override
  State<BookingSummaryPage> createState() => _BookingSummaryPageState();
}

class _BookingSummaryPageState extends State<BookingSummaryPage> {
  late final BookingSummaryCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BookingSummaryCubit>()..loadConfig(widget.cafeId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rời trang?'),
        content: const Text(
          'Nếu rời bây giờ, thông tin đặt chỗ sẽ bị huỷ. Bạn có chắc?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rời đi'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<BookingSummaryCubit, BookingSummaryState>(
        listener: (context, state) {
          if (state is SummarySuccess) {
            // vì payment flow đang trong giai đoạn fix bugs — bỏ comment khi ready.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Tạo booking thành công! bookingId=${state.bookingId}, '
                  'cọc=${state.depositAmount}đ (payment tạm khoá)',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 5),
              ),
            );
            Navigator.popUntil(context, (route) => route.isFirst);
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(
            //     builder: (_) => PaymentPage(
            //       bookingId: state.bookingId,
            //       cafeId: widget.cafeId,
            //       depositAmount: state.depositAmount,
            //       deadline: state.deadline,
            //       config: lastReady?.config,
            //       method: lastReady?.selectedMethod ?? _defaultMethod,
            //     ),
            //   ),
            // );
          }
          if (state is SummaryFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          if (state is SummaryReady) {
            // _lastReady = state;
          }
        },
        builder: (context, state) {
          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) async {
              if (didPop) return;
              if (await _confirmLeave() && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Scaffold(
              appBar: AppBar(title: const Text('Xác nhận đặt chỗ')),
              body: _buildBody(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingSummaryState state) {
    if (state is SummaryInitial || state is SummaryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is SummaryFailure && state.code == 'FETCH_CONFIG') {
      return _buildError(state.message);
    }
    if (state is SummaryReady) {
      return _buildReady(context, state);
    }
    if (state is SummarySubmitting) {
      return const Center(child: CircularProgressIndicator());
    }
    return const SizedBox.shrink();
  }

  Widget _buildReady(BuildContext context, SummaryReady state) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm — dd/MM/yyyy');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thông tin phòng
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.gameName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _kv(theme, 'Quán', widget.cafeName),
                  _kv(theme, 'Giờ hẹn', timeFmt.format(widget.scheduledTime)),
                  _kv(theme, 'Số ghế', widget.seatCount.toString()),
                  _kv(
                    theme,
                    'Số thành viên',
                    widget.memberIds.length.toString(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DepositBreakdownCard(breakdown: state.breakdown),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PaymentMethodSelector(
                selected: state.selectedMethod,
                onChanged: _cubit.selectPaymentMethod,
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _cubit.submit(
              cafeId: widget.cafeId,
              gameId: widget.gameId,
              scheduledTime: widget.scheduledTime,
              seatCount: widget.seatCount,
              memberIds: widget.memberIds,
            ),
            icon: const Icon(Icons.lock_outline),
            label: const Text('Xác nhận & Thanh toán'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => _cubit.loadConfig(widget.cafeId),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kv(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
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
}
