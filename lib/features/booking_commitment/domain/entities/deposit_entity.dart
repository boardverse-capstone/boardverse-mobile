import 'package:equatable/equatable.dart';

class DepositEntity extends Equatable {
  final String id;
  final String lobbyId;
  final String bookingId;
  final double amount;
  final DepositStatus status;
  final DateTime deadline;
  final List<DepositRecord> records;

  const DepositEntity({
    required this.id,
    required this.lobbyId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.deadline,
    required this.records,
  });

  @override
  List<Object?> get props => [id, lobbyId, bookingId, amount, status, deadline, records];
}

class DepositRecord extends Equatable {
  final String oduserId;
  final String userName;
  final String avatarUrl;
  final bool hasDeposited;
  final DateTime? depositedAt;

  const DepositRecord({
    required this.oduserId,
    required this.userName,
    required this.avatarUrl,
    required this.hasDeposited,
    this.depositedAt,
  });

  @override
  List<Object?> get props => [oduserId, userName, avatarUrl, hasDeposited, depositedAt];
}

enum DepositStatus {
  pending,
  partiallyPaid,
  allPaid,
  expired,
  cancelled,
}
