import 'package:equatable/equatable.dart';

import '../enums/pricing_model.dart';

/// Cấu hình biểu phí + cọc của từng quán (BR-02, BR-03).
///
/// Server là source-of-truth cho `maxDeposit` (đã validate BR-03).
/// Client chỉ dùng để hiển thị + kiểm tra trước khi gửi request.
class DepositConfigEntity extends Equatable {
  final String cafeId;

  /// Giá giờ đầu — dùng làm mốc 50% cho BR-03.
  final double firstHourPrice;

  /// Giá vé vào cổng — chỉ dùng khi `pricingModel == flatEntry` (BR-01).
  final double entryFee;

  /// Trần cọc tối đa server cho phép (= 50% × firstHourPrice theo BR-03).
  final double maxDeposit;

  /// Mức cọc mặc định quán đề xuất.
  final double defaultDeposit;

  /// Số phút được phép giữ chỗ kể từ khi tạo đơn (BR-06, ≤ 30).
  final int graceMinutes;

  final String currency;
  final PricingModel pricingModel;

  const DepositConfigEntity({
    required this.cafeId,
    required this.firstHourPrice,
    required this.entryFee,
    required this.maxDeposit,
    required this.defaultDeposit,
    required this.graceMinutes,
    this.currency = 'VND',
    this.pricingModel = PricingModel.hourly,
  });

  /// BR-03: kiểm tra nhanh phía client. Server vẫn validate lần cuối.
  bool canAccept(double amount) =>
      amount >= 0 && amount <= maxDeposit;

  @override
  List<Object?> get props => [
        cafeId,
        firstHourPrice,
        entryFee,
        maxDeposit,
        defaultDeposit,
        graceMinutes,
        currency,
        pricingModel,
      ];
}