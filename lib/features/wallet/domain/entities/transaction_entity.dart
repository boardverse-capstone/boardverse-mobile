import 'package:equatable/equatable.dart';

/// Loại giao dịch trong ledger (BR §3.2, §3.3)
enum TransactionType {
  topUp,
  depositHold,
  depositRelease,
  depositCapture,
  depositForfeit,
  adjustment,
  adminCredit,
  adminDebit;

  static TransactionType fromString(String value) {
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.topUp,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.topUp:
        return 'Nạp tiền';
      case TransactionType.depositHold:
        return 'Giữ cọc';
      case TransactionType.depositRelease:
        return 'Hoàn cọc';
      case TransactionType.depositCapture:
        return 'Thanh toán cọc';
      case TransactionType.depositForfeit:
        return 'Tịch thu cọc';
      case TransactionType.adjustment:
        return 'Điều chỉnh';
      case TransactionType.adminCredit:
        return 'Admin cộng';
      case TransactionType.adminDebit:
        return 'Admin trừ';
    }
  }

  bool get isPositive =>
      this == TransactionType.topUp ||
      this == TransactionType.depositRelease ||
      this == TransactionType.adminCredit;

  bool get isNegative =>
      this == TransactionType.depositHold ||
      this == TransactionType.depositCapture ||
      this == TransactionType.depositForfeit ||
      this == TransactionType.adminDebit;
}

/// Một dòng trong ledger (BR §3.3)
///
/// Ledger là append-only — không UPDATE/DELETE dòng đã ghi.
class TransactionEntity extends Equatable {
  final String id;

  /// Loại giao dịch
  final TransactionType type;

  /// Số BVC (luôn dương)
  final int amount;

  /// ID của lobby liên quan (nếu có)
  final String? relatedLobbyId;

  /// ID của booking/reservation liên quan (nếu có)
  final String? relatedBookingId;

  /// Mã tham chiếu thanh toán (vd: BVC-A1B2C3D4E5 cho top-up)
  final String? relatedPaymentRef;

  /// Số dư availableBalance sau giao dịch (snapshot để debug)
  final int balanceSnapshot;

  /// Ghi chú (thường dùng cho admin adjustment)
  final String? note;

  /// Thời điểm tạo giao dịch
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.type,
    required this.amount,
    this.relatedLobbyId,
    this.relatedBookingId,
    this.relatedPaymentRef,
    required this.balanceSnapshot,
    this.note,
    required this.createdAt,
  });

  /// Chuyển amount sang VND (1 BVC = 1.000 VND)
  int get amountVnd => amount * 1000;

  /// Mô tả ngắn cho UI
  String get shortDescription {
    switch (type) {
      case TransactionType.topUp:
        return 'Nạp $amount BVC';
      case TransactionType.depositHold:
        return 'Cọc lobby ($amount BVC)';
      case TransactionType.depositRelease:
        return 'Hoàn cọc $amount BVC';
      case TransactionType.depositCapture:
        return 'Thanh toán $amount BVC';
      case TransactionType.depositForfeit:
        return 'Tịch thu $amount BVC';
      case TransactionType.adjustment:
        return 'Điều chỉnh: $note';
      case TransactionType.adminCredit:
        return 'Admin cộng $amount BVC';
      case TransactionType.adminDebit:
        return 'Admin trừ $amount BVC';
    }
  }

  @override
  List<Object?> get props => [
        id,
        type,
        amount,
        relatedLobbyId,
        relatedBookingId,
        relatedPaymentRef,
        balanceSnapshot,
        note,
        createdAt,
      ];
}
