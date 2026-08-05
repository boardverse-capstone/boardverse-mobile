import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của top-up flow
sealed class TopUpState extends Equatable {
  const TopUpState();

  @override
  List<Object?> get props => [];
}

/// Initial state - user chưa bắt đầu top-up
class TopUpInitial extends TopUpState {
  const TopUpInitial();
}

/// Đang gọi API tạo top-up
class TopUpCreating extends TopUpState {
  const TopUpCreating();
}

/// Đã tạo top-up, đang chờ user thanh toán
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

/// Đang kiểm tra trạng thái top-up (polling)
class TopUpCheckingStatus extends TopUpState {
  const TopUpCheckingStatus();
}

/// Đang gọi API hủy top-up
class TopUpCancelling extends TopUpState {
  const TopUpCancelling();
}

/// Top-up thành công
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

/// Top-up thất bại
class TopUpFailed extends TopUpState {
  final String reason;

  const TopUpFailed({required this.reason});

  @override
  List<Object?> get props => [reason];
}

/// Top-up hết hạn (timeout)
class TopUpExpired extends TopUpState {
  const TopUpExpired();
}

/// Top-up đã bị user hủy thành công
class TopUpCancelled extends TopUpState {
  const TopUpCancelled();
}

/// Các gói top-up được đề xuất (BR §2.5)
class TopUpPackages {
  static const List<int> suggestedAmountsVnd = [
    20000, // 20 BVC
    50000, // 50 BVC
    100000, // 100 BVC
    200000, // 200 BVC
    500000, // 500 BVC
  ];

  /// Số BVC tương ứng với mỗi gói
  static int vndToBvc(int amountVnd) => amountVnd ~/ 1000;

  /// Tạo danh sách gói top-up cho UI
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
