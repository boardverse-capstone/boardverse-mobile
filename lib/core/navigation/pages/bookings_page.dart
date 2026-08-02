import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../../core/theme/theme.dart';
import '../../../features/booking_payment/domain/entities/deposit_config_entity.dart';
import '../../../features/booking_payment/domain/enums/payment_method.dart';
import '../../../features/booking_payment/presentation/cubit/booking_history_cubit.dart';
import '../../../features/booking_payment/presentation/pages/booking_history_page.dart';
import '../../../features/booking_payment/presentation/pages/payment_page.dart';
import '../widgets/booking_pending_resume_helper.dart';

/// Tab "Lịch đặt" (`BookingsPage`) — wrap `BookingHistoryPageContent` + banner
/// "Tiếp tục thanh toán" nếu `pendingBookingId` còn trong secure storage.
///
/// Đã chuyển từ placeholder sang tích hợp history thật (real API) kèm
/// resume flow thủ công (user bấm banner thay vì auto-navigate).
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  static void requestRefresh(BuildContext context) {
    BookingRefreshSignal.instance.notify();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BookingHistoryCubit>(
      create: (_) => sl<BookingHistoryCubit>()..loadAll(),
      child: const SafeArea(child: BookingsTabContent()),
    );
  }
}

class BookingsTabContent extends StatelessWidget {
  const BookingsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    final historyCubit = context.read<BookingHistoryCubit>();
    return Column(
      children: [
        _PendingDepositBanner(historyCubit: historyCubit),
        Expanded(
          child: BlocBuilder<BookingHistoryCubit, BookingHistoryState>(
            builder: (context, state) {
              return BookingHistoryPageContent(
                state: state,
                onRefresh: historyCubit.loadAll,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PendingDepositBanner extends StatefulWidget {
  final BookingHistoryCubit historyCubit;
  const _PendingDepositBanner({required this.historyCubit});

  @override
  State<_PendingDepositBanner> createState() => _PendingDepositBannerState();
}

class _PendingDepositBannerState extends State<_PendingDepositBanner> {
  String? _bookingId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    BookingRefreshSignal.instance.addListener(_onRefresh);
  }

  @override
  void dispose() {
    BookingRefreshSignal.instance.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    final id = await sl<BookingPersistenceResumeHelper>().readPendingBookingId();
    if (!mounted) return;
    setState(() {
      _bookingId = id;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_bookingId == null || _bookingId!.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Material(
      color: AppColors.warning.withValues(alpha: 0.12),
      child: InkWell(
        onTap: () => _resume(context),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.20),
                  borderRadius: AppRadius.radiusSmAll,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  size: AppIcons.md,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Đang có đơn chờ thanh toán',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Bấm để tiếp tục thanh toán cọc SePay.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _resume(BuildContext context) async {
    // Capture các "InheritedWidget" handle TRƯỚC khi qua `await` để
    // tránh `use_build_context_synchronously`.
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final helper = sl<BookingPersistenceResumeHelper>();
    final rawId = await helper.readPendingId();
    if (!mounted || rawId == null) return;

    final deposit = await helper.fetchDepositStatus(rawId);
    if (!mounted) return;
    final booking = await helper.fetchBooking(rawId);
    if (!mounted) return;

    String bookingId = rawId;
    String cafeId = '';
    String cafeName = '';
    double depositAmount = 0;
    DateTime deadline = DateTime.now().add(const Duration(minutes: 5));

    if (deposit != null) {
      bookingId = deposit.bookingId ?? rawId;
      cafeId = deposit.cafeId;
      cafeName = deposit.cafeName ?? '';
      depositAmount = deposit.amount;
      deadline = deposit.qrExpiresAt ?? deadline;
    } else if (booking != null) {
      cafeId = booking.cafeId;
      cafeName = booking.cafeName;
      depositAmount = booking.depositAmount;
      deadline = booking.depositDeadline;
    } else {
      await helper.clearPending();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Đơn đặt chỗ đã hết hạn, vui lòng tạo lại.'),
        ),
      );
      widget.historyCubit.loadAll();
      return;
    }

    if (booking != null && booking.status.name != 'pendingDeposit') {
      await helper.clearPending();
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Đơn đã hoàn tất hoặc hết hạn.')),
      );
      widget.historyCubit.loadAll();
      return;
    }

    final config = cafeId.isNotEmpty
        ? await helper.fetchDepositConfig(cafeId)
        : null;
    if (!mounted) return;
    final cfg = config ??
        DepositConfigEntity(
          cafeId: cafeId,
          firstHourPrice: 0,
          entryFee: 0,
          maxDeposit: depositAmount,
          defaultDeposit: depositAmount,
          graceMinutes: 15,
        );
    navigator.push(
      MaterialPageRoute(
        builder: (_) => PaymentPage(
          bookingId: bookingId,
          cafeId: cafeId,
          cafeName: cafeName,
          depositAmount: depositAmount,
          deadline: deadline,
          config: cfg,
          method: PaymentMethod.sepay,
        ),
      ),
    );
  }
}

/// Singleton signal — đồng bộ refresh giữa các trang booking.
///
/// `BookingsPage` lắng nghe listener này để gọi `loadAll()` khi:
/// - User double-tap vào tab Bookings.
/// - Có booking mới được tạo (vd: từ `BookingSuccessPage`).
/// - Deep-link SePay return trigger refresh.
class BookingRefreshSignal extends ChangeNotifier {
  BookingRefreshSignal._();

  static final BookingRefreshSignal instance = BookingRefreshSignal._();

  void notify() {
    if (hasListeners) notifyListeners();
  }
}

/// Bridge tới [BookingRefreshSignal] — dùng cho `DeepLinkHandler` không
/// muốn phụ thuộc trực tiếp vào widget tree.
void notifyBookingRefresh() => BookingRefreshSignal.instance.notify();
