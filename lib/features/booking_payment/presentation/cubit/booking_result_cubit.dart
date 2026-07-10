import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../../domain/enums/booking_status.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_result_state.dart';

/// Cubit dùng cho `BookingSuccessPage` + `BookingHistoryPage`
/// + resume flow khi kill app giữa chừng.
class BookingResultCubit extends Cubit<BookingResultState> {
  final BookingRepository _repository;
  StreamSubscription<BookingEntity>? _statusSub;

  BookingResultCubit({required this._repository})
      : super(const ResultInitial());

  /// Load booking theo id — dùng cho resume + Success page.
  Future<void> loadById(String bookingId) async {
    emit(const ResultLoading());
    final result = await _repository.getBookingById(bookingId);
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (booking) => emit(mapStatusToState(booking)),
    );
  }

  /// Polling status — đón khi server chuyển sang `checkedIn`.
  /// Hủy subscription cũ trước khi đăng ký mới.
  void startPolling(String bookingId, {Duration interval = const Duration(seconds: 3)}) {
    _statusSub?.cancel();
    _statusSub = _repository
        .watchBookingStatus(bookingId)
        .listen((booking) {
      if (booking.status == BookingStatus.checkedIn ||
          booking.status.isTerminal) {
        emit(mapStatusToState(booking));
      }
    });
  }

  /// Host huỷ booking (success page có nút "Huỷ đơn").
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
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (booking) => emit(ResultCancelled(booking)),
    );
  }

  /// Lấy lịch sử booking.
  Future<void> loadHistory() async {
    emit(const ResultLoading());
    final result = await _repository.getBookingHistory();
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (items) => emit(ResultHistory(items)),
    );
  }

  /// Lấy các booking sắp tới (confirmed + checkedIn).
  Future<void> loadUpcomingBookings() async {
    emit(const ResultLoading());
    final result = await _repository.getUpcomingBookings();
    result.fold(
      (failure) => emit(ResultFailure(failure.message)),
      (bookings) => emit(ResultUpcomingBookings(bookings)),
    );
  }

  /// Load song song upcoming + history rồi emit 1 state duy nhất
  /// để tránh race khi UI dùng chung 1 cubit cho cả 2 tab.
  Future<void> loadUpcomingAndHistory() async {
    final upcomingF = _repository.getUpcomingBookings();
    final historyF = _repository.getBookingHistory();
    final results = await Future.wait([upcomingF, historyF]);
    final upcomingResult = results[0];
    final historyResult = results[1];

    final List<BookingEntity> upcoming = upcomingResult.fold(
      (_) => <BookingEntity>[],
      (list) => list as List<BookingEntity>,
    );
    final List<BookingHistoryEntity> history = historyResult.fold(
      (_) => <BookingHistoryEntity>[],
      (list) => list as List<BookingHistoryEntity>,
    );

    emit(ResultUpcomingAndHistory(
      upcoming: upcoming,
      history: history,
    ));
  }

  /// Resume flow — kiểm tra `pendingBookingId` lưu ở secure storage.
  Future<void> tryRestorePending() async {
    final idResult = await _repository.getPendingBookingId();
    final id = await idResult.fold((_) async => null, (v) async => v);
    if (id == null || id.isEmpty) {
      emit(const ResumeCleared());
      return;
    }
    final result = await _repository.getBookingById(id);
    result.fold(
      (failure) {
        // Không tìm thấy → clear để tránh vòng lặp.
        _repository.clearPendingBookingId();
        emit(const ResumeCleared());
      },
      (booking) {
        if (booking.status.isTerminal) {
          _repository.clearPendingBookingId();
          emit(const ResumeCleared());
        } else if (booking.status == BookingStatus.pendingDeposit) {
          emit(ResumeToPayment(booking.id));
        } else if (booking.status == BookingStatus.confirmed) {
          emit(ResumeToSuccess(booking.id));
        } else {
          emit(const ResumeCleared());
        }
      },
    );
  }

  @override
  Future<void> close() async {
    _statusSub?.cancel();
    return super.close();
  }
}