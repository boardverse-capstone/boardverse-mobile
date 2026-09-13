import 'package:equatable/equatable.dart';

import 'reservation_entity.dart';

/// Entity cho Quote (chưa tạo DB row)
/// Quote chỉ dùng để hiển thị, không tạo reservation
class ReservationQuoteEntity extends Equatable {
  final String? reservationId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime playDate;
  final TimeSlot timeSlot;
  final String? preferredStartTime;
  final String? preferredEndTime;

  /// Giờ bắt đầu thực tế được xếp lịch (server tính toán từ timeSlot + preferredStartTime).
  final DateTime scheduledStartTime;

  /// Giờ kết thúc thực tế được xếp lịch (server tính toán từ timeSlot.endTime hoặc preferredEndTime).
  final DateTime scheduledEndTime;

  final DateTime recruitmentDeadline;
  final int minPlayers;
  final int maxPlayers;
  final int depositRatePerPerson;
  final int baseDeposit;
  final double riskMultiplier;
  final int minDepositApplied;
  final int finalDeposit;
  final int currentBalance;
  final int missingAmount;
  final int bufferMinutes;
  final bool bufferWarning;
  final bool isPrivate;
  final bool requiresCafeApproval;
  final DateTime expiresAt;
  final List<String> warnings;

  /// Mức rủi ro của user kèm theo quote (BR-RISK-*).
  /// Backend trả về để client hiển thị cảnh báo trước khi confirm.
  /// Default `low` cho backward-compat với quote response cũ.
  final RiskLevel riskLevel;

  const ReservationQuoteEntity({
    this.reservationId,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.playDate,
    required this.timeSlot,
    this.preferredStartTime,
    this.preferredEndTime,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.recruitmentDeadline,
    required this.minPlayers,
    required this.maxPlayers,
    required this.depositRatePerPerson,
    required this.baseDeposit,
    required this.riskMultiplier,
    required this.minDepositApplied,
    required this.finalDeposit,
    required this.currentBalance,
    required this.missingAmount,
    required this.bufferMinutes,
    required this.bufferWarning,
    this.isPrivate = false,
    required this.requiresCafeApproval,
    required this.expiresAt,
    required this.warnings,
    this.riskLevel = RiskLevel.low,
  });

  /// Kiểm tra user có đủ số dư không
  bool get hasEnoughBalance => currentBalance >= finalDeposit;

  /// Tính thời gian còn lại của quote
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Quote đã hết hạn chưa
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Tính buffer warning level
  BufferWarningLevel get bufferWarningLevel {
    if (bufferMinutes >= 120) return BufferWarningLevel.none;
    if (bufferMinutes >= 60) return BufferWarningLevel.warning;
    return BufferWarningLevel.rejected;
  }

  /// Định dạng hiển thị số người chơi:
  /// - Khi minPlayers == maxPlayers → "X-Y" (VD: "2-2")
  /// - Khi minPlayers != maxPlayers → "X-Y" (VD: "2-4")
  ///
  /// Tránh UI hiển thị "2-2" khó hiểu khi chỉ có 1 giá trị.
  String get playerRangeDisplay =>
      minPlayers == maxPlayers ? '$minPlayers' : '$minPlayers-$maxPlayers';

  @override
  List<Object?> get props => [
        cafeId,
        gameId,
        playDate,
        timeSlot,
        minPlayers,
        maxPlayers,
        finalDeposit,
        currentBalance,
        missingAmount,
        bufferMinutes,
        bufferWarning,
        isPrivate,
        requiresCafeApproval,
        expiresAt,
        riskLevel,
        scheduledStartTime,
        scheduledEndTime,
        preferredStartTime,
        preferredEndTime,
      ];
}

enum BufferWarningLevel {
  none,
  warning,
  rejected;

  String get message {
    switch (this) {
      case BufferWarningLevel.none:
        return '';
      case BufferWarningLevel.warning:
        return 'Thời gian tuyển người ngắn. Khuyến nghị chọn slot xa hơn.';
      case BufferWarningLevel.rejected:
        return 'Thời gian tuyển người quá ngắn. Vui lòng chọn slot khác.';
    }
  }
}

/// Kết quả confirm reservation
class ReservationConfirmResult extends Equatable {
  final String reservationId;
  final String lobbyId;
  final String? lobbyShareCode;
  final DateTime recruitmentDeadline;
  final bool requiresCafeApproval;
  final DateTime? cafeApprovalDeadline;
  final int heldBvc;

  const ReservationConfirmResult({
    required this.reservationId,
    required this.lobbyId,
    this.lobbyShareCode,
    required this.recruitmentDeadline,
    required this.requiresCafeApproval,
    this.cafeApprovalDeadline,
    required this.heldBvc,
  });

  @override
  List<Object?> get props => [
        reservationId,
        lobbyId,
        lobbyShareCode,
        recruitmentDeadline,
        requiresCafeApproval,
        cafeApprovalDeadline,
        heldBvc,
      ];
}

/// Kết quả cancel reservation (trước khi check-in)
class ReservationCancelResult extends Equatable {
  final String reservationId;
  final String lobbyId;
  final int refundBvc;
  final int forfeitBvc;
  final String refundPolicyApplied;

  const ReservationCancelResult({
    required this.reservationId,
    required this.lobbyId,
    required this.refundBvc,
    required this.forfeitBvc,
    required this.refundPolicyApplied,
  });

  @override
  List<Object?> get props => [
        reservationId,
        lobbyId,
        refundBvc,
        forfeitBvc,
        refundPolicyApplied,
      ];
}

/// Kết quả cancel-after-checkin (BR-REFUND-04/05)
class ReservationCancelAfterCheckinResult extends Equatable {
  final String reservationId;
  final String previousStatus;
  final String newStatus;
  final int playDurationMinutes;
  final double playedRatio;
  final int refundBvc;
  final int forfeitBvc;
  final String refundReason;
  final String cancellationType;
  final DateTime cancelledAt;

  const ReservationCancelAfterCheckinResult({
    required this.reservationId,
    required this.previousStatus,
    required this.newStatus,
    required this.playDurationMinutes,
    required this.playedRatio,
    required this.refundBvc,
    required this.forfeitBvc,
    required this.refundReason,
    required this.cancellationType,
    required this.cancelledAt,
  });

  /// Kiểm tra có được hoàn tiền không
  bool get hasRefund => refundBvc > 0;

  /// Kiểm tra có bị phạt không
  bool get hasForfeit => forfeitBvc > 0;

  @override
  List<Object?> get props => [
        reservationId,
        previousStatus,
        newStatus,
        playDurationMinutes,
        playedRatio,
        refundBvc,
        forfeitBvc,
        refundReason,
        cancellationType,
        cancelledAt,
      ];
}

/// Kết quả extend availability check (BR-EXT-01..05)
class ExtendAvailabilityResult extends Equatable {
  final String reservationId;
  final DateTime currentScheduledEndTime;
  final int requestedExtensionMinutes;
  final DateTime newScheduledEndTime;
  final bool isAvailable;
  final int remainingExtensionMinutes;
  final int extensionCount;
  final int maxExtensionMinutes;
  final String? reason;

  const ExtendAvailabilityResult({
    required this.reservationId,
    required this.currentScheduledEndTime,
    required this.requestedExtensionMinutes,
    required this.newScheduledEndTime,
    required this.isAvailable,
    required this.remainingExtensionMinutes,
    required this.extensionCount,
    required this.maxExtensionMinutes,
    this.reason,
  });

  /// Kiểm tra còn có thể extend không
  bool get canExtend => isAvailable && remainingExtensionMinutes > 0;

  /// Kiểm tra đã đạt max chưa
  bool get isMaxedOut => extensionCount >= 2;

  @override
  List<Object?> get props => [
        reservationId,
        currentScheduledEndTime,
        requestedExtensionMinutes,
        newScheduledEndTime,
        isAvailable,
        remainingExtensionMinutes,
        extensionCount,
        maxExtensionMinutes,
        reason,
      ];
}

/// Kết quả check-in bằng QR code (POS)
class CheckInByCodeResult extends Equatable {
  final String reservationId;
  final String lobbyId;
  final String activeSessionId;
  final String reservationStatus;
  final String lobbyStatus;
  final DateTime checkedInAt;
  final int heldBvc;

  const CheckInByCodeResult({
    required this.reservationId,
    required this.lobbyId,
    required this.activeSessionId,
    required this.reservationStatus,
    required this.lobbyStatus,
    required this.checkedInAt,
    required this.heldBvc,
  });

  @override
  List<Object?> get props => [
        reservationId,
        lobbyId,
        activeSessionId,
        reservationStatus,
        lobbyStatus,
        checkedInAt,
        heldBvc,
      ];
}

/// Request model cho cancel-after-checkin
class CancelAfterCheckinRequest {
  final String reservationId;
  final String? reason;
  final String idempotencyKey;

  const CancelAfterCheckinRequest({
    required this.reservationId,
    this.reason,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'reservationId': reservationId,
        if (reason != null) 'reason': reason,
        'idempotencyKey': idempotencyKey,
      };
}

/// Request model cho check-in bằng QR code (POS)
class CheckInByCodeRequest {
  final String cafeId;
  final String reservationCode;
  final String activeSessionId;
  final String idempotencyKey;

  const CheckInByCodeRequest({
    required this.cafeId,
    required this.reservationCode,
    required this.activeSessionId,
    required this.idempotencyKey,
  });

  Map<String, dynamic> toJson() => {
        'cafeId': cafeId,
        'reservationCode': reservationCode,
        'activeSessionId': activeSessionId,
        'idempotencyKey': idempotencyKey,
      };
}
