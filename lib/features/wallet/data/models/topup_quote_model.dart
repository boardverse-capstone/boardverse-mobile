import '../../domain/entities/entities.dart';

/// Data model cho TopUp API response.
class TopUpQuoteModel extends TopUpQuoteEntity {
  const TopUpQuoteModel({
    required super.paymentUrl,
    required super.qrUrl,
    required super.qrImageBase64,
    required super.orderId,
    required super.topUpId,
    required super.expectedBvc,
    required super.expiresAt,
    required super.idempotencyKey,
  });

  factory TopUpQuoteModel.fromJson(Map<String, dynamic> json) {
    final orderId = (json['orderId'] as String?) ?? '';
    return TopUpQuoteModel(
      paymentUrl: (json['paymentUrl'] as String?) ?? '',
      qrUrl: (json['qrUrl'] as String?) ?? '',
      qrImageBase64: json['qrImageBase64'] as String?,
      orderId: orderId,
      // Fallback về `orderId` khi backend chưa trả Guid — backend có thể
      // từ chối nếu thực sự yêu cầu Guid.
      topUpId: (json['topUpId'] as String?) ?? (orderId.isEmpty ? null : orderId),
      expectedBvc: (json['expectedBvc'] as num?)?.toInt() ?? 0,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      idempotencyKey: (json['idempotencyKey'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentUrl': paymentUrl,
      'qrUrl': qrUrl,
      'qrImageBase64': qrImageBase64,
      'orderId': orderId,
      'topUpId': topUpId,
      'expectedBvc': expectedBvc,
      'expiresAt': expiresAt.toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }
}

/// Request model cho top-up.
class TopUpRequestModel {
  final int amountVnd;
  final String idempotencyKey;

  const TopUpRequestModel({
    required this.amountVnd,
    required this.idempotencyKey,
  });

  factory TopUpRequestModel.fromJson(Map<String, dynamic> json) {
    return TopUpRequestModel(
      amountVnd: (json['amountVnd'] as num?)?.toInt() ?? 0,
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amountVnd': amountVnd,
      'idempotencyKey': idempotencyKey,
    };
  }
}
