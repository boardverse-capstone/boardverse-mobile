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

/// Kết quả cancel reservation
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
