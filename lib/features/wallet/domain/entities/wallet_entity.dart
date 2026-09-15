import 'package:equatable/equatable.dart';

/// Ví BVC của user.
///
/// Tối giản cho UX: chỉ giữ số dư khả dụng. Các chi tiết nghiệp vụ
/// (held, risk, cooling-off, trạng thái tài khoản) được tính toán ở
/// backend và không hiển thị trong màn hình ví.
///
/// Tỷ lệ quy đổi: 1 BVC = 1.000 VND.
class WalletEntity extends Equatable {
  final String userId;

  /// Số BVC khả dụng (đã trừ các khoản đang giữ).
  final int availableBalance;

  const WalletEntity({
    required this.userId,
    required this.availableBalance,
  });

  /// Quy đổi sang VND (1 BVC = 1.000 VND).
  int get availableBalanceVnd => availableBalance * 1000;

  @override
  List<Object?> get props => [userId, availableBalance];
}
