import 'package:equatable/equatable.dart';

import '../../domain/entities/cafe_availability_entity.dart';
import '../../domain/entities/cafe_table_entity.dart';
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

/// Đang khảo sát capacity + load bàn trống (gap #1 + #2).
class SummaryLoadingTables extends BookingSummaryState {
  const SummaryLoadingTables();
}

/// Đã có cấu hình cọc, danh sách bàn trống + availability check.
class SummaryReady extends BookingSummaryState {
  final DepositConfigEntity config;
  final Breakdown breakdown;
  final PaymentMethod selectedMethod;

  /// Bàn trống trong khung giờ hiện tại (gap #1).
  final List<CafeTableEntity> availableTables;

  /// Kết quả khảo sát capacity (gap #2). Null nếu backend chưa có endpoint.
  final CafeAvailabilityEntity? availability;

  /// Bàn được chọn tự động theo strategy `single_default`.
  /// User có thể đổi qua UI.
  final String? selectedTableId;

  const SummaryReady({
    required this.config,
    required this.breakdown,
    required this.selectedMethod,
    this.availableTables = const [],
    this.availability,
    this.selectedTableId,
  });

  BookingSummaryState copyWith({
    PaymentMethod? selectedMethod,
    String? selectedTableId,
    List<CafeTableEntity>? availableTables,
    CafeAvailabilityEntity? availability,
  }) =>
      SummaryReady(
        config: config,
        breakdown: breakdown,
        selectedMethod: selectedMethod ?? this.selectedMethod,
        availableTables: availableTables ?? this.availableTables,
        availability: availability ?? this.availability,
        selectedTableId: selectedTableId ?? this.selectedTableId,
      );

  @override
  List<Object?> get props => [
        config,
        breakdown,
        selectedMethod,
        availableTables,
        availability,
        selectedTableId,
      ];
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
