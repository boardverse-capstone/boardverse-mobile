import 'package:equatable/equatable.dart';

import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/payment_method.dart';

sealed class BookingSummaryState extends Equatable {
  const BookingSummaryState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái ban đầu, chưa gọi API.
class SummaryInitial extends BookingSummaryState {
  const SummaryInitial();
}

/// Đang tải `DepositConfig` cho quán.
class SummaryLoading extends BookingSummaryState {
  const SummaryLoading();
}

/// Đã có cấu hình cọc và phương thức thanh toán Host chọn.
class SummaryReady extends BookingSummaryState {
  final DepositConfigEntity config;
  final Breakdown breakdown;
  final PaymentMethod selectedMethod;

  const SummaryReady({
    required this.config,
    required this.breakdown,
    required this.selectedMethod,
  });

  BookingSummaryState copyWith({
    PaymentMethod? selectedMethod,
  }) =>
      SummaryReady(
        config: config,
        breakdown: breakdown,
        selectedMethod: selectedMethod ?? this.selectedMethod,
      );

  @override
  List<Object?> get props => [config, breakdown, selectedMethod];
}

/// Đang gửi request tạo booking lên server.
class SummarySubmitting extends BookingSummaryState {
  const SummarySubmitting();
}

/// Tạo đơn thành công — chuyển sang trang Payment.
class SummarySuccess extends BookingSummaryState {
  final String bookingId;
  final DateTime deadline;
  final double depositAmount;

  const SummarySuccess({
    required this.bookingId,
    required this.deadline,
    required this.depositAmount,
  });

  @override
  List<Object?> get props => [bookingId, deadline, depositAmount];
}

/// Validation fail (BR-03) hoặc server fail.
class SummaryFailure extends BookingSummaryState {
  final String code;
  final String message;

  const SummaryFailure({required this.code, required this.message});

  @override
  List<Object?> get props => [code, message];
}

/// Thông tin breakdown giá để hiển thị ở UI Summary.
class Breakdown extends Equatable {
  final double firstHourPrice;
  final double recommendedDeposit;
  final double maxDeposit;
  final String currency;
  final String pricingModelLabel;

  const Breakdown({
    required this.firstHourPrice,
    required this.recommendedDeposit,
    required this.maxDeposit,
    required this.currency,
    required this.pricingModelLabel,
  });

  @override
  List<Object?> get props =>
      [firstHourPrice, recommendedDeposit, maxDeposit, currency, pricingModelLabel];
}