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
  expired,
  cancelledByPlayer,
  cancelledByCafe,
  noShow;

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
      case ReservationStatus.expired:
        return 'Hết hạn';
      case ReservationStatus.cancelledByPlayer:
        return 'Hủy bởi người dùng';
      case ReservationStatus.cancelledByCafe:
        return 'Hủy bởi quán';
      case ReservationStatus.noShow:
        return 'Không đến';
    }
  }

  bool get isActive =>
      this == ReservationStatus.holding ||
      this == ReservationStatus.confirmed ||
      this == ReservationStatus.checkedIn;

  bool get isTerminal =>
      this == ReservationStatus.completed ||
      this == ReservationStatus.expired ||
      this == ReservationStatus.cancelledByPlayer ||
      this == ReservationStatus.cancelledByCafe ||
      this == ReservationStatus.noShow;

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

/// Entity cho Reservation (BR §2, §6)
class ReservationEntity extends Equatable {
  final String id;
  final String hostId;
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
  final LobbyStatus? lobbyStatus;
  final bool requiresCafeApproval;
  final DateTime? cafeApprovalDeadline;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ReservationEntity({
    required this.id,
    required this.hostId,
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
    this.lobbyStatus,
    required this.requiresCafeApproval,
    this.cafeApprovalDeadline,
    required this.createdAt,
    this.updatedAt,
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
        lobbyStatus,
        requiresCafeApproval,
        createdAt,
        updatedAt,
      ];
}
