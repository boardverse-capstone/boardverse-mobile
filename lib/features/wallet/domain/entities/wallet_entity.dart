import 'package:equatable/equatable.dart';

/// Trạng thái tài khoản của user (BR-RISK-04)
enum AccountStatus {
  active,
  warning,
  restricted,
  suspended,
  banned;

  static AccountStatus fromString(String value) {
    return AccountStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AccountStatus.active,
    );
  }
}

/// Mức rủi ro của user (BR-RISK-09)
enum RiskLevel {
  low,
  medium,
  high,
  critical;

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}

/// Ví BVC của user (BR §2, §3)
///
/// - `availableBalance`: BVC có thể dùng để đặt cọc
/// - `heldBalance`: BVC đang bị giữ cho reservation/lobby
///
/// 1 BVC = 1.000 VND (cố định, BR §2.2)
class WalletEntity extends Equatable {
  final String userId;

  /// Số BVC có thể dùng (đã trừ các khoản đang hold)
  final int availableBalance;

  /// Số BVC đang bị giữ cho reservation/lobby
  final int heldBalance;

  /// Mức rủi ro (low/medium/high/critical) — user chỉ thấy enum, không thấy score (BR-RISK-09)
  final RiskLevel riskLevel;

  /// User có đang trong cooling-off period không (BR-NEW-10)
  final bool isCoolingOff;

  /// Trạng thái tài khoản (BR-RISK-04)
  final AccountStatus accountStatus;

  const WalletEntity({
    required this.userId,
    required this.availableBalance,
    required this.heldBalance,
    required this.riskLevel,
    required this.isCoolingOff,
    required this.accountStatus,
  });

  /// Tổng số dư (available + held)
  int get totalBalance => availableBalance + heldBalance;

  /// Chuyển đổi sang VND (1 BVC = 1.000 VND)
  int get availableBalanceVnd => availableBalance * 1000;
  int get heldBalanceVnd => heldBalance * 1000;
  int get totalBalanceVnd => totalBalance * 1000;

  /// Kiểm tra user có thể thực hiện top-up không
  bool get canTopUp =>
      accountStatus != AccountStatus.suspended &&
      accountStatus != AccountStatus.banned;

  /// Kiểm tra user có thể tạo lobby không
  bool get canCreateLobby =>
      accountStatus == AccountStatus.active ||
      accountStatus == AccountStatus.warning;

  /// Kiểm tra user có thể tham gia lobby không
  bool get canJoinLobby =>
      accountStatus != AccountStatus.suspended &&
      accountStatus != AccountStatus.banned;

  @override
  List<Object?> get props => [
        userId,
        availableBalance,
        heldBalance,
        riskLevel,
        isCoolingOff,
        accountStatus,
      ];
}
