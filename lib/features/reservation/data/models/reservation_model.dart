import '../../domain/entities/entities.dart';

/// Data model cho Reservation API response.
///
/// Parse đúng các field từ backend theo API response thực tế.
class ReservationModel extends ReservationEntity {
  const ReservationModel({
    required super.id,
    required super.hostId,
    super.hostDisplayName,
    required super.cafeId,
    required super.cafeName,
    super.cafeAddress,
    required super.gameId,
    required super.gameName,
    required super.playDate,
    required super.timeSlot,
    super.preferredStartTime,
    required super.scheduledTime,
    super.scheduledEndTime,
    super.recruitmentDeadline,
    required super.minPlayers,
    required super.maxPlayers,
    super.depositRatePerPerson,
    super.baseDeposit,
    required super.riskMultiplier,
    super.minDepositApplied,
    required super.finalDeposit,
    required super.status,
    required super.currentPlayers,
    super.lobbyId,
    super.lobbyShareCode,
    super.lobbyStatus,
    super.isPrivate,
    required super.requiresCafeApproval,
    super.cafeApprovalDeadline,
    super.cafeRejectionReason,
    super.refundPolicyApplied,
    required super.createdAt,
    super.updatedAt,
    super.isHost,
    super.canCancel,
    super.checkedInAt,
    super.actualEndAt,
    super.playedRatio,
    super.endReason,
    super.tableNumber,
    super.cancelledBy,
    super.cancelReason,
    super.remainingApprovalHours,
    super.remainingApprovalMinutes,
    super.isCafeApproved,
    super.approvedAt,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] as String? ?? '',
      hostId: json['hostId'] as String? ?? '',
      // API trả field 'hostName' → map sang hostDisplayName
      hostDisplayName: json['hostName'] as String? ?? json['hostDisplayName'] as String?,
      cafeId: json['cafeId'] as String? ?? '',
      cafeName: json['cafeName'] as String? ?? '',
      cafeAddress: json['cafeAddress'] as String?,
      gameId: json['gameId'] as String? ?? '',
      gameName: json['gameName'] as String? ?? '',
      playDate: _parseDateOnly(json['playDate'] as String?) ?? DateTime.now(),
      timeSlot: TimeSlot.fromString(json['timeSlot'] as String? ?? 'evening'),
      preferredStartTime: json['preferredStartTime'] as String?,
      // API trả 'scheduledStartTime' → scheduledTime
      // Nếu list API không trả, fallback sang playDate + timeSlot
      scheduledTime: _parseDateTime(
        json['scheduledStartTime'] as String?,
        null,
      ) ?? _buildScheduledTimeFromPlayDateAndSlot(
        json['playDate'] as String?,
        json['timeSlot'] as String?,
      ),
      scheduledEndTime: _parseDateTime(
        json['scheduledEndTime'] as String?,
        null,
      ),
      recruitmentDeadline: _parseDateTime(
        json['recruitmentDeadline'] as String?,
        null,
      ),
      minPlayers: json['minPlayers'] as int? ?? 2,
      maxPlayers: json['maxPlayers'] as int? ?? 4,
      // API trả depositAmount → finalDeposit
      finalDeposit: json['depositAmount'] as int? ?? json['finalDeposit'] as int? ?? 0,
      // Các field tính toán mặc định
      depositRatePerPerson: json['depositRatePerPerson'] as int? ?? 0,
      baseDeposit: json['baseDeposit'] as int? ?? 0,
      riskMultiplier: (json['riskMultiplier'] as num?)?.toDouble() ?? 1.0,
      minDepositApplied: json['minDepositApplied'] as int? ?? 0,
      status: ReservationStatus.fromString(json['status'] as String? ?? 'draft'),
      currentPlayers: json['currentPlayers'] as int? ?? 1,
      lobbyId: json['lobbyId'] as String?,
      // API trả 'reservationCode' → lobbyShareCode
      lobbyShareCode: json['reservationCode'] as String? ?? json['lobbyShareCode'] as String?,
      lobbyStatus: json['lobbyStatus'] != null
          ? LobbyStatus.fromString(json['lobbyStatus'] as String)
          : null,
      isPrivate: json['isPrivate'] as bool? ?? false,
      requiresCafeApproval: json['requiresCafeApproval'] as bool? ?? false,
      cafeApprovalDeadline: _parseDateTime(
        json['cafeApprovalDeadline'] as String?,
        null,
      ),
      cafeRejectionReason: json['cafeRejectionReason'] as String?,
      refundPolicyApplied: json['refundPolicyApplied'] as String?,
      createdAt: _parseDateTime(json['createdAt'] as String?, null) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt'] as String?, null),
      checkedInAt: _parseDateTime(json['checkedInAt'] as String?, null),
      actualEndAt: _parseDateTime(json['actualEndAt'] as String?, null),
      approvedAt: _parseDateTime(json['approvedAt'] as String?, null),
      isHost: json['isHost'] as bool?,
      canCancel: json['canCancel'] as bool?,
      playedRatio: (json['playedRatio'] as num?)?.toDouble(),
      endReason: json['endReason'] as String?,
      tableNumber: json['tableNumber'] as String?,
      cancelledBy: json['cancelledBy'] as String?,
      cancelReason: json['cancelReason'] as String?,
      remainingApprovalHours: (json['remainingApprovalHours'] as num?)?.toInt(),
      remainingApprovalMinutes: (json['remainingApprovalMinutes'] as num?)?.toInt(),
      isCafeApproved: json['isCafeApproved'] as bool?,
    );
  }

  /// Parse datetime string mà KHÔNG coi 'Z' suffix là UTC.
  ///
  /// Backend Việt Nam thường gửi ISO string kèm 'Z' nhưng thực chất là
  /// giờ local (VN+7). Nếu để `DateTime.tryParse` parse đúng UTC rồi `.toLocal()`
  /// sẽ bị lệch 7 tiếng.
  ///
  /// Fix: strip 'Z' suffix trước khi parse để Flutter coi đó là local time.
  static DateTime? _parseDateTime(String? primary, String? fallback) {
    DateTime? parse(String? s) {
      if (s == null || s.isEmpty) return null;
      // Strip trailing 'Z' để parse thành local time thay vì UTC
      final normalized = s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
      return DateTime.tryParse(normalized);
    }

    return parse(primary) ?? parse(fallback);
  }

  /// Parse date-only string (không có time) như "2026-08-15".
  static DateTime? _parseDateOnly(String? s) {
    if (s == null || s.isEmpty) return null;
    return DateTime.tryParse(s);
  }

  /// Build scheduledTime từ playDate + timeSlot.
  ///
  /// Dùng khi list API không trả `scheduledStartTime` mà chỉ trả
  /// `playDate` (date only) + `timeSlot`
  /// (`Morning`/`Afternoon`/`Evening`/`LateNight`).
  static DateTime _buildScheduledTimeFromPlayDateAndSlot(
    String? playDate,
    String? timeSlot,
  ) {
    // Parse date từ string "2026-08-19"
    final date = DateTime.tryParse(playDate ?? '') ?? DateTime.now();

    // Parse time slot và lấy start time
    final slot = TimeSlot.fromString(timeSlot ?? 'evening');
    final timeParts = slot.startTime.split(':');
    final hour = int.tryParse(timeParts[0]) ?? 9;
    final minute = timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0;

    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostDisplayName,
      'cafeId': cafeId,
      'cafeName': cafeName,
      'cafeAddress': cafeAddress,
      'gameId': gameId,
      'gameName': gameName,
      'playDate': playDate.toIso8601String().split('T').first,
      'timeSlot': timeSlot.name,
      'preferredStartTime': preferredStartTime,
      'scheduledStartTime': scheduledTime.toIso8601String(),
      'scheduledEndTime': scheduledEndTime?.toIso8601String(),
      'recruitmentDeadline': recruitmentDeadline?.toIso8601String(),
      'minPlayers': minPlayers,
      'maxPlayers': maxPlayers,
      'depositAmount': finalDeposit,
      'depositRatePerPerson': depositRatePerPerson,
      'baseDeposit': baseDeposit,
      'riskMultiplier': riskMultiplier,
      'minDepositApplied': minDepositApplied,
      'finalDeposit': finalDeposit,
      'status': status.name,
      'currentPlayers': currentPlayers,
      'lobbyId': lobbyId,
      'reservationCode': lobbyShareCode,
      'lobbyShareCode': lobbyShareCode,
      'lobbyStatus': lobbyStatus?.name,
      'isPrivate': isPrivate,
      'requiresCafeApproval': requiresCafeApproval,
      'cafeApprovalDeadline': cafeApprovalDeadline?.toIso8601String(),
      'cafeRejectionReason': cafeRejectionReason,
      'refundPolicyApplied': refundPolicyApplied,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isHost': isHost,
      'canCancel': canCancel,
      'checkedInAt': checkedInAt?.toIso8601String(),
      'actualEndAt': actualEndAt?.toIso8601String(),
      'playedRatio': playedRatio,
      'endReason': endReason,
      'tableNumber': tableNumber,
      'remainingApprovalHours': remainingApprovalHours,
      'remainingApprovalMinutes': remainingApprovalMinutes,
      'isCafeApproved': isCafeApproved,
      'approvedAt': approvedAt?.toIso8601String(),
    };
  }
}
