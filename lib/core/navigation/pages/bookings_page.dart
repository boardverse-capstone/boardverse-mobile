import 'package:flutter/material.dart';

/// Temporary screen for booking-related content.
class BookingsPage extends StatelessWidget {
  const BookingsPage({super.key});

  static void requestRefresh(BuildContext context) {
    BookingRefreshSignal.instance.notify();
  }

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Đây là screen liên quan tới module booking',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class BookingRefreshSignal extends ChangeNotifier {
  BookingRefreshSignal._();

  static final BookingRefreshSignal instance = BookingRefreshSignal._();

  void notify() {
    if (hasListeners) notifyListeners();
  }
}
