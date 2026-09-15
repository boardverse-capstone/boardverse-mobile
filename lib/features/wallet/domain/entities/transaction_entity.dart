import 'package:equatable/equatable.dart';

/// Tên PascalCase do backend trả về trong field `type` của
/// GET /api/v1/wallet/transactions.
///
/// Dùng để map qua lại giữa Dart enum ↔ JSON một cách an toàn — tránh
/// hard-code string rải rác ở UI / datasource.
abstract final class TransactionTypeNames {
  static const String topUp = 'TopUp';
  static const String depositHold = 'DepositHold';
  static const String depositRelease = 'DepositRelease';
  static const String depositCapture = 'DepositCapture';
  static const String depositForfeit = 'DepositForfeit';
  static const String adjustment = 'Adjustment';
  static const String adminCredit = 'AdminCredit';
  static const String adminDebit = 'AdminDebit';
}

/// Loại giao dịch trong ledger.
enum TransactionType {
  topUp,
  depositHold,
  depositRelease,
  depositCapture,
  depositForfeit,
  adjustment,
  adminCredit,
  adminDebit;

  /// Map từ string backend → enum. Throw nếu gặp value lạ.
  static TransactionType fromString(String value) {
    final normalized = value.trim();
    for (final t in TransactionType.values) {
      if (t.wireName == normalized) return t;
    }
    throw FormatException(
      'Unsupported ledger type from backend: "$value". '
      'Expected one of: ${TransactionType.values.map((e) => e.wireName).join(', ')}',
    );
  }

  /// Tên PascalCase chính xác mà backend serialize.
  String get wireName {
    switch (this) {
      case TransactionType.topUp:
        return TransactionTypeNames.topUp;
      case TransactionType.depositHold:
        return TransactionTypeNames.depositHold;
      case TransactionType.depositRelease:
        return TransactionTypeNames.depositRelease;
      case TransactionType.depositCapture:
        return TransactionTypeNames.depositCapture;
      case TransactionType.depositForfeit:
        return TransactionTypeNames.depositForfeit;
      case TransactionType.adjustment:
        return TransactionTypeNames.adjustment;
      case TransactionType.adminCredit:
        return TransactionTypeNames.adminCredit;
      case TransactionType.adminDebit:
        return TransactionTypeNames.adminDebit;
    }
  }

  /// Tên hiển thị tiếng Việt.
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
}

/// Chiều ảnh hưởng lên `availableBalance`:
///   - [credit]: cộng vào ví (TopUp, DepositRelease, AdminCredit, Adjustment dương)
///   - [debit] : trừ khỏi ví hiển thị (DepositHold, DepositCapture,
///               DepositForfeit, AdminDebit, Adjustment âm)
enum TransactionDirection { credit, debit }

/// Extension helper cho UI.
extension TransactionTypeDirection on TransactionType {
  /// Hướng mặc định theo loại giao dịch. Với `Adjustment` phải xét thêm
  /// dấu của `amount` — dùng [directionFor] thay.
  TransactionDirection get defaultDirection {
    switch (this) {
      case TransactionType.topUp:
      case TransactionType.depositRelease:
      case TransactionType.adminCredit:
        return TransactionDirection.credit;

      case TransactionType.depositHold:
      case TransactionType.depositCapture:
      case TransactionType.depositForfeit:
      case TransactionType.adminDebit:
        return TransactionDirection.debit;

      case TransactionType.adjustment:
        // Mặc định conservative — UI nên resolve qua `directionFor(amount)`.
        return TransactionDirection.credit;
    }
  }

  /// Hướng thực tế: với `Adjustment` thì đảo theo dấu amount.
  TransactionDirection directionFor(int amount) {
    if (this == TransactionType.adjustment) {
      return amount >= 0
          ? TransactionDirection.credit
          : TransactionDirection.debit;
    }
    return defaultDirection;
  }
}

/// Một dòng trong ledger (append-only).
class TransactionEntity extends Equatable {
  final String id;

  /// Loại giao dịch.
  final TransactionType type;

  /// Số BVC. Với `Adjustment` có thể âm để biểu diễn "trừ".
  final int amount;

  /// ID của lobby liên quan (nếu có).
  final String? relatedLobbyId;

  /// ID của booking/reservation liên quan (nếu có).
  final String? relatedBookingId;

  /// Mã tham chiếu thanh toán (vd: BVC-A1B2C3D4E5 cho top-up).
  final String? relatedPaymentRef;

  /// Số dư availableBalance sau giao dịch (snapshot).
  final int balanceSnapshot;

  /// Ghi chú (thường dùng cho admin adjustment).
  final String? note;

  /// Thời điểm tạo giao dịch.
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

  /// Quy đổi amount sang VND (1 BVC = 1.000 VND).
  /// Trả về giá trị tuyệt đối — dấu đã nằm ở UI qua [direction].
  int get amountVndAbs => amount.abs() * 1000;

  /// Chiều ảnh hưởng lên ví hiển thị.
  TransactionDirection get direction => type.directionFor(amount);

  /// True nếu là khoản CỘNG.
  bool get isCredit => direction == TransactionDirection.credit;

  /// True nếu là khoản TRỪ.
  bool get isDebit => direction == TransactionDirection.debit;

  /// Mô tả ngắn cho UI.
  String get shortDescription {
    switch (type) {
      case TransactionType.topUp:
        return 'Nạp ${amount.abs()} BVC';
      case TransactionType.depositHold:
        return 'Cọc lobby (${amount.abs()} BVC)';
      case TransactionType.depositRelease:
        return 'Hoàn cọc ${amount.abs()} BVC';
      case TransactionType.depositCapture:
        return 'Thanh toán ${amount.abs()} BVC';
      case TransactionType.depositForfeit:
        return 'Tịch thu ${amount.abs()} BVC';
      case TransactionType.adjustment:
        return 'Điều chỉnh: ${note ?? ''}'.trim();
      case TransactionType.adminCredit:
        return 'Admin cộng ${amount.abs()} BVC';
      case TransactionType.adminDebit:
        return 'Admin trừ ${amount.abs()} BVC';
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
