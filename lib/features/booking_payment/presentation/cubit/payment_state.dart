import 'package:equatable/equatable.dart';

import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/payment_method.dart';

sealed class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi tạo.
class PaymentIdle extends PaymentState {
  const PaymentIdle();
}

/// Đang gọi `openGateway` để lấy transactionRef.
class PaymentOpening extends PaymentState {
  const PaymentOpening();
}

/// Gateway đã mở, đang chờ người dùng thao tác.
class PaymentAwaitingCallback extends PaymentState {
  final double amount;
  final DateTime deadline;
  final PaymentMethod method;
  final DepositConfigEntity config;

  /// Backend fallback sang VietQR tĩnh — user phải nhập manualRef
  /// (transferContent) trong app SePay thay vì quét QR tự động.
  final bool requiresManualConfirmation;

  /// QR URL render được khi `requiresManualConfirmation=true`.
  final String? qrUrl;

  /// Deposit id dùng cho polling/manual lookup.
  final String? depositId;

  /// OrderId `BV-...` để hiển thị cho user.
  final String? orderId;

  const PaymentAwaitingCallback({
    required this.amount,
    required this.deadline,
    required this.method,
    required this.config,
    this.requiresManualConfirmation = false,
    this.qrUrl,
    this.depositId,
    this.orderId,
  });

  PaymentAwaitingCallback copyWith({
    String? depositId,
    String? orderId,
    DateTime? deadline,
    String? qrUrl,
  }) =>
      PaymentAwaitingCallback(
        amount: amount,
        deadline: deadline ?? this.deadline,
        method: method,
        config: config,
        requiresManualConfirmation: requiresManualConfirmation,
        qrUrl: qrUrl ?? this.qrUrl,
        depositId: depositId ?? this.depositId,
        orderId: orderId ?? this.orderId,
      );

  @override
  List<Object?> get props => [
        amount,
        deadline,
        method,
        config,
        requiresManualConfirmation,
        qrUrl,
        depositId,
        orderId,
      ];
}

/// QR đã hết hạn (BR-06) — đang gọi `regenerate-qr`.
class PaymentRegenerating extends PaymentState {
  const PaymentRegenerating();
}

/// Đang gọi API `confirmBookingPayment`.
class PaymentProcessing extends PaymentState {
  const PaymentProcessing();
}

/// Thanh toán thành công — booking đã CONFIRMED.
class PaymentSuccess extends PaymentState {
  final String bookingId;

  const PaymentSuccess({required this.bookingId});

  @override
  List<Object?> get props => [bookingId];
}

/// Gateway báo fail hoặc user huỷ trên cổng.
class PaymentFailed extends PaymentState {
  final String reason;

  const PaymentFailed({required this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Countdown về 0 — đã tự động huỷ qua API.
class PaymentTimeout extends PaymentState {
  const PaymentTimeout();
}