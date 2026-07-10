import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../cubit/booking_result_cubit.dart';
import '../cubit/booking_result_state.dart';
import '../widgets/no_show_badge.dart';
import 'booking_detail_page.dart';

/// Trang lịch hẹn của user — có 2 tab: Sắp tới + Lịch sử.
class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage>
    with SingleTickerProviderStateMixin {
  late final BookingResultCubit _cubit;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BookingResultCubit>();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  void _loadData() {
    _cubit.loadUpcomingAndHistory();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Column(
        children: [
          // TabBar đặt ở đây vì AppBar đã có ở BookingsPage wrapper.
          Material(
            color: Theme.of(context).appBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Sắp tới'),
                Tab(text: 'Lịch sử'),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<BookingResultCubit, BookingResultState>(
              builder: (context, state) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _UpcomingTab(
                      state: state,
                      onRefresh: () {
                        _cubit.loadUpcomingAndHistory();
                        return Future.value();
                      },
                      onChanged: _cubit.loadUpcomingBookings,
                    ),
                    _HistoryTab(
                      state: state,
                      onRefresh: () {
                        _cubit.loadUpcomingAndHistory();
                        return Future.value();
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab: Các booking sắp tới (pending + confirmed + checkedIn + cancelled).
class _UpcomingTab extends StatelessWidget {
  final BookingResultState state;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChanged;

  const _UpcomingTab({
    required this.state,
    required this.onRefresh,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (state is ResultLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<BookingEntity> upcomingBookings;
    if (state is ResultUpcomingBookings) {
      upcomingBookings = (state as ResultUpcomingBookings).bookings;
    } else if (state is ResultUpcomingAndHistory) {
      upcomingBookings = (state as ResultUpcomingAndHistory).upcoming;
    } else {
      upcomingBookings = const <BookingEntity>[];
    }

    if (upcomingBookings.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Chưa có lịch hẹn nào sắp tới'),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: upcomingBookings.length,
        itemBuilder: (context, i) {
          final booking = upcomingBookings[i];
          return _UpcomingBookingCard(
            booking: booking,
            onChanged: onChanged,
          );
        },
      ),
    );
  }
}

/// Card tóm tắt booking — tap để mở trang chi tiết.
/// Hiển thị: icon + game + quán + giờ + số ghế + trạng thái + chevron.
class _UpcomingBookingCard extends StatelessWidget {
  final BookingEntity booking;
  final Future<void> Function() onChanged;

  const _UpcomingBookingCard({
    required this.booking,
    required this.onChanged,
  });

  Color _statusColor() {
    switch (booking.status.name) {
      case 'confirmed':
        return Colors.blue;
      case 'checkedIn':
        return Colors.green;
      case 'pendingDeposit':
        return Colors.orange;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Colors.grey;
      case 'expired':
        return Colors.red.shade400;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel() {
    switch (booking.status.name) {
      case 'confirmed':
        return 'Đã xác nhận';
      case 'checkedIn':
        return 'Đang chơi';
      case 'pendingDeposit':
        return 'Chờ cọc';
      case 'cancelledByPlayer':
        return 'Đã hủy';
      case 'cancelledByCafe':
        return 'Quán hủy';
      case 'expired':
        return 'Hết hạn';
      default:
        return booking.status.name;
    }
  }

  IconData _statusIcon() {
    switch (booking.status.name) {
      case 'confirmed':
        return Icons.check_circle;
      case 'checkedIn':
        return Icons.sports_esports;
      case 'pendingDeposit':
        return Icons.hourglass_empty;
      case 'cancelledByPlayer':
      case 'cancelledByCafe':
        return Icons.cancel;
      case 'expired':
        return Icons.timer_off;
      default:
        return Icons.event;
    }
  }

  void _openDetail(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingDetailPage(booking: booking),
      ),
    );

    // Khi quay lại, reload để cập nhật trạng thái (vd: sau check-in).
    if (result == true) {
      await onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => _openDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.1),
                child: Icon(_statusIcon(), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.gameName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '📍 ${booking.cafeName}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '🕒 ${DateFormat('HH:mm — dd/MM').format(booking.scheduledTime)}'
                      ' • ${booking.seatCount} người',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _statusLabel(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tab: Lịch sử booking (đã qua).
class _HistoryTab extends StatelessWidget {
  final BookingResultState state;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (state is ResultLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final List<BookingHistoryEntity> historyItems;
    if (state is ResultHistory) {
      historyItems = (state as ResultHistory).items;
    } else if (state is ResultUpcomingAndHistory) {
      historyItems = (state as ResultUpcomingAndHistory).history;
    } else {
      historyItems = const <BookingHistoryEntity>[];
    }

    if (historyItems.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(child: Text('Chưa có lịch sử đặt chỗ.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: historyItems.length,
        itemBuilder: (context, i) => _HistoryCard(item: historyItems[i]),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final BookingHistoryEntity item;

  const _HistoryCard({required this.item});

  Color _statusColor(BuildContext context) {
    switch (item.status) {
      case BookingHistoryStatus.upcoming:
        return Colors.blue;
      case BookingHistoryStatus.completed:
        return Colors.green;
      case BookingHistoryStatus.cancelled:
        return Colors.grey;
      case BookingHistoryStatus.noShow:
        return Colors.red;
    }
  }

  String _statusLabel() {
    switch (item.status) {
      case BookingHistoryStatus.upcoming:
        return 'Sắp tới';
      case BookingHistoryStatus.completed:
        return 'Đã chơi';
      case BookingHistoryStatus.cancelled:
        return 'Đã huỷ';
      case BookingHistoryStatus.noShow:
        return 'Vắng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.gameName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '📍 ${item.cafeName}',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              '🕒 ${DateFormat('HH:mm — dd/MM/yyyy').format(item.scheduledTime)}',
              style: theme.textTheme.bodySmall,
            ),
            if (item.hasNoShowBadge) ...[
              const SizedBox(height: 8),
              const NoShowBadge(),
            ],
          ],
        ),
      ),
    );
  }
}
