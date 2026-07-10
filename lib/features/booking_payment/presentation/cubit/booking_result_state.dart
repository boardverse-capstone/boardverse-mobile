import 'package:equatable/equatable.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../../domain/enums/booking_status.dart';

sealed class BookingResultState extends Equatable {
  const BookingResultState();

  @override
  List<Object?> get props => [];
}

class ResultInitial extends BookingResultState {
  const ResultInitial();
}

class ResultLoading extends BookingResultState {
  const ResultLoading();
}

class ResultConfirmed extends BookingResultState {
  final BookingEntity booking;
  const ResultConfirmed(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ResultCheckedIn extends BookingResultState {
  final BookingEntity booking;
  const ResultCheckedIn(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ResultExpired extends BookingResultState {
  final BookingEntity booking;
  const ResultExpired(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ResultCancelled extends BookingResultState {
  final BookingEntity booking;
  const ResultCancelled(this.booking);

  @override
  List<Object?> get props => [booking];
}

class ResultHistory extends BookingResultState {
  final List<BookingHistoryEntity> items;
  const ResultHistory(this.items);

  @override
  List<Object?> get props => [items];
}

/// Upcoming bookings (confirmed + checkedIn) để test check-in flow.
class ResultUpcomingBookings extends BookingResultState {
  final List<BookingEntity> bookings;
  const ResultUpcomingBookings(this.bookings);

  @override
  List<Object?> get props => [bookings];
}

/// State gộp upcoming + history để tránh race khi load đồng thời.
class ResultUpcomingAndHistory extends BookingResultState {
  final List<BookingEntity> upcoming;
  final List<BookingHistoryEntity> history;
  const ResultUpcomingAndHistory({
    required this.upcoming,
    required this.history,
  });

  @override
  List<Object?> get props => [upcoming, history];
}

/// Trạng thái emit khi resume → user đang ở màn thanh toán.
class ResumeToPayment extends BookingResultState {
  final String bookingId;
  const ResumeToPayment(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Trạng thái emit khi resume → user đã CONFIRMED, mở Success page.
class ResumeToSuccess extends BookingResultState {
  final String bookingId;
  const ResumeToSuccess(this.bookingId);

  @override
  List<Object?> get props => [bookingId];
}

/// Resume xong — không có pending booking nào.
class ResumeCleared extends BookingResultState {
  const ResumeCleared();
}

class ResultFailure extends BookingResultState {
  final String message;
  const ResultFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Map `BookingStatus` → state phù hợp.
BookingResultState mapStatusToState(BookingEntity booking) {
  switch (booking.status) {
    case BookingStatus.confirmed:
      return ResultConfirmed(booking);
    case BookingStatus.checkedIn:
      return ResultCheckedIn(booking);
    case BookingStatus.expired:
      return ResultExpired(booking);
    case BookingStatus.cancelledByPlayer:
    case BookingStatus.cancelledByCafe:
      return ResultCancelled(booking);
    case BookingStatus.pendingDeposit:
      // Khi load bằng id, đang PENDING_DEPOSIT → cũng là ResumeToPayment.
      return ResumeToPayment(booking.id);
  }
}
