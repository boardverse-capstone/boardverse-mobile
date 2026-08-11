import 'package:equatable/equatable.dart';

/// Canonical PascalCase status name do backend trả về trong field `type`
/// của GET /api/v1/wallet/transactions (xem swagger `LedgerEntryType`).
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

/// Loại giao dịch trong ledger (BR §3.2, §3.3).
///
/// Mapping theo swagger `LedgerEntryType`:
///   TopUp           → nạp tiền thật → BVC
///   DepositHold     → giữ cọc reservation
///   DepositRelease  → hoàn cọc do timeout/hủy
///   DepositCapture  → capture cọc sau check-in
///   DepositForfeit  → tịch thu cọc do no-show
///   Adjustment      → sửa sai (chỉ admin)
///   AdminCredit     → admin cộng BVC thủ công
///   AdminDebit      → admin trừ BVC thủ công
enum TransactionType {
  topUp,
  depositHold,
  depositRelease,
  depositCapture,
  depositForfeit,
  adjustment,
  adminCredit,
  adminDebit;

  /// Map từ string backend → enum. Throw nếu gặp value lạ — UI sẽ hiển thị
  /// rõ ràng thay vì nuốt bug.
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

  /// Tên PascalCase chính xác mà backend serialize (swagger enum).
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
        return '�iều chỉnh';
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
///
/// `Adjustment` đặc biệt: dấu phụ thuộc vào `amount` (server chỉ ghi
/// entry kèm `isCredit` của admin, ledger `amount` luôn dương theo BR
/// §3.3 — tuy nhiên `TransactionType.adjustment` có thể xuất hiện với
/// amount âm khi backend chọn cách biểu diễn ±). UI dùng [amountSign]
/// để ra quyết định cuối cùng.
enum TransactionDirection { credit, debit }

/// Extension đính kèm helper cho UI.
///
/// `isPositive`/`isNegative` được GIỮ để tương thích ngược với code
/// cũ, nhưng UI mới nên dùng `direction` (kết hợp `type` + dấu `amount`
/// cho Adjustment).
extension TransactionTypeDirection on TransactionType {
  /// Hướng mặc định theo loại giao dịch. Với `Adjustment` phải xét
  /// thêm dấu của `amount` — dùng [directionFor] thay.
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

  /// True nếu mặc định là khoản cộng (giữ để tương thích ngược).
  bool get isPositive =>
      defaultDirection == TransactionDirection.credit;

  /// True nếu mặc định là khoản trừ (giữ để tương thích ngược).
  bool get isNegative =>
      defaultDirection == TransactionDirection.debit;
}

/// Một dòng trong ledger (BR §3.3).
///
/// Ledger là append-only — không UPDATE/DELETE dòng đã ghi.
class TransactionEntity extends Equatable {
  final String id;

  /// Loại giao dịch
  final TransactionType type;

  /// Số BVC. **Bình thường luôn dương** theo BR §3.3 — tuy nhiên với
  /// `Adjustment` có thể mang dấu âm để biểu diễn "trừ"; UI resolve
  /// chiều bằng `directionFor(amount)`.
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

  /// Chuyển amount sang VND (1 BVC = 1.000 VND).
  /// Trả về giá trị tuyệt đối để format — dấu đã nằm ở UI qua [direction].
  int get amountVndAbs => amount.abs() * 1000;

  /// Chiều ảnh hưởng lên ví hiển thị — UI lấy cái này để quyết định
  /// đ�/xanh và prefix `+`/`-`.
  TransactionDirection get direction => type.directionFor(amount);

  /// True nếu là khoản CỘNG (xanh, prefix `+`). False = khoản TRỪ
  /// (đỏ, prefix `-`).
  bool get isCredit => direction == TransactionDirection.credit;

  bool get isDebit => direction == TransactionDirection.debit;

  /// Mô tả ngắn cho UI
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
