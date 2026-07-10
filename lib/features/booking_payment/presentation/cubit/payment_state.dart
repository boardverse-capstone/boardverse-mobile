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

  const PaymentAwaitingCallback({
    required this.amount,
    required this.deadline,
    required this.method,
    required this.config,
  });

  @override
  List<Object?> get props => [amount, deadline, method, config];
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