import '../../domain/entities/entities.dart';

/// Data model cho TopUp API response
class TopUpQuoteModel extends TopUpQuoteEntity {
  const TopUpQuoteModel({
    required super.paymentUrl,
    required super.qrUrl,
    required super.orderId,
    required super.topUpId,
    required super.expectedBvc,
    required super.expiresAt,
    required super.idempotencyKey,
  });

  factory TopUpQuoteModel.fromJson(Map<String, dynamic> json) {
    return TopUpQuoteModel(
      paymentUrl: json['paymentUrl'] as String,
      qrUrl: json['qrUrl'] as String,
      orderId: json['orderId'] as String,
      // topUpId là Guid của BvcTopUpRequest — backend trả về để client có thể cancel.
      // Nếu backend chưa trả, fallback dùng orderId (sẽ fail ở DELETE nếu sai format).
      topUpId: json['topUpId'] as String? ?? json['orderId'] as String,
      expectedBvc: json['expectedBvc'] as int,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      idempotencyKey: json['idempotencyKey'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentUrl': paymentUrl,
      'qrUrl': qrUrl,
      'orderId': orderId,
      'topUpId': topUpId,
      'expectedBvc': expectedBvc,
      'expiresAt': expiresAt.toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }
}

/// Request model cho top-up
class TopUpRequestModel {
  final int amountVnd;
  final String idempotencyKey;

  const TopUpRequestModel({
    required this.amountVnd,
    required this.idempotencyKey,
  });

  factory TopUpRequestModel.fromJson(Map<String, dynamic> json) {
    return TopUpRequestModel(
      amountVnd: json['amountVnd'] as int,
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
