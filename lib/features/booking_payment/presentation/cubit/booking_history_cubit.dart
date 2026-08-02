import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/booking_entity.dart';
import '../../domain/entities/booking_history_entity.dart';
import '../../domain/entities/cafe_booking_summary_entity.dart';
import '../../domain/repositories/booking_repository.dart';

/// Cubit dùng riêng cho `BookingHistoryPage` — gọi
/// `BookingRepository.loadAllForUser` (orchestrate hosted + joined lobbies)
/// hoặc `getBookingsForCafe` cho Player view (gap #14).
///
/// Tách khỏi `BookingResultCubit` để tránh truy cập root cubit (giảm
/// coupling) theo plan tổng.
class BookingHistoryCubit extends Cubit<BookingHistoryState> {
  final BookingRepository _repository;

  BookingHistoryCubit({required this._repository})
      : super(const BookingHistoryInitial());

  /// Load toàn bộ booking của user hiện tại (hosted + joined).
  Future<void> loadAll() async {
    emit(const BookingHistoryLoading());
    final result = await _repository.loadAllForUser();
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingHistoryFailure(failure.message)),
      (uh) => emit(BookingHistoryLoaded(
        upcoming: uh.upcoming,
        history: uh.history,
        cafeView: const [],
      )),
    );
  }

  /// Load bookings cho 1 cafe cụ thể (gap #14 — Player view).
  /// Kết quả trả summary rút gọn (CafeBookingSummaryEntity), không
  /// dùng để push BookingDetailPage — chỉ hiển thị danh sách lịch.
  Future<void> loadForCafe(String cafeId) async {
    emit(const BookingHistoryLoading());
    final result = await _repository.getBookingsForCafe(cafeId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(BookingHistoryFailure(failure.message)),
      (cafeList) => emit(BookingHistoryLoaded(
        upcoming: const [],
        history: const [],
        cafeView: cafeList,
      )),
    );
  }
}

/// Sealed state cho `BookingHistoryCubit`.
sealed class BookingHistoryState extends Equatable {
  const BookingHistoryState();
  @override
  List<Object?> get props => [];
}

class BookingHistoryInitial extends BookingHistoryState {
  const BookingHistoryInitial();
}

class BookingHistoryLoading extends BookingHistoryState {
  const BookingHistoryLoading();
}

class BookingHistoryLoaded extends BookingHistoryState {
  final List<BookingEntity> upcoming;
  final List<BookingHistoryEntity> history;
  final List<CafeBookingSummaryEntity> cafeView;
  const BookingHistoryLoaded({
    required this.upcoming,
    required this.history,
    required this.cafeView,
  });

  @override
  List<Object?> get props => [upcoming, history, cafeView];
}

class BookingHistoryFailure extends BookingHistoryState {
  final String message;
  const BookingHistoryFailure(this.message);
  @override
  List<Object?> get props => [message];
}