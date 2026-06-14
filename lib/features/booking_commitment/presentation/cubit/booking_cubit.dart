import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mock_booking_datasource.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _repository;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 5);

  BookingCubit({required this._repository})
      : super(const BookingInitial());

  // ─── Initiate Deposit ─────────────────────────────────────────────────

  Future<void> initiateDeposit({
    required String lobbyId,
    required double amount,
  }) async {
    emit(const BookingLoading());

    final result = await _repository.initiateDeposit(
      lobbyId: lobbyId,
      amount: amount,
    );

    result.fold(
      (failure) => emit(BookingFailure(message: failure.message)),
      (deposit) {
        _remainingTime = deposit.deadline.difference(DateTime.now());
        _startCountdown(deposit.deadline);
        emit(DepositPending(
          deposit: deposit,
          userBalance: 150000,
          remainingTime: _remainingTime,
        ));
      },
    );
  }

  // ─── Make Deposit ────────────────────────────────────────────────────

  Future<void> makeDeposit(String depositId) async {
    final currentState = state;
    if (currentState is! DepositPending) return;

    emit(const DepositProcessing());

    final result = await _repository.makeDeposit(depositId);

    result.fold(
      (failure) => emit(BookingFailure(message: failure.message)),
      (deposit) {
        if (deposit.status == DepositStatus.allPaid) {
          emit(DepositSuccess(deposit: deposit));
          _confirmBooking(depositId);
        } else {
          emit(DepositPending(
            deposit: deposit,
            userBalance: currentState.userBalance - deposit.amount,
            remainingTime: _remainingTime,
          ));
        }
      },
    );
  }

  // ─── Confirm Booking ─────────────────────────────────────────────────

  Future<void> _confirmBooking(String depositId) async {
    final result = await _repository.confirmBooking(depositId);

    result.fold(
      (failure) => emit(BookingFailure(message: failure.message)),
      (booking) => emit(BookingConfirmed(booking: booking)),
    );
  }

  // ─── Countdown Timer ─────────────────────────────────────────────────

  void _startCountdown(DateTime deadline) {
    _countdownTimer?.cancel();
    _remainingTime = deadline.difference(DateTime.now());

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingTime = deadline.difference(DateTime.now());

      if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
        _stopCountdown();
        _handleDepositTimeout();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _handleDepositTimeout() {
    final timeoutError = MockBookingDatasource.mockDepositTimeoutError;
    emit(DepositTimeout(
      refundAmount: timeoutError.refundAmount,
      karmaPenalty: timeoutError.karmaPenalty,
    ));
  }

  Duration get remainingTime => _remainingTime;

  // ─── Load Mock Deposit (for development) ─────────────────────────────

  void loadMockDeposit() {
    final mockDeposit = MockBookingDatasource.mockDepositStatusList;
    _remainingTime = mockDeposit.deadline.difference(DateTime.now());
    _startCountdown(mockDeposit.deadline);
    emit(DepositPending(
      deposit: mockDeposit.toEntity(),
      userBalance: 150000,
      remainingTime: _remainingTime,
    ));
  }

  @override
  Future<void> close() {
    _stopCountdown();
    return super.close();
  }
}
