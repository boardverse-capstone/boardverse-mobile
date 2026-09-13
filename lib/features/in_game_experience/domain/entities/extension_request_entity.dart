import '../../data/models/extend_session_model.dart';

export '../../data/models/extend_session_model.dart';

/// Extension request entity
class ExtensionRequestEntity {
  final String requestId;
  final String sessionId;
  final int requestedMinutes;
  final int estimatedAdditionalCostVnd;
  final ExtensionStatus status;
  final bool success;
  final String? message;
  final DateTime? newEndTime;
  final int totalMinutesBooked;

  const ExtensionRequestEntity({
    required this.requestId,
    required this.sessionId,
    required this.requestedMinutes,
    required this.estimatedAdditionalCostVnd,
    required this.status,
    required this.success,
    this.message,
    this.newEndTime,
    required this.totalMinutesBooked,
  });

  /// Format estimated cost as BVC
  String get formattedEstimatedCost {
    return '${(estimatedAdditionalCostVnd / 1000).toStringAsFixed(0)} BVC';
  }

  /// Check if request is pending
  bool get isPending => status == ExtensionStatus.pending;

  /// Check if request was approved
  bool get isApproved => status == ExtensionStatus.approved;

  /// Check if request was rejected
  bool get isRejected => status == ExtensionStatus.rejected;

  ExtensionRequestEntity copyWith({
    String? requestId,
    String? sessionId,
    int? requestedMinutes,
    int? estimatedAdditionalCostVnd,
    ExtensionStatus? status,
    bool? success,
    String? message,
    DateTime? newEndTime,
    int? totalMinutesBooked,
  }) {
    return ExtensionRequestEntity(
      requestId: requestId ?? this.requestId,
      sessionId: sessionId ?? this.sessionId,
      requestedMinutes: requestedMinutes ?? this.requestedMinutes,
      estimatedAdditionalCostVnd:
          estimatedAdditionalCostVnd ?? this.estimatedAdditionalCostVnd,
      status: status ?? this.status,
      success: success ?? this.success,
      message: message ?? this.message,
      newEndTime: newEndTime ?? this.newEndTime,
      totalMinutesBooked: totalMinutesBooked ?? this.totalMinutesBooked,
    );
  }
}

/// Last extension request entity
class LastExtensionRequestEntity {
  final String requestId;
  final int requestedMinutes;
  final int? approvedMinutes;
  final int estimatedAdditionalCostVnd;
  final ExtensionStatus status;
  final String? rejectionReason;
  final DateTime requestedAt;
  final DateTime? requestedAtUtc;
  final DateTime? processedAt;
  final DateTime? processedAtOffset;

  const LastExtensionRequestEntity({
    required this.requestId,
    required this.requestedMinutes,
    this.approvedMinutes,
    required this.estimatedAdditionalCostVnd,
    required this.status,
    this.rejectionReason,
    required this.requestedAt,
    this.requestedAtUtc,
    this.processedAt,
    this.processedAtOffset,
  });

  /// Format estimated cost as BVC
  String get formattedEstimatedCost {
    return '${(estimatedAdditionalCostVnd / 1000).toStringAsFixed(0)} BVC';
  }

  /// Check if request is pending
  bool get isPending => status == ExtensionStatus.pending;

  /// Check if request was approved
  bool get isApproved => status == ExtensionStatus.approved;

  /// Check if request was rejected
  bool get isRejected => status == ExtensionStatus.rejected;

  /// Get display status text
  String get statusText {
    switch (status) {
      case ExtensionStatus.pending:
        return 'Đang chờ duyệt';
      case ExtensionStatus.approved:
        return 'Đã duyệt';
      case ExtensionStatus.rejected:
        return 'Từ chối';
      case ExtensionStatus.expired:
        return 'Hết hạn';
    }
  }

  LastExtensionRequestEntity copyWith({
    String? requestId,
    int? requestedMinutes,
    int? approvedMinutes,
    int? estimatedAdditionalCostVnd,
    ExtensionStatus? status,
    String? rejectionReason,
    DateTime? requestedAt,
    DateTime? requestedAtUtc,
    DateTime? processedAt,
    DateTime? processedAtOffset,
  }) {
    return LastExtensionRequestEntity(
      requestId: requestId ?? this.requestId,
      requestedMinutes: requestedMinutes ?? this.requestedMinutes,
      approvedMinutes: approvedMinutes ?? this.approvedMinutes,
      estimatedAdditionalCostVnd:
          estimatedAdditionalCostVnd ?? this.estimatedAdditionalCostVnd,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      requestedAt: requestedAt ?? this.requestedAt,
      requestedAtUtc: requestedAtUtc ?? this.requestedAtUtc,
      processedAt: processedAt ?? this.processedAt,
      processedAtOffset: processedAtOffset ?? this.processedAtOffset,
    );
  }
}
