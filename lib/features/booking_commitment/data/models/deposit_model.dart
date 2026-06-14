import '../../domain/entities/deposit_entity.dart';

enum DepositStatusModel {
  pending,
  partiallyPaid,
  allPaid,
  expired,
  cancelled,
}

class DepositRecordModel {
  final String oduserId;
  final String userName;
  final String avatarUrl;
  final bool hasDeposited;
  final String? depositedAt;

  const DepositRecordModel({
    required this.oduserId,
    required this.userName,
    required this.avatarUrl,
    required this.hasDeposited,
    this.depositedAt,
  });

  factory DepositRecordModel.fromJson(Map<String, dynamic> json) {
    return DepositRecordModel(
      oduserId: json['oduserId'] as String,
      userName: json['userName'] as String,
      avatarUrl: json['avatarUrl'] as String,
      hasDeposited: json['hasDeposited'] as bool,
      depositedAt: json['depositedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'oduserId': oduserId,
      'userName': userName,
      'avatarUrl': avatarUrl,
      'hasDeposited': hasDeposited,
      'depositedAt': depositedAt,
    };
  }

  DepositRecord toEntity() => DepositRecord(
        oduserId: oduserId,
        userName: userName,
        avatarUrl: avatarUrl,
        hasDeposited: hasDeposited,
        depositedAt: depositedAt != null ? DateTime.parse(depositedAt!) : null,
      );
}

class DepositModel {
  final String id;
  final String lobbyId;
  final String bookingId;
  final double amount;
  final DepositStatusModel status;
  final DateTime deadline;
  final List<DepositRecordModel> records;

  const DepositModel({
    required this.id,
    required this.lobbyId,
    required this.bookingId,
    required this.amount,
    required this.status,
    required this.deadline,
    required this.records,
  });

  factory DepositModel.fromJson(Map<String, dynamic> json) {
    return DepositModel(
      id: json['id'] as String,
      lobbyId: json['lobbyId'] as String,
      bookingId: json['bookingId'] as String,
      amount: (json['amount'] as num).toDouble(),
      status: DepositStatusModel.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DepositStatusModel.pending,
      ),
      deadline: DateTime.parse(json['deadline'] as String),
      records: (json['records'] as List)
          .map((e) => DepositRecordModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lobbyId': lobbyId,
      'bookingId': bookingId,
      'amount': amount,
      'status': status.name,
      'deadline': deadline.toIso8601String(),
      'records': records.map((e) => e.toJson()).toList(),
    };
  }

  int get paidCount => records.where((r) => r.hasDeposited).length;
  int get totalCount => records.length;
  double get userBalance => 150000;

  DepositEntity toEntity() => DepositEntity(
        id: id,
        lobbyId: lobbyId,
        bookingId: bookingId,
        amount: amount,
        status: _statusToEntity(status),
        deadline: deadline,
        records: records.map((r) => r.toEntity()).toList(),
      );

  static DepositStatus _statusToEntity(DepositStatusModel status) {
    switch (status) {
      case DepositStatusModel.pending:
        return DepositStatus.pending;
      case DepositStatusModel.partiallyPaid:
        return DepositStatus.partiallyPaid;
      case DepositStatusModel.allPaid:
        return DepositStatus.allPaid;
      case DepositStatusModel.expired:
        return DepositStatus.expired;
      case DepositStatusModel.cancelled:
        return DepositStatus.cancelled;
    }
  }
}
