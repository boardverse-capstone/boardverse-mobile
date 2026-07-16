import 'package:flutter/material.dart';

import '../../../features/booking_payment/presentation/pages/booking_history_page.dart';

/// Trang "Lịch hẹn" trên bottom nav — delegate toàn bộ UI cho
/// [BookingHistoryPage] (Task 2).
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: BookingHistoryPage(),
    );
  }
}