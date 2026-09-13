/// Model for POST /api/v1/sessions/me/extend request and response
class ExtendSessionRequestModel {
  final int extensionMinutes;

  const ExtendSessionRequestModel({
    required this.extensionMinutes,
  });

  Map<String, dynamic> toJson() {
    return {
      'extensionMinutes': extensionMinutes,
    };
  }
}

/// Response model for extend session
class ExtendSessionResponseModel {
  final String requestId;
  final String sessionId;
  final int requestedMinutes;
  final int estimatedAdditionalCostVnd;
  final ExtensionStatus status;
  final bool success;
  final String? message;
  final DateTime? newEndTime;
  final int totalMinutesBooked;
  final int estimatedAdditionalCost;

  const ExtendSessionResponseModel({
    required this.requestId,
    required this.sessionId,
    required this.requestedMinutes,
    required this.estimatedAdditionalCostVnd,
    required this.status,
    required this.success,
    this.message,
    this.newEndTime,
    required this.totalMinutesBooked,
    required this.estimatedAdditionalCost,
  });

  factory ExtendSessionResponseModel.fromJson(Map<String, dynamic> json) {
    return ExtendSessionResponseModel(
      requestId: json['requestId'] as String,
      sessionId: json['sessionId'] as String,
      requestedMinutes: (json['requestedMinutes'] as num?)?.toInt() ?? 0,
      estimatedAdditionalCostVnd: (json['estimatedAdditionalCostVnd'] as num?)?.toInt() ?? 0,
      status: ExtensionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ExtensionStatus.pending,
      ),
      success: json['success'] as bool? ?? true,
      message: json['message'] as String?,
      newEndTime: json['newEndTime'] != null
          ? DateTime.parse(json['newEndTime'] as String)
          : null,
      totalMinutesBooked: (json['totalMinutesBooked'] as num?)?.toInt() ?? 0,
      estimatedAdditionalCost: (json['estimatedAdditionalCost'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'sessionId': sessionId,
      'requestedMinutes': requestedMinutes,
      'estimatedAdditionalCostVnd': estimatedAdditionalCostVnd,
      'status': status.name,
      'success': success,
      'message': message,
      'newEndTime': newEndTime?.toIso8601String(),
      'totalMinutesBooked': totalMinutesBooked,
      'estimatedAdditionalCost': estimatedAdditionalCost,
    };
  }
}

/// Extension status enum
enum ExtensionStatus { pending, approved, rejected, expired }
