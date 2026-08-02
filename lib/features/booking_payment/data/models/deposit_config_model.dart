import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/pricing_model.dart';

/// JSON ↔ Entity cho `DepositConfigEntity`.
///
/// Endpoint: `GET /api/Cafes/{cafeId}/deposit-config`.
/// Dữ liệu trả về được bọc trong `ApiResponse.data`.
class DepositConfigModel {
  final String cafeId;
  final double firstHourPrice;
  final double entryFee;
  final double maxDeposit;
  final double defaultDeposit;
  final int graceMinutes;
  final int seatCount;
  final String currency;
  final String pricingModel;

  const DepositConfigModel({
    required this.cafeId,
    required this.firstHourPrice,
    required this.entryFee,
    required this.maxDeposit,
    required this.defaultDeposit,
    required this.graceMinutes,
    this.seatCount = 0,
    this.currency = 'VND',
    this.pricingModel = 'hourly',
  });

  factory DepositConfigModel.fromJson(Map<String, dynamic> json) {
    return DepositConfigModel(
      cafeId: json['cafeId'] as String? ?? '',
      firstHourPrice: (json['firstHourPrice'] as num).toDouble(),
      entryFee: (json['entryFee'] as num?)?.toDouble() ?? 0,
      maxDeposit: (json['maxDeposit'] as num).toDouble(),
      defaultDeposit: (json['defaultDeposit'] as num?)?.toDouble() ?? 0,
      graceMinutes: (json['graceMinutes'] as num?)?.toInt() ?? 30,
      seatCount: (json['seatCount'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      pricingModel: json['pricingModel'] as String? ?? 'hourly',
    );
  }

  DepositConfigEntity toEntity() => DepositConfigEntity(
        cafeId: cafeId,
        firstHourPrice: firstHourPrice,
        entryFee: entryFee,
        maxDeposit: maxDeposit,
        defaultDeposit: defaultDeposit,
        graceMinutes: graceMinutes,
        seatCount: seatCount,
        currency: currency,
        pricingModel: _pricingFromString(pricingModel),
      );

  static PricingModel _pricingFromString(String s) {
    switch (s) {
      case 'flatEntry':
        return PricingModel.flatEntry;
      case 'hourly':
      default:
        return PricingModel.hourly;
    }
  }
}
