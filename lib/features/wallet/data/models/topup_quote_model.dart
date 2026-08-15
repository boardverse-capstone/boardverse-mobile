import '../../domain/entities/entities.dart';

/// Data model cho TopUp API response
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
    // ⚠️ Backend phiên bản hiện tại CHƯA trả field `topUpId` (Guid) trong
    // `TopUpResponseDto` — chỉ trả `orderId` (vd "1983EBFA5333CF7F42").
    //
    // Xử lý:
    // - Nếu backend có trả `topUpId` (Guid) → dùng nó cho DELETE/PATCH.
    // - Nếu backend CHƯA trả → fallback dùng `orderId`. Backend nhận cả
    //   orderId trong path param `topUpId` (Swagger ghi "uuid" nhưng thực
    //   tế backend .NET parse string nên chấp nhận mọi định dạng). Nếu
    //   backend thực sự yêu cầu Guid → PATCH/DELETE sẽ 404, lúc đó UI
    //   sẽ disable buttons nhờ heuristic `hasTopUpId` bên dưới.
    final rawTopUpId = json['topUpId'] as String?;
    final orderId = (json['orderId'] as String?) ?? '';
    if (rawTopUpId == null && orderId.isNotEmpty) {
      // ignore: avoid_print
      print(
        '[TopUpQuoteModel] ⚠️ Backend response THIẾU field `topUpId`. '
        'Fallback dùng `orderId` cho PATCH/DELETE. Nội dung response: $json',
      );
    }

    // `paymentUrl` / `qrUrl` nullable trong Swagger — backend có thể
    // trả null khi tạo đơn thất bại một phần. Coerce sang empty string
    // để entity vẫn khởi tạo được; UI sẽ dùng fallback chain.
    return TopUpQuoteModel(
      paymentUrl: (json['paymentUrl'] as String?) ?? '',
      qrUrl: (json['qrUrl'] as String?) ?? '',
      qrImageBase64: json['qrImageBase64'] as String?,
      orderId: orderId,
      // Fallback: nếu backend chưa trả topUpId → dùng orderId. Nếu backend
      // nhận Guid strict → PATCH/DELETE sẽ 404, UI sẽ disable qua heuristic.
      topUpId: rawTopUpId ?? (orderId.isEmpty ? null : orderId),
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
