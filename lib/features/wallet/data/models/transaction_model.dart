import '../../domain/entities/entities.dart';

/// Data model cho Transaction API response
class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.type,
    required super.amount,
    super.relatedLobbyId,
    super.relatedBookingId,
    super.relatedPaymentRef,
    required super.balanceSnapshot,
    super.note,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.fromString(json['type'] as String? ?? 'TopUp'),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      relatedLobbyId: json['relatedLobbyId'] as String?,
      relatedBookingId: json['relatedBookingId'] as String?,
      relatedPaymentRef: json['relatedPaymentRef'] as String?,
      balanceSnapshot: (json['balanceSnapshot'] as num?)?.toInt() ?? 0,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.wireName,
      'amount': amount,
      'relatedLobbyId': relatedLobbyId,
      'relatedBookingId': relatedBookingId,
      'relatedPaymentRef': relatedPaymentRef,
      'balanceSnapshot': balanceSnapshot,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

/// Paged response cho transactions list
class TransactionListModel {
  final List<TransactionModel> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final bool hasMore;

  const TransactionListModel({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.hasMore,
  });

  factory TransactionListModel.fromJson(Map<String, dynamic> json) {
    return TransactionListModel(
      items: (json['items'] as List<dynamic>)
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (json['page'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      hasMore: json['hasMore'] as bool,
    );
  }
}
