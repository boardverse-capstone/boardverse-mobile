import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/booking_persistence_service.dart';
import '../../data/datasources/base/payment_gateway.dart';
import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/entities/deposit_payment_entity.dart';
import '../../domain/enums/payment_method.dart';
import '../../domain/repositories/booking_repository.dart';
import 'payment_state.dart';

/// Cubit xử lý luồng thanh toán — gọi `createDepositPayment` mở SePay URL
/// + polling kết quả. Khi `Paid` → `PaymentSuccess` (không qua bước
/// `confirmBookingPayment` nữa vì backend tự detect qua webhook).
///
/// Lưu `pendingDepositId` để resume flow nếu user kill app.
///
/// Tính năng nâng cấp (theo `.agents/docs/apis_docs/payment.md`):
/// - Truyền `requiresManualConfirmation` + `qrUrl` qua state để UI biết
///   khi nào cần hiển thị nút "Đã chuyển khoản thủ công".
/// - Auto-detect `QrExpired` từ polling → trigger `regenerateDepositQr`.
/// - Cung cấp `regenerateQr()` action user-trigger.
class PaymentCubit extends Cubit<PaymentState> {
  final BookingRepository repository;
  final PaymentGateway gateway;
  final BookingPersistenceService persistence;

  StreamSubscription<PaymentResult>? _resultSub;
  Timer? _countdownTimer;
  DateTime? _deadline;
  String? _bookingId;
  String? _depositId;

  /// Cache `DepositPaymentEntity` từ lần mở gần nhất để dùng cho
  /// `regenerateQr` (giữ `orderId` cho UI hiển thị).
  DepositPaymentEntity? _lastPayment;

  PaymentCubit({
    required this.repository,
    required this.gateway,
    required this.persistence,
  }) : super(const PaymentIdle());

  /// Bắt đầu flow: gọi `createDepositPayment` → mở URL qua `url_launcher`
  /// → polling kết quả qua `gateway.watchResult`.
  Future<void> start({
    required String bookingId,
    required double amount,
    required PaymentMethod method,
    required DateTime deadline,
    required DepositConfigEntity config,
  }) async {
    _bookingId = bookingId;
    _deadline = deadline;
    await persistence.savePendingBookingId(bookingId);

    emit(const PaymentOpening());
    final openResult = await gateway.openGateway(
      bookingId: bookingId,
      amount: amount,
      method: method,
    );

    if (isClosed) return;
    await openResult.fold(
      (failure) async => emit(PaymentFailed(reason: failure.message)),
      (transactionRef) async {
        _depositId = transactionRef;
        await persistence.savePendingDepositId(transactionRef);
        // Lấy payment detail để có qrUrl + orderId cho UI.
        final statusResult = await repository.getDepositStatus(transactionRef);
        statusResult.fold(
          (_) => null,
          (s) => _lastPayment = DepositPaymentEntity(
            depositId: s.depositId,
            orderId: s.orderId,
            qrUrl: '',
            paymentUrl: '',
            qrExpiresAt: s.qrExpiresAt,
            amount: s.amount,
            requiresManualConfirmation: false,
          ),
        );
        emit(PaymentAwaitingCallback(
          amount: amount,
          deadline: deadline,
          method: method,
          config: config,
          requiresManualConfirmation: _lastPayment?.requiresManualConfirmation ?? false,
          qrUrl: _lastPayment?.qrUrl,
          depositId: transactionRef,
          orderId: _lastPayment?.orderId,
        ));
        _startCountdown();
        _resultSub = gateway
            .watchResult(transactionRef)
            .listen(_handleGatewayResult);
      },
    );
  }

  /// User chủ động huỷ → gọi API cancel + clear pending → emit PaymentFailed.
  Future<void> cancelByUser(String reason) async {
    final bookingId = _bookingId;
    _stopTimers();
    await persistence.clearPendingBookingId();
    await persistence.clearPendingDepositId();
    if (bookingId == null) {
      emit(const PaymentFailed(reason: 'Đã huỷ'));
      return;
    }
    final result = await repository.cancelBookingByPlayer(
      bookingId: bookingId,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(PaymentFailed(reason: failure.message)),
      (_) => emit(const PaymentFailed(reason: 'Đã huỷ')),
    );
  }

  /// Force poll — user nhấn "Tôi đã thanh toán".
  /// Hiện tại gateway tự polling 3s; method này chỉ re-subscribe.
  void forceRetry() {
    final depositId = _depositId;
    if (depositId == null) return;
    _resultSub?.cancel();
    _resultSub = gateway.watchResult(depositId).listen(_handleGatewayResult);
  }

  /// Tạo lại QR khi QR cũ hết hạn (BR-06).
  ///
  /// Flow: `POST /api/payments/booking-deposit/{id}/regenerate-qr` →
  /// backend trả `DepositPaymentEntity` mới → lưu lại vào state
  /// `PaymentAwaitingCallback` với `qrExpiresAt` mới.
  Future<void> regenerateQr() async {
    final depositId = _depositId;
    if (depositId == null) return;
    emit(const PaymentRegenerating());
    final result = await repository.regenerateDepositQr(depositId);
    if (isClosed) return;
    await result.fold(
      (failure) async => emit(PaymentFailed(reason: failure.message)),
      (payment) async {
        _lastPayment = payment;
        final current = state;
        if (current is PaymentAwaitingCallback) {
          // Backend đã set QR mới — tự refresh deadline +5 phút nếu null.
          final newDeadline = payment.qrExpiresAt ??
              DateTime.now().add(const Duration(minutes: 5));
          _deadline = newDeadline;
          _startCountdown();
          emit(current.copyWith(
            depositId: payment.depositId,
            orderId: payment.orderId,
            deadline: newDeadline,
            qrUrl: payment.qrUrl,
          ));
          // Re-subscribe polling với depositId (mới hoặc cũ).
          _resultSub?.cancel();
          _resultSub = gateway
              .watchResult(payment.depositId)
              .listen(_handleGatewayResult);
        } else {
          emit(PaymentFailed(reason: 'Trạng thái không hợp lệ'));
        }
      },
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
    final bookingId = _bookingId;
    if (bookingId == null) return;
    _stopTimers();
    await persistence.clearPendingBookingId();
    await persistence.clearPendingDepositId();
    // Backend tự đẩy status = Confirmed qua webhook → chỉ phát success để UI
    // navigate. Không gọi `confirmBookingPayment` (đã bỏ).
    emit(PaymentSuccess(bookingId: bookingId));
  }

  Future<void> _onPaymentFailed(String reason) async {
    final bookingId = _bookingId;
    _stopTimers();
    if (bookingId == null) {
      emit(PaymentFailed(reason: reason));
      return;
    }
    // Tự huỷ booking trên server để tránh stuck `PendingDeposit`.
    await repository.cancelBookingByPlayer(
      bookingId: bookingId,
      reason: 'Thanh toán thất bại: $reason',
    );
    await persistence.clearPendingBookingId();
    await persistence.clearPendingDepositId();
    if (isClosed) return;
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
      await persistence.clearPendingDepositId();
      emit(const PaymentTimeout());
      return;
    }
    await repository.cancelBookingByPlayer(
      bookingId: bookingId,
      reason: 'Hết thời gian giữ chỗ (BR-06)',
    );
    await persistence.clearPendingBookingId();
    await persistence.clearPendingDepositId();
    if (isClosed) return;
    emit(const PaymentTimeout());
  }

  void _stopTimers() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _resultSub?.cancel();
    _resultSub = null;
  }

  @override
  Future<void> close() async {
    _stopTimers();
    return super.close();
  }
}