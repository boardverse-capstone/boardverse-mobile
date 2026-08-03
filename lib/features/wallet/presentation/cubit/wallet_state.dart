import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của wallet cubit
sealed class WalletState extends Equatable {
  const WalletState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class WalletInitial extends WalletState {
  const WalletInitial();
}

/// Loading wallet data
class WalletLoading extends WalletState {
  const WalletLoading();
}

/// Wallet loaded successfully
class WalletLoaded extends WalletState {
  final WalletEntity wallet;

  const WalletLoaded({required this.wallet});

  @override
  List<Object?> get props => [wallet];
}

/// Error loading wallet
class WalletError extends WalletState {
  final String message;

  const WalletError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Wallet balance insufficient for operation
class WalletInsufficientBalance extends WalletState {
  final WalletEntity wallet;
  final int required;
  final int missing;

  const WalletInsufficientBalance({
    required this.wallet,
    required this.required,
    required this.missing,
  });

  @override
  List<Object?> get props => [wallet, required, missing];
}
