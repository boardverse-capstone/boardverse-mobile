import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của wallet cubit.
sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Trạng thái khởi đầu.
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Đang tải dữ liệu ví.
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Đã tải ví thành công.
class WalletLoaded extends WalletState {
  final WalletEntity wallet;

  const WalletLoaded({required this.wallet});

  @override
  List<Object?> get props => [wallet];
}

/// Lỗi tải ví.
class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}
