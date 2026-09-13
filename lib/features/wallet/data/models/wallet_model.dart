import '../../domain/entities/entities.dart';

/// Data model cho Wallet API response
class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    required super.availableBalance,
    required super.heldBalance,
    required super.riskMultiplier,
    required super.riskLevel,
    required super.isCoolingOff,
    required super.accountStatus,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: json['userId'] as String,
      availableBalance: (json['availableBalance'] as num?)?.toInt() ?? 0,
      heldBalance: (json['heldBalance'] as num?)?.toInt() ?? 0,
      riskMultiplier:
          (json['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      riskLevel: RiskLevel.fromString(json['riskLevel'] as String? ?? 'low'),
      isCoolingOff: json['isCoolingOff'] as bool? ?? false,
      accountStatus:
          AccountStatus.fromString(json['accountStatus'] as String? ?? 'active'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'availableBalance': availableBalance,
      'heldBalance': heldBalance,
      'riskMultiplier': riskMultiplier,
      'riskLevel': riskLevel.name,
      'isCoolingOff': isCoolingOff,
      'accountStatus': accountStatus.name,
    };
  }
}
