import 'package:equatable/equatable.dart';
import '../../domain/entities/deposit_entity.dart';
import '../../domain/entities/booking_qr_entity.dart';

sealed class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {
  const BookingInitial();
}

class BookingLoading extends BookingState {
  const BookingLoading();
}

class DepositPending extends BookingState {
  final DepositEntity deposit;
  final double userBalance;
  final Duration remainingTime;

  const DepositPending({
    required this.deposit,
    required this.userBalance,
    required this.remainingTime,
  });

  @override
  List<Object?> get props => [deposit, userBalance, remainingTime];
}

class DepositProcessing extends BookingState {
  const DepositProcessing();
}

class DepositSuccess extends BookingState {
  final DepositEntity deposit;

  const DepositSuccess({required this.deposit});

  @override
  List<Object?> get props => [deposit];
}

class BookingConfirmed extends BookingState {
  final BookingQrEntity booking;

  const BookingConfirmed({required this.booking});

  @override
  List<Object?> get props => [booking];
}

class DepositTimeout extends BookingState {
  final double? refundAmount;
  final int? karmaPenalty;

  const DepositTimeout({
    this.refundAmount,
    this.karmaPenalty,
  });

  @override
  List<Object?> get props => [refundAmount, karmaPenalty];
}

class BookingFailure extends BookingState {
  final String message;

  const BookingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
