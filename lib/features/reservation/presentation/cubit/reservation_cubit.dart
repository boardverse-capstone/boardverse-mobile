import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'reservation_state.dart';

/// Cubit xử lý reservation flow (BR §6)
///
/// Flow:
/// 1. Tạo quote → hiển thị chi tiết cọc
/// 2. Kiểm tra balance
/// 3. Nếu đủ → confirm reservation (atomic transaction)
/// 4. Nếu không đủ → hiển thị dialog nạp tiền
/// 5. Sau khi nạp → refresh balance → confirm
class ReservationCubit extends Cubit<ReservationState> {
  final ReservationRepository repository;
  ReservationQuoteEntity? _currentQuote;

  ReservationCubit({required this.repository}) : super(const ReservationInitial());

  /// Tạo quote cho reservation
  Future<void> createQuote({
    required String cafeId,
    required String gameId,
    required DateTime playDate,
    required TimeSlot timeSlot,
    String? preferredStartTime,
    required int minPlayers,
    required int maxPlayers,
  }) async {
    emit(const ReservationQuoteLoading());

    final idempotencyKey =
        'quote-${DateTime.now().millisecondsSinceEpoch}';

    final result = await repository.createQuote(
      cafeId: cafeId,
      gameId: gameId,
      playDate: playDate,
      timeSlot: timeSlot,
      preferredStartTime: preferredStartTime,
      minPlayers: minPlayers,
      maxPlayers: maxPlayers,
      idempotencyKey: idempotencyKey,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ReservationQuoteError(message: failure.message));
      },
      (quote) async {
        _currentQuote = quote;

        // Kiểm tra balance
        if (!quote.hasEnoughBalance) {
          emit(ReservationInsufficientBalance(
            quote: quote,
            missingBvc: quote.missingAmount,
          ));
        } else {
          emit(ReservationQuoteLoaded(quote: quote));
        }
      },
    );
  }

  /// Confirm reservation (atomic transaction)
  Future<void> confirmReservation() async {
    final quote = _currentQuote;
    if (quote == null) {
      emit(const ReservationConfirmError(message: 'Không có thông tin quote'));
      return;
    }

    // Kiểm tra balance lại
    if (!quote.hasEnoughBalance) {
      emit(ReservationInsufficientBalance(
        quote: quote,
        missingBvc: quote.missingAmount,
      ));
      return;
    }

    emit(const ReservationConfirming());

    final idempotencyKey =
        'confirm-${DateTime.now().millisecondsSinceEpoch}';

    final result = await repository.confirmReservation(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      timeSlot: quote.timeSlot,
      preferredStartTime: quote.preferredStartTime,
      minPlayers: quote.minPlayers,
      maxPlayers: quote.maxPlayers,
      expectedFinalDeposit: quote.finalDeposit,
      idempotencyKey: idempotencyKey,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ReservationConfirmError(message: failure.message));
      },
      (confirmResult) async {
        emit(ReservationConfirmed(result: confirmResult));
      },
    );
  }

  /// Cancel reservation
  Future<void> cancelReservation(String reservationId, {String? reason}) async {
    emit(const ReservationCancelling());

    final result = await repository.cancelReservation(
      reservationId: reservationId,
      reason: reason,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(ReservationCancelError(message: failure.message));
      },
      (cancelResult) async {
        emit(ReservationCancelled(result: cancelResult));
      },
    );
  }

  /// Refresh balance sau khi top-up
  Future<void> refreshBalanceAndConfirm() async {
    // Tạo lại quote để lấy balance mới
    final quote = _currentQuote;
    if (quote == null) return;

    await createQuote(
      cafeId: quote.cafeId,
      gameId: quote.gameId,
      playDate: quote.playDate,
      timeSlot: quote.timeSlot,
      preferredStartTime: quote.preferredStartTime,
      minPlayers: quote.minPlayers,
      maxPlayers: quote.maxPlayers,
    );
  }

  /// Lấy quote hiện tại
  ReservationQuoteEntity? get currentQuote => _currentQuote;

  /// Reset state
  void reset() {
    _currentQuote = null;
    emit(const ReservationInitial());
  }
}
