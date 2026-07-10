import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/base/payment_gateway.dart';
import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import 'payment_state.dart';

/// Cubit xử lý luồng thanh toán — gọi gateway, polling kết quả,
/// đếm ngược deadline cọc, tự động huỷ khi hết hạn.
class PaymentCubit extends Cubit<PaymentState> {
  final BookingRepository _repository;
  final PaymentGateway _gateway;

  StreamSubscription<PaymentResult>? _resultSub;
  Timer? _countdownTimer;
  DateTime? _deadline;
  String? _bookingId;

  PaymentCubit({
    required this._repository,
    required this._gateway,
  }) : super(const PaymentIdle());

  /// Bắt đầu flow: mở gateway → lắng nghe kết quả + countdown.
  Future<void> start({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required DateTime deadline,
    required DepositConfigEntity config,
  }) async {
    _bookingId = bookingId;
    _deadline = deadline;

    emit(const PaymentOpening());
    final openResult = await _gateway.openGateway(
      bookingId: bookingId,
      amount: amount,
      method: method,
    );

    await openResult.fold(
      (failure) async =>
          emit(PaymentFailed(reason: failure.message)),
      (transactionRef) async {
        emit(PaymentAwaitingCallback(
          amount: amount,
          deadline: deadline,
          method: method,
          config: config,
        ));
        _startCountdown();
        _resultSub = _gateway
            .watchResult(transactionRef)
            .listen(_handleGatewayResult);
      },
    );
  }

  /// User chủ động huỷ → gọi API cancel rồi emit PaymentFailed.
  Future<void> cancelByUser(String reason) async {
    if (_bookingId == null) {
      emit(const PaymentFailed(reason: 'Đã huỷ'));
      return;
    }
    _stopTimers();
    final result = await _repository.cancelBookingByPlayer(
      bookingId: _bookingId!,
      reason: reason,
    );
    result.fold(
      (failure) => emit(PaymentFailed(reason: failure.message)),
      (_) => emit(const PaymentFailed(reason: 'Đã huỷ')),
    );
  }

  // ─── Internals ──────────────────────────────────────────────────────

  void _handleGatewayResult(PaymentResult result) {
    switch (result) {
      case GatewayPending():
        // vẫn chờ — widget đang hiện countdown.
        break;
      case GatewaySuccess(:final transactionRef):
        _onPaymentSuccess(transactionRef);
        break;
      case GatewayFailed(:final reason):
        _onPaymentFailed(reason);
        break;
    }
  }

  Future<void> _onPaymentSuccess(String transactionRef) async {
    if (_bookingId == null) return;
    _stopCountdownTimer();
    emit(const PaymentProcessing());
    final result = await _repository.confirmBookingPayment(
      bookingId: _bookingId!,
      paymentRef: transactionRef,
    );
    result.fold(
      (failure) => emit(PaymentFailed(reason: failure.message)),
      (_) => emit(PaymentSuccess(bookingId: _bookingId!)),
    );
  }

  Future<void> _onPaymentFailed(String reason) async {
    if (_bookingId == null) {
      emit(PaymentFailed(reason: reason));
      return;
    }
    _stopCountdownTimer();
    // Tự huỷ booking trên server để tránh EXPIRED state trên client.
    await _repository.cancelBookingByPlayer(
      bookingId: _bookingId!,
      reason: 'Thanh toán thất bại: $reason',
    );
    emit(PaymentFailed(reason: reason));
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final deadline = _deadline;
      if (deadline == null) return;
      final remaining = deadline.difference(DateTime.now());
      if (remaining.isNegative) {
        _onExpired();
      }
    });
  }

  Future<void> _onExpired() async {
    _stopTimers();
    final bookingId = _bookingId;
    if (bookingId == null) {
      emit(const PaymentTimeout());
      return;
    }
    await _repository.cancelBookingByPlayer(
      bookingId: bookingId,
      reason: 'Hết thời gian giữ chỗ (BR-06)',
    );
    emit(const PaymentTimeout());
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _stopTimers() {
    _stopCountdownTimer();
    _resultSub?.cancel();
    _resultSub = null;
  }

  @override
  Future<void> close() async {
    _stopTimers();
    return super.close();
  }
}