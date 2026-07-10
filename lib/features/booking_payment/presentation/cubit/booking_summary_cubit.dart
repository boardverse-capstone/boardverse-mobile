import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_summary_state.dart';

/// Cubit cho trang `BookingSummaryPage` — load cấu hình cọc, validate
/// BR-03 (deposit cap), và gửi request tạo booking.
class BookingSummaryCubit extends Cubit<BookingSummaryState> {
  final BookingRepository _repository;

  BookingSummaryCubit({required this._repository})
      : super(const SummaryInitial());

  Future<void> loadConfig(String cafeId) async {
    emit(const SummaryLoading());
    final result = await _repository.getDepositConfig(cafeId);
    result.fold(
      (failure) => emit(
        SummaryFailure(code: 'FETCH_CONFIG', message: failure.message),
      ),
      (config) {
        final breakdown = Breakdown(
          firstHourPrice: config.firstHourPrice,
          recommendedDeposit: config.defaultDeposit,
          maxDeposit: config.maxDeposit,
          currency: config.currency,
          pricingModelLabel: config.pricingModel.name,
        );
        emit(SummaryReady(
          config: config,
          breakdown: breakdown,
          selectedMethod: PaymentMethod.sandboxMock,
        ));
      },
    );
  }

  void selectPaymentMethod(PaymentMethod method) {
    final current = state;
    if (current is SummaryReady) {
      emit(current.copyWith(selectedMethod: method));
    }
  }

  Future<void> submit({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required List<String> memberIds,
  }) async {
    final current = state;
    if (current is! SummaryReady) {
      emit(const SummaryFailure(
        code: 'NO_CONFIG',
        message: 'Chưa tải cấu hình quán. Vui lòng thử lại.',
      ));
      return;
    }

    final amount = current.config.defaultDeposit;
    // BR-03 — validate deposit cap phía client.
    if (!current.config.canAccept(amount)) {
      emit(SummaryFailure(
        code: 'DEPOSIT_CAP',
        message:
            'Cọc vượt quá giới hạn (${current.config.maxDeposit.toStringAsFixed(0)} ${current.config.currency}).',
      ));
      return;
    }

    emit(const SummarySubmitting());
    final result = await _repository.createBooking(
      cafeId: cafeId,
      gameId: gameId,
      scheduledTime: scheduledTime,
      seatCount: seatCount,
      depositAmount: amount,
      paymentMethod: current.selectedMethod,
      memberIds: memberIds,
    );

    result.fold(
      (failure) => emit(SummaryFailure(code: 'CREATE', message: failure.message)),
      (booking) => emit(SummarySuccess(
        bookingId: booking.id,
        deadline: booking.depositDeadline,
        depositAmount: booking.depositAmount,
      )),
    );
  }
}