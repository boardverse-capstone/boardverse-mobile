import '../../domain/entities/deposit_config_entity.dart';
import '../../domain/enums/pricing_model.dart';

class DepositConfigModel {
  final String cafeId;
  final double firstHourPrice;
  final double entryFee;
  final double maxDeposit;
  final double defaultDeposit;
  final int graceMinutes;
  final String currency;
  final String pricingModel;

  const DepositConfigModel({
    required this.cafeId,
    required this.firstHourPrice,
    required this.entryFee,
    required this.maxDeposit,
    required this.defaultDeposit,
    required this.graceMinutes,
    this.currency = 'VND',
    this.pricingModel = 'hourly',
  });

  factory DepositConfigModel.fromJson(Map<String, dynamic> json) {
    return DepositConfigModel(
      cafeId: json['cafeId'] as String,
      firstHourPrice: (json['firstHourPrice'] as num).toDouble(),
      entryFee: (json['entryFee'] as num).toDouble(),
      maxDeposit: (json['maxDeposit'] as num).toDouble(),
      defaultDeposit: (json['defaultDeposit'] as num).toDouble(),
      graceMinutes: (json['graceMinutes'] as num).toInt(),
      currency: (json['currency'] as String?) ?? 'VND',
      pricingModel: (json['pricingModel'] as String?) ?? 'hourly',
    );
  }

  Map<String, dynamic> toJson() => {
        'cafeId': cafeId,
        'firstHourPrice': firstHourPrice,
        'entryFee': entryFee,
        'maxDeposit': maxDeposit,
        'defaultDeposit': defaultDeposit,
        'graceMinutes': graceMinutes,
        'currency': currency,
        'pricingModel': pricingModel,
      };

  DepositConfigEntity toEntity() => DepositConfigEntity(
        cafeId: cafeId,
        firstHourPrice: firstHourPrice,
        entryFee: entryFee,
        maxDeposit: maxDeposit,
        defaultDeposit: defaultDeposit,
        graceMinutes: graceMinutes,
        currency: currency,
        pricingModel: _pricingFromString(pricingModel),
      );

  static PricingModel _pricingFromString(String s) =>
      PricingModel.values.firstWhere(
        (e) => e.name == s,
        orElse: () => PricingModel.hourly,
      );
}