import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của top-up flow.
sealed class TopUpState extends Equatable {
  const TopUpState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi đầu — user chưa bắt đầu nạp.
class TopUpInitial extends TopUpState {
  const TopUpInitial();
}

/// Đang gọi API tạo đơn nạp.
class TopUpCreating extends TopUpState {
  const TopUpCreating();
}

/// Đã tạo đơn, đang chờ user thanh toán.
class TopUpAwaitingPayment extends TopUpState {
  final TopUpQuoteEntity quote;
  final DateTime deadline;

  const TopUpAwaitingPayment({
    required this.quote,
    required this.deadline,
  });

  @override
  List<Object?> get props => [quote, deadline];
}

/// Đang kiểm tra trạng thái (polling).
class TopUpCheckingStatus extends TopUpState {
  const TopUpCheckingStatus();
}

/// Đang gọi API hủy đơn.
class TopUpCancelling extends TopUpState {
  const TopUpCancelling();
}

/// Nạp thành công.
class TopUpSuccess extends TopUpState {
  final int amountBvc;
  final int newBalance;

  const TopUpSuccess({
    required this.amountBvc,
    required this.newBalance,
  });

  @override
  List<Object?> get props => [amountBvc, newBalance];
}

/// Nạp thất bại.
class TopUpFailed extends TopUpState {
  final String reason;

  const TopUpFailed({required this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Đơn nạp đã hết hạn.
class TopUpExpired extends TopUpState {
  const TopUpExpired();
}

/// Đơn nạp đã bị user hủy thành công.
class TopUpCancelled extends TopUpState {
  const TopUpCancelled();
}

/// Các gói nạp gợi ý.
class TopUpPackages {
  static const List<int> suggestedAmountsVnd = [
    20000, // 20 BVC
    50000, // 50 BVC
    100000, // 100 BVC
    200000, // 200 BVC
    500000, // 500 BVC
  ];

  /// Quy đổi VND → BVC (1 BVC = 1.000 VND).
  static int vndToBvc(int amountVnd) => amountVnd ~/ 1000;

  /// Danh sách gói nạp cho UI.
  static List<TopUpPackageItem> get suggestedPackages {
    return suggestedAmountsVnd.map((vnd) {
      return TopUpPackageItem(
        amountVnd: vnd,
        amountBvc: vndToBvc(vnd),
        label: _formatVnd(vnd),
      );
    }).toList();
  }

  static String _formatVnd(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}

class TopUpPackageItem {
  final int amountVnd;
  final int amountBvc;
  final String label;

  const TopUpPackageItem({
    required this.amountVnd,
    required this.amountBvc,
    required this.label,
  });
}
