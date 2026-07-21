import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/booking_payment/presentation/cubit/booking_result_cubit.dart';
import '../../../features/booking_payment/presentation/pages/booking_history_page.dart';

/// Tab "Phòng chờ" — delegate toàn bộ UI cho [BookingHistoryPage].
///
/// Each tap on the bottom-nav Books tab triggers a soft refresh via
/// [BookingRefreshSignal]; [BookingHistoryPage] listens to it and reloads
/// the upcoming + history lists.
class BookingsPage extends StatefulWidget {
  const BookingsPage({super.key});

  /// Asks the active [BookingHistoryPage] (if any) to reload its data.
  /// Safe to call when the page is not mounted.
  static void requestRefresh(BuildContext context) {
    BookingRefreshSignal.instance.notify();
  }

  @override
  State<BookingsPage> createState() => _BookingsPageState();
}

class _BookingsPageState extends State<BookingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BookingResultCubit>().loadUpcomingAndHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const BookingHistoryPage();
  }
}

/// Tiny notifier used to broadcast a "refresh bookings" request from the
/// bottom-nav double-tap handler down to the [BookingHistoryPage] without
/// adding another cubit to the navigation state.
class BookingRefreshSignal extends ChangeNotifier {
  BookingRefreshSignal._();
  static final BookingRefreshSignal instance = BookingRefreshSignal._();

  void notify() {
    if (hasListeners) notifyListeners();
  }
}