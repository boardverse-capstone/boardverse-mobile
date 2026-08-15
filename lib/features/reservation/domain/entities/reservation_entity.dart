import 'package:equatable/equatable.dart';

/// Khung giờ cố định (BR-NEW-15)
enum TimeSlot {
  morning,
  afternoon,
  evening,
  night;

  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Phiên sáng';
      case TimeSlot.afternoon:
        return 'Phiên chiều';
      case TimeSlot.evening:
        return 'Phiên tối';
      case TimeSlot.night:
        return 'Phiên khuya';
    }
  }

  String get startTime {
    switch (this) {
      case TimeSlot.morning:
        return '09:00';
      case TimeSlot.afternoon:
        return '13:00';
      case TimeSlot.evening:
        return '18:00';
      case TimeSlot.night:
        return '19:00';
    }
  }

  String get endTime {
    switch (this) {
      case TimeSlot.morning:
        return '13:00';
      case TimeSlot.afternoon:
        return '18:00';
      case TimeSlot.evening:
        return '23:00';
      case TimeSlot.night:
        return '24:00';
    }
  }

  static TimeSlot fromString(String value) {
    return TimeSlot.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TimeSlot.evening,
    );
  }
}

/// Trạng thái reservation (BR §5.1)
enum ReservationStatus {
  draft,
  awaitingDeposit,
  holding,
  confirmed,
  checkedIn,
  completed,
  earlyCheckout,
  expired,
  cancelledByPlayer,
  cancelledByCafe,
  noShow,
  cancelledByHost,
  rejectedByCafe;

  String get displayName {
    switch (this) {
      case ReservationStatus.draft:
        return 'Nháp';
      case ReservationStatus.awaitingDeposit:
        return 'Chờ đặt cọc';
      case ReservationStatus.holding:
        return 'Đang giữ chỗ';
      case ReservationStatus.confirmed:
        return 'Đã xác nhận';
      case ReservationStatus.checkedIn:
        return 'Đã check-in';
      case ReservationStatus.completed:
        return 'Hoàn thành';
      case ReservationStatus.earlyCheckout:
        return 'Kết thúc sớm';
      case ReservationStatus.expired:
        return 'Hết hạn';
      case ReservationStatus.cancelledByPlayer:
        return 'Hủy bởi người dùng';
      case ReservationStatus.cancelledByCafe:
        return 'Hủy bởi quán';
      case ReservationStatus.cancelledByHost:
        return 'Chủ phòng hủy';
      case ReservationStatus.noShow:
        return 'Không đến';
      case ReservationStatus.rejectedByCafe:
        return 'Quán từ chối';
    }
  }

  bool get isActive =>
      this == ReservationStatus.holding ||
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.checkedIn;

  bool get isTerminal =>
      this == ReservationStatus.completed ||
      this == ReservationStatus.earlyCheckout ||
      this == ReservationStatus.expired ||
      this == ReservationStatus.cancelledByPlayer ||
      this == ReservationStatus.cancelledByCafe ||
      this == ReservationStatus.cancelledByHost ||
      this == ReservationStatus.noShow ||
      this == ReservationStatus.rejectedByCafe;

  static ReservationStatus fromString(String value) {
    return ReservationStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => ReservationStatus.draft,
    );
  }
}

/// Trạng thái lobby liên quan (BR §5.3)
enum LobbyStatus {
  pendingActivation,
  pendingCafeApproval,
  open,
  viable,
  full,
  inProgress,
  closed,
  timeoutFailed,
  hostCancelled,
  rejectedByCafe,
  expiredByCafe;

  String get displayName {
    switch (this) {
      case LobbyStatus.pendingActivation:
        return 'Đang kích hoạt';
      case LobbyStatus.pendingCafeApproval:
        return 'Chờ quán duyệt';
      case LobbyStatus.open:
        return 'Mở';
      case LobbyStatus.viable:
        return 'Đủ người';
      case LobbyStatus.full:
        return 'Đầy';
      case LobbyStatus.inProgress:
        return 'Đang chơi';
      case LobbyStatus.closed:
        return 'Đóng';
      case LobbyStatus.timeoutFailed:
        return 'Hết hạn';
      case LobbyStatus.hostCancelled:
        return 'Host hủy';
      case LobbyStatus.rejectedByCafe:
        return 'Quán từ chối';
      case LobbyStatus.expiredByCafe:
        return 'Hết hạn duyệt';
    }
  }

  bool get isActive =>
      this == LobbyStatus.open ||
      this == LobbyStatus.viable ||
      this == LobbyStatus.full ||
      this == LobbyStatus.inProgress ||
      this == LobbyStatus.pendingCafeApproval;

  static LobbyStatus fromString(String value) {
    return LobbyStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => LobbyStatus.open,
    );
  }
}

extension LobbyStatusX on LobbyStatus {
  bool get isCafePending => this == LobbyStatus.pendingCafeApproval;
  bool get isRejectedByCafe => this == LobbyStatus.rejectedByCafe;
  bool get isExpiredByCafe => this == LobbyStatus.expiredByCafe;
}

extension ReservationStatusX on ReservationStatus {
  bool get isAwaitingCafeApproval =>
      this == ReservationStatus.holding &&
      // awaiting flag được suy ra từ lobbyStatus.pendingCafeApproval; đây
      // chỉ là helper khi chỉ có reservation status.
      false;

  bool get isCancelledByCafe =>
      this == ReservationStatus.cancelledByCafe ||
      this == ReservationStatus.rejectedByCafe;
}

/// Mức rủi ro của user theo `riskScore` (BR-RISK-*).
/// Backend trả về trong quote response (`riskLevel` field) để client
/// hiển thị cảnh báo tiền cọc nhân hệ số cao.
enum RiskLevel {
  low,
  medium,
  high,
  critical;

  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Bình thường';
      case RiskLevel.medium:
        return 'Trung bình';
      case RiskLevel.high:
        return 'Cao';
      case RiskLevel.critical:
        return 'Nghiêm trọng';
    }
  }

  /// Hệ số nhân cọc tương ứng với mức rủi ro.
  /// Khớp với `riskMultiplier` mapping BR-RISK-03 trong business rules.
  double get suggestedMultiplier {
    switch (this) {
      case RiskLevel.low:
        return 1.0;
      case RiskLevel.medium:
        return 1.25;
      case RiskLevel.high:
        return 1.5;
      case RiskLevel.critical:
        return 2.0;
    }
  }

  static RiskLevel fromString(String value) {
    return RiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}

/// Entity cho Reservation (BR §2, §6)
class ReservationEntity extends Equatable {
  final String id;
  final String hostId;

  /// Tên hiển thị của host (từ backend).
  final String? hostDisplayName;

  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime playDate;
  final TimeSlot timeSlot;
  final String? preferredStartTime;
  final DateTime scheduledTime;
  final DateTime recruitmentDeadline;
  final int minPlayers;
  final int maxPlayers;
  final int depositRatePerPerson;
  final int baseDeposit;
  final double riskMultiplier;
  final int minDepositApplied;
  final int finalDeposit;
  final ReservationStatus status;
  final int currentPlayers;
  final String? lobbyId;

  /// Mã share code 8 ký tự của lobby (vd: K7H3NP9X).
  /// Trong list API, backend trả dưới field `reservationCode`.
  final String? lobbyShareCode;
  final LobbyStatus? lobbyStatus;
  final bool isPrivate;
  final bool requiresCafeApproval;
  final DateTime? cafeApprovalDeadline;
  final String? cafeRejectionReason;
  final String? refundPolicyApplied;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// User hiện tại có phải host của reservation này không (chỉ có ở list API).
  final bool? isHost;

  /// Còn lại bao nhiêu giờ đến cafe approval deadline (tính từ server).
  final int? remainingApprovalHours;

  /// Còn lại bao nhiêu phút đến cafe approval deadline (tính từ server).
  final int? remainingApprovalMinutes;

  /// Cafe đã duyệt chưa. Một số endpoint chỉ trả status nhưng UI cần biết
  /// chính xác để hiển thị banner.
  final bool? isCafeApproved;

  /// Thời điểm cafe duyệt (nếu có).
  final DateTime? approvedAt;

  const ReservationEntity({
    required this.id,
    required this.hostId,
    this.hostDisplayName,
    required this.cafeId,
    required this.cafeName,
    required this.gameId,
    required this.gameName,
    required this.playDate,
    required this.timeSlot,
    this.preferredStartTime,
    required this.scheduledTime,
    required this.recruitmentDeadline,
    required this.minPlayers,
    required this.maxPlayers,
    required this.depositRatePerPerson,
    required this.baseDeposit,
    required this.riskMultiplier,
    required this.minDepositApplied,
    required this.finalDeposit,
    required this.status,
    required this.currentPlayers,
    this.lobbyId,
    this.lobbyShareCode,
    this.lobbyStatus,
    this.isPrivate = false,
    required this.requiresCafeApproval,
    this.cafeApprovalDeadline,
    this.cafeRejectionReason,
    this.refundPolicyApplied,
    required this.createdAt,
    this.updatedAt,
    this.isHost,
    this.remainingApprovalHours,
    this.remainingApprovalMinutes,
    this.isCafeApproved,
    this.approvedAt,
  });

  /// Tính số ghế còn trống
  int get remainingSlots => maxPlayers - currentPlayers;

  /// Lobby đã đầy chưa
  bool get isLobbyFull => currentPlayers >= maxPlayers;

  /// Lobby đã đạt minPlayers chưa
  bool get hasReachedMinPlayers => currentPlayers >= minPlayers;

  /// Tính thời gian còn lại đến recruitment deadline
  Duration get timeToDeadline => recruitmentDeadline.difference(DateTime.now());

  /// Kiểm tra còn trong recruitment window không
  bool get isWithinRecruitmentWindow =>
      DateTime.now().isBefore(recruitmentDeadline);

  /// Tính buffer time (thời gian từ now đến deadline)
  int get bufferMinutes => timeToDeadline.inMinutes;

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostDisplayName,
        cafeId,
        gameId,
        playDate,
        timeSlot,
        preferredStartTime,
        scheduledTime,
        recruitmentDeadline,
        minPlayers,
        maxPlayers,
        finalDeposit,
        status,
        currentPlayers,
        lobbyId,
        lobbyShareCode,
        lobbyStatus,
        requiresCafeApproval,
        createdAt,
        updatedAt,
        isHost,
      remainingApprovalHours,
        remainingApprovalMinutes,
        isCafeApproved,
        approvedAt,
      ];
}
