import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/booking_cubit.dart';
import '../cubit/booking_state.dart';
import '../widgets/deposit_countdown_timer.dart';
import '../widgets/deposit_status_card.dart';
import '../widgets/booking_qr_card.dart';

class DepositPage extends StatefulWidget {
  final String lobbyId;
  final String gameName;
  final String cafeName;
  final BookingCubit bookingCubit;

  const DepositPage({
    super.key,
    required this.lobbyId,
    required this.gameName,
    required this.cafeName,
    required this.bookingCubit,
  });

  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  @override
  void initState() {
    super.initState();
    widget.bookingCubit.initiateDeposit(
      lobbyId: widget.lobbyId,
      amount: 50000,
    );
  }

  void _showTimeoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.error_outline,
          color: Colors.red.shade700,
          size: 48,
        ),
        title: const Text('Hết thời gian đặt cọc'),
        content: const Text(
          'Một thành viên không đóng cọc đúng hạn. Phòng đã bị hủy, tiền cọc đã hoàn trả và điểm Karma đã bị trừ.',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: widget.bookingCubit,
      child: BlocConsumer<BookingCubit, BookingState>(
        listener: (context, state) {
          if (state is DepositTimeout) {
            _showTimeoutDialog(context);
          }
          if (state is BookingConfirmed) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đặt cọc thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Đặt cọc giữ phòng'),
            ),
            body: _buildBody(context, state),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, BookingState state) {
    if (state is BookingLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is BookingFailure) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(state.message),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => widget.bookingCubit.initiateDeposit(
                lobbyId: widget.lobbyId,
                amount: 50000,
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (state is BookingConfirmed) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            BookingQrCard(booking: state.booking),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const _InGameSessionPlaceholder(),
                    ),
                    (route) => route.isFirst,
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Đã đến quán - Check-in'),
              ),
            ),
          ],
        ),
      );
    }

    if (state is DepositProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang xử lý đặt cọc...'),
          ],
        ),
      );
    }

    if (state is DepositPending) {
      return _buildDepositPendingView(context, state);
    }

    return const SizedBox.shrink();
  }

  Widget _buildDepositPendingView(BuildContext context, DepositPending state) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Game and Cafe Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.extension,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.gameName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_cafe,
                        color: theme.colorScheme.outline,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.cafeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Countdown Timer
          DepositCountdownTimer(
            deadline: state.deposit.deadline,
            onExpired: () {},
          ),
          const SizedBox(height: 16),

          // User Balance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Số dư ví',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Text(
                    _formatCurrency(state.userBalance),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Deposit Status
          DepositStatusCard(
            records: state.deposit.records,
            amount: state.deposit.amount,
            onDeposit: () => widget.bookingCubit.makeDeposit(state.deposit.id),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}đ';
  }
}

class _InGameSessionPlaceholder extends StatelessWidget {
  const _InGameSessionPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trải nghiệm tại bàn'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green,
            ),
            SizedBox(height: 16),
            Text(
              'Check-in thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Module 4: In-Game Experience'),
          ],
        ),
      ),
    );
  }
}
