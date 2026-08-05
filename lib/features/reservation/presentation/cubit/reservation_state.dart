import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của reservation quote flow
sealed class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class ReservationInitial extends ReservationState {
  const ReservationInitial();
}

/// Loading quote
class ReservationQuoteLoading extends ReservationState {
  const ReservationQuoteLoading();
}

/// Quote loaded - hiển thị chi tiết cọc
class ReservationQuoteLoaded extends ReservationState {
  final ReservationQuoteEntity quote;

  const ReservationQuoteLoaded({required this.quote});

  @override
  List<Object?> get props => [quote];
}

/// Error loading quote
class ReservationQuoteError extends ReservationState {
  final String message;

  const ReservationQuoteError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Confirming reservation (atomic transaction)
class ReservationConfirming extends ReservationState {
  const ReservationConfirming();
}

/// Reservation confirmed thành công
class ReservationConfirmed extends ReservationState {
  final ReservationConfirmResult result;

  const ReservationConfirmed({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Error confirming reservation
class ReservationConfirmError extends ReservationState {
  final String message;

  const ReservationConfirmError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Insufficient balance for reservation
class ReservationInsufficientBalance extends ReservationState {
  final ReservationQuoteEntity quote;
  final int missingBvc;

  const ReservationInsufficientBalance({
    required this.quote,
    required this.missingBvc,
  });

  @override
  List<Object?> get props => [quote, missingBvc];
}

/// Cancelling reservation
class ReservationCancelling extends ReservationState {
  const ReservationCancelling();
}

/// Reservation cancelled
class ReservationCancelled extends ReservationState {
  final ReservationCancelResult result;

  const ReservationCancelled({required this.result});

  @override
  List<Object?> get props => [result];
}

/// Reservation cancelled error
class ReservationCancelError extends ReservationState {
  final String message;

  const ReservationCancelError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Quote hết hạn (user cần tạo lại quote trước khi confirm).
class ReservationQuoteExpired extends ReservationState {
  const ReservationQuoteExpired();
}

/// Reservation đang chờ cafe duyệt (sau khi confirm thành công nhưng
/// `requiresCafeApproval == true`).
class ReservationPendingCafeApproval extends ReservationState {
  final String reservationId;
  final String? lobbyId;
  final DateTime? cafeApprovalDeadline;

  const ReservationPendingCafeApproval({
    required this.reservationId,
    this.lobbyId,
    this.cafeApprovalDeadline,
  });

  @override
  List<Object?> get props => [reservationId, lobbyId, cafeApprovalDeadline];
}

/// Reservation bị cafe từ chối duyệt.
class ReservationRejectedByCafe extends ReservationState {
  final String reservationId;
  final String? reason;
  final int refundBvc;
  final String refundPolicyApplied;

  const ReservationRejectedByCafe({
    required this.reservationId,
    this.reason,
    required this.refundBvc,
    required this.refundPolicyApplied,
  });

  @override
  List<Object?> get props =>
      [reservationId, reason, refundBvc, refundPolicyApplied];
}
