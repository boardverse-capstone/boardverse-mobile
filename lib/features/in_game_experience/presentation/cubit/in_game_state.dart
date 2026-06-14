import 'package:equatable/equatable.dart';
import '../../domain/entities/in_game_session_entity.dart';

sealed class InGameState extends Equatable {
  const InGameState();

  @override
  List<Object?> get props => [];
}

class InGameInitial extends InGameState {
  const InGameInitial();
}

class InGameLoading extends InGameState {
  const InGameLoading();
}

class InGameSessionActive extends InGameState {
  final InGameSessionEntity session;
  final Duration currentDuration;

  const InGameSessionActive({
    required this.session,
    required this.currentDuration,
  });

  @override
  List<Object?> get props => [session, currentDuration];
}

class InGameCheckingInventory extends InGameState {
  final InGameSessionEntity session;

  const InGameCheckingInventory({required this.session});

  @override
  List<Object?> get props => [session];
}

class InGameCheckoutComplete extends InGameState {
  final double totalAmount;
  final double depositPaid;
  final double remainingAmount;

  const InGameCheckoutComplete({
    required this.totalAmount,
    required this.depositPaid,
    required this.remainingAmount,
  });

  @override
  List<Object?> get props => [totalAmount, depositPaid, remainingAmount];
}

class InGameFailure extends InGameState {
  final String message;

  const InGameFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
