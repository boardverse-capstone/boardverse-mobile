import '../../domain/entities/session_payment_entity.dart';

/// Model for POST /api/v1/sessions/me/pay request and response
class PaySessionRequestModel {
  final String sessionId;

  const PaySessionRequestModel({
    required this.sessionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
    };
  }
}

/// Response model for pay session
class PaySessionResponseModel {
  final bool success;
  final String message;
  final InvoiceModel invoice;
  final int bvcDeducted;
  final int remainingBvcBalance;
  final String paymentMethod;

  const PaySessionResponseModel({
    required this.success,
    required this.message,
    required this.invoice,
    required this.bvcDeducted,
    required this.remainingBvcBalance,
    required this.paymentMethod,
  });

  factory PaySessionResponseModel.fromJson(Map<String, dynamic> json) {
    return PaySessionResponseModel(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      invoice:
          InvoiceModel.fromJson(json['invoice'] as Map<String, dynamic>),
      bvcDeducted: (json['bvcDeducted'] as num?)?.toInt() ?? 0,
      remainingBvcBalance: (json['remainingBvcBalance'] as num?)?.toInt() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'BVC',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'invoice': invoice.toJson(),
      'bvcDeducted': bvcDeducted,
      'remainingBvcBalance': remainingBvcBalance,
      'paymentMethod': paymentMethod,
    };
  }

  SessionPaymentResultEntity toEntity() => SessionPaymentResultEntity(
        success: success,
        message: message,
        invoice: invoice.toEntity(),
        bvcDeducted: bvcDeducted,
        remainingBvcBalance: remainingBvcBalance,
        paymentMethod: paymentMethod,
      );
}

/// Invoice model
class InvoiceModel {
  final String sessionId;
  final int totalMinutes;
  final int subtotal;
  final int penaltyAmount;
  final int depositApplied;
  final int totalDue;
  final String currency;
  final List<InvoiceLineItemModel> lineItems;

  const InvoiceModel({
    required this.sessionId,
    required this.totalMinutes,
    required this.subtotal,
    required this.penaltyAmount,
    required this.depositApplied,
    required this.totalDue,
    required this.currency,
    required this.lineItems,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      sessionId: json['sessionId'] as String,
      totalMinutes: (json['totalMinutes'] as num?)?.toInt() ?? 0,
      subtotal: (json['subtotal'] as num?)?.toInt() ?? 0,
      penaltyAmount: (json['penaltyAmount'] as num?)?.toInt() ?? 0,
      depositApplied: (json['depositApplied'] as num?)?.toInt() ?? 0,
      totalDue: (json['totalDue'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'VND',
      lineItems: (json['lineItems'] as List?)
              ?.map((e) => InvoiceLineItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'totalMinutes': totalMinutes,
      'subtotal': subtotal,
      'penaltyAmount': penaltyAmount,
      'depositApplied': depositApplied,
      'totalDue': totalDue,
      'currency': currency,
      'lineItems': lineItems.map((e) => e.toJson()).toList(),
    };
  }

  InvoiceEntity toEntity() => InvoiceEntity(
        sessionId: sessionId,
        totalMinutes: totalMinutes,
        subtotal: subtotal,
        penaltyAmount: penaltyAmount,
        depositApplied: depositApplied,
        totalDue: totalDue,
        currency: currency,
        lineItems: lineItems.map((e) => e.toEntity()).toList(),
      );
}

/// Invoice line item model
class InvoiceLineItemModel {
  final String type;
  final String description;
  final int minutes;
  final int ratePerMinute;
  final int amount;

  const InvoiceLineItemModel({
    required this.type,
    required this.description,
    required this.minutes,
    required this.ratePerMinute,
    required this.amount,
  });

  factory InvoiceLineItemModel.fromJson(Map<String, dynamic> json) {
    return InvoiceLineItemModel(
      type: json['type'] as String? ?? '',
      description: json['description'] as String? ?? '',
      minutes: (json['minutes'] as num?)?.toInt() ?? 0,
      ratePerMinute: (json['ratePerMinute'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'description': description,
      'minutes': minutes,
      'ratePerMinute': ratePerMinute,
      'amount': amount,
    };
  }

  InvoiceLineItemEntity toEntity() => InvoiceLineItemEntity(
        type: type,
        description: description,
        minutes: minutes,
        ratePerMinute: ratePerMinute,
        amount: amount,
      );
}
