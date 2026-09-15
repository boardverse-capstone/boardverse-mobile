import '../../domain/entities/entities.dart';

/// Data model cho Wallet API response.
class WalletModel extends WalletEntity {
  const WalletModel({
    required super.userId,
    required super.availableBalance,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      userId: (json['userId'] as String?) ?? '',
      availableBalance: (json['availableBalance'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'availableBalance': availableBalance,
    };
  }
}
