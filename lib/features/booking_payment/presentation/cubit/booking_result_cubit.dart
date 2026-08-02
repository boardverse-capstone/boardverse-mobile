import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/deposit_status_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_result_state.dart';

/// Cubit dùng cho `BookingSuccessPage` + `BookingDetailPage` + resume flow.
///
/// Tích hợp mới (gap #11):
/// - `restoreFlow()` ưu tiên `pendingDepositId` (user đang mid-payment).
/// - Sau khi `Paid` → tự clear pending keys (đã làm trong repo).
/// - Polling 5s qua `getBookingById` để đón status thay đổi.
/// - `loadRefundContext` → fetch DepositStatus khi booking terminal để
///   render banner hoàn cọc / tịch thu (gap #11).
class BookingResultCubit extends Cubit<BookingResultState> {
  final BookingRepository _repository;
  StreamSubscription<dynamic>? _statusSub;

  BookingResultCubit({required this._repository})
      : super(const ResultInitial());

  Future<void> loadById(String bookingId) async {
    emit(const ResultLoading());
    final result = await _repository.getBookingById(bookingId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (booking) {
        emit(mapStatusToState(booking));
        // Khi terminal, thử fetch refund context (nếu có paymentRef).
        final paymentRef = booking.paymentRef;
        if (booking.status.isTerminal &&
            paymentRef != null &&
            paymentRef.isNotEmpty) {
          loadRefundContext(paymentRef);
        }
      },
    );
  }

  /// Polling `GET /api/bookings/{id}` mỗi 5s để đón backend cập nhật
  /// `status` (vd: thay đổi sang `CheckedIn` khi POS scan QR).
  ///
  /// Tự dừng khi:
  /// - trạng thái đạt terminal (checkedIn/noShow/cancelled).
  /// - trạng thái `confirmed` (BR-06 grace đã được set).
  void startPollingStatus(
    String bookingId, {
    Duration interval = const Duration(seconds: 5),
  }) {
    _statusSub?.cancel();
    _statusSub = Stream<void>.periodic(interval).asyncMap((_) async {
      final result = await _repository.getBookingById(bookingId);
      return result.fold(
        (failure) => null,
        (booking) => booking,
      );
    }).listen((booking) {
      if (booking == null) return;
      if (booking.status == BookingStatus.checkedIn) {
        emit(mapStatusToState(booking));
      } else if (booking.status.isTerminal) {
        emit(mapStatusToState(booking));
        _statusSub?.cancel();
      }
    });
  }

  /// Host huỷ booking (success page / detail page).
  Future<void> cancelByPlayer(String reason) async {
    final current = state;
    String? id;
    if (current is ResultConfirmed) {
      id = current.booking.id;
    }
    if (id == null) return;

    final result = await _repository.cancelBookingByPlayer(
      bookingId: id,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (booking) {
        emit(ResultCancelled(booking));
        final paymentRef = booking.paymentRef;
        if (paymentRef != null && paymentRef.isNotEmpty) {
          loadRefundContext(paymentRef);
        }
      },
    );
  }

  /// Fetch trạng thái deposit (refund/forfeit) cho booking terminal.
  /// Silent-fail nếu backend không trả (vd: thanh toán offline).
  Future<void> loadRefundContext(String depositId) async {
    final result = await _repository.getDepositStatus(depositId);
    if (isClosed) return;
    result.fold(
      (_) {/* silent — không hiển thị banner */},
      (status) {
        if (status.status.isRefundRelevant) {
          emit(RefundContextLoaded(status));
        }
      },
    );
  }

  /// Resume flow khi mở app sau khi kill giữa chừng (gap #11).
  ///
  /// Priority:
  /// 1. Nếu có `pendingDepositId` → user đang mid-payment → resume SePay
  ///    flow (poll deposit status, navigate về PaymentPage khi Paid).
  /// 2. Nếu có `pendingBookingId` → resume booking detail.
  /// 3. Nếu không có → emit `ResumeCleared`.
  Future<void> restoreFlow() async {
    emit(const ResultLoading());
    final depositIdResult = await _repository.getPendingDepositId();
    final bookingIdResult = await _repository.getPendingBookingId();

    String? pendingDepositId;
    String? pendingBookingId;
    depositIdResult.fold((_) => null, (value) => pendingDepositId = value);
    bookingIdResult.fold((_) => null, (value) => pendingBookingId = value);

    // Priority 1: deposit pending → resume payment flow.
    final depId = pendingDepositId;
    final bkId = pendingBookingId;
    if (depId != null && depId.isNotEmpty) {
      final statusResult = await _repository.getDepositStatus(depId);
      if (isClosed) return;
      DepositStatusEntity? status;
      statusResult.fold((_) => null, (value) => status = value);
      final s = status;
      if (s != null && s.status == DepositStatus.paid) {
        // Đã thanh toán rồi (webhook xử lý trước khi user mở lại app).
        await _repository.clearPendingBookingId();
        await _repository.clearPendingDepositId();
        emit(const ResumeCleared());
        return;
      }
      // Còn pending → resume tới PaymentPage (qua bookingId).
      if (bkId != null && bkId.isNotEmpty) {
        emit(ResumeToPayment(bkId));
        return;
      }
    }

    // Priority 2: chỉ có booking pending (không có deposit) → resume detail.
    if (bkId != null && bkId.isNotEmpty) {
      final bookingResult = await _repository.getBookingById(bkId);
      if (isClosed) return;
      BookingEntity? booking;
      bookingResult.fold((_) => null, (value) => booking = value);
      final b = booking;
      if (b != null) {
        emit(mapStatusToState(b));
        return;
      }
    }

    emit(const ResumeCleared());
  }

  @override
  Future<void> close() async {
    await _statusSub?.cancel();
    return super.close();
  }
}

/// Vẫn giữ để UI cũ (Success page) build được khi status = PendingDeposit.
BookingResultState mapStatusToState(BookingEntity booking) {
  switch (booking.status) {
    case BookingStatus.confirmed:
      return ResultConfirmed(booking);
    case BookingStatus.checkedIn:
      return ResultCheckedIn(booking);
    case BookingStatus.noShow:
    case BookingStatus.cancelled:
      return ResultCancelled(booking);
    case BookingStatus.pendingDeposit:
      return ResumeToPayment(booking.id);
  }
}