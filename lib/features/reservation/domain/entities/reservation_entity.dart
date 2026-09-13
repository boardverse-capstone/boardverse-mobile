import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../lobby_management/domain/entities/lobby_entity.dart';

/// Khung giờ cố định (BR-NEW-15)
enum TimeSlot {
  morning,
  afternoon,
  evening,
  lateNight;

  String get displayName {
    switch (this) {
      case TimeSlot.morning:
        return 'Phiên sáng';
      case TimeSlot.afternoon:
        return 'Phiên chiều';
      case TimeSlot.evening:
        return 'Phiên tối';
      case TimeSlot.lateNight:
        return 'Phiên khuya';
    }
  }

  /// Giờ bắt đầu mặc định của khung giờ (HH:mm).
  /// LateNight vượt qua 0 giờ ngày hôm sau — server vẫn hợp lệ.
  String get startTime {
    switch (this) {
      case TimeSlot.morning:
        return '09:00';
      case TimeSlot.afternoon:
        return '13:00';
      case TimeSlot.evening:
        return '18:00';
      case TimeSlot.lateNight:
        return '23:00';
    }
  }

  /// Giờ kết thúc mặc định của khung giờ (HH:mm).
  /// LateNight kết thúc 06:00 ngày hôm sau.
  String get endTime {
    switch (this) {
      case TimeSlot.morning:
        return '13:00';
      case TimeSlot.afternoon:
        return '18:00';
      case TimeSlot.evening:
        return '23:00';
      case TimeSlot.lateNight:
        return '06:00';
    }
  }

  static TimeSlot fromString(String value) {
    // BR-NEW-15 — backend dùng 'LateNight' (không phải 'Night' như BR cũ).
    // Accept cả 'night' (backward-compat) + 'lateNight' / 'LateNight' / 'LATE_NIGHT'.
    final normalized = value.toLowerCase().replaceAll('_', '').trim();
    switch (normalized) {
      case 'morning':
        return TimeSlot.morning;
      case 'afternoon':
        return TimeSlot.afternoon;
      case 'evening':
        return TimeSlot.evening;
      case 'latenight':
      case 'night':
        return TimeSlot.lateNight;
      default:
        return TimeSlot.evening;
    }
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

/// Phân loại vai trò của user với một reservation.
///
/// Được backend trả về trong `GET /api/v1/reservations/my` qua field
/// `participationType`. Cho phép FE phân biệt trực quan giữa:
/// - **Host**: reservation do user tạo (user trả cọc + chịu trách nhiệm).
/// - **Member**: reservation user tham gia với vai trò thành viên (lobby do
///   người khác host).
///
/// Mapping query string filter (xem `.agents/docs/apis_docs/reservation.md`
/// §GET /my): `participationType=Host` hoặc `=Member`. Null = lấy cả hai.
///
/// Binding note (2026-09-02): ASP.NET Core bind enum theo string name
/// **case-insensitive** — `host`, `Host`, `HOST` đều OK.
enum ReservationParticipationType {
  host,
  member;

  String get displayName {
    switch (this) {
      case ReservationParticipationType.host:
        return 'Tôi tạo';
      case ReservationParticipationType.member:
        return 'Tôi tham gia';
    }
  }

  /// Short label dùng cho badge trên card — uppercase, ngắn gọn.
  String get shortLabel {
    switch (this) {
      case ReservationParticipationType.host:
        return 'CHỦ PHÒNG';
      case ReservationParticipationType.member:
        return 'THÀNH VIÊN';
    }
  }

  IconData get icon {
    switch (this) {
      case ReservationParticipationType.host:
        return Icons.workspace_premium_rounded;
      case ReservationParticipationType.member:
        return Icons.groups_rounded;
    }
  }

  /// Convert sang query string cho API filter.
  String get apiValue => name; // "host" | "member"

  static ReservationParticipationType? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'host':
        return ReservationParticipationType.host;
      case 'member':
        return ReservationParticipationType.member;
      default:
        return null;
    }
  }
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
///
/// Parse đúng các field từ API response thực tế.
class ReservationEntity extends Equatable {
  final String id;
  final String hostId;

  /// Tên hiển thị của host (từ backend field 'hostName').
  final String? hostDisplayName;

  final String cafeId;
  final String cafeName;

  /// Địa chỉ quán (từ backend field 'cafeAddress').
  final String? cafeAddress;

  final String gameId;
  final String gameName;
  final DateTime playDate;
  final TimeSlot timeSlot;
  final String? preferredStartTime;
  final String? preferredEndTime;

  /// Thời gian bắt đầu reservation (từ field 'scheduledStartTime' API).
  final DateTime scheduledTime;

  /// Thời gian kết thúc reservation (từ field 'scheduledEndTime' API).
  final DateTime? scheduledEndTime;

  /// Thời gian hết hạn tuyển người.
  final DateTime? recruitmentDeadline;

  final int minPlayers;
  final int maxPlayers;

  /// Số tiền cọc cuối cùng (từ field 'depositAmount' API).
  final int finalDeposit;

  /// Phí cọc/người (tính toán).
  final int depositRatePerPerson;

  /// Cọc base (tính toán).
  final int baseDeposit;

  /// Hệ số rủi ro (từ field 'riskMultiplier' API).
  final double riskMultiplier;

  /// Cọc tối thiểu áp dụng.
  final int minDepositApplied;

  final ReservationStatus status;
  final int currentPlayers;
  final String? lobbyId;

  /// Mã share code của lobby (từ field 'reservationCode' API).
  final String? lobbyShareCode;

  final LobbyStatus? lobbyStatus;
  final bool isPrivate;
  final bool requiresCafeApproval;
  final DateTime? cafeApprovalDeadline;
  final String? cafeRejectionReason;
  final String? refundPolicyApplied;
  final DateTime createdAt;
  final DateTime? updatedAt;

  /// User hiện tại có phải host của reservation này không.
  final bool? isHost;

  /// Có thể hủy reservation không (từ field 'canCancel' API).
  final bool? canCancel;

  /// Thời điểm check-in (từ field 'checkedInAt' API).
  final DateTime? checkedInAt;

  /// Thời điểm kết thúc thực tế (từ field 'actualEndAt' API).
  final DateTime? actualEndAt;

  /// Tỷ lệ đã chơi (từ field 'playedRatio' API).
  final double? playedRatio;

  /// Lý do kết thúc (từ field 'endReason' API).
  final String? endReason;

  /// Số bàn (từ field 'tableNumber' API).
  final String? tableNumber;

  /// Người đã hủy (từ field 'cancelledBy' API).
  final String? cancelledBy;

  /// Lý do hủy (từ field 'cancelReason' API).
  final String? cancelReason;

  /// Còn lại bao nhiêu giờ đến cafe approval deadline (tính từ server).
  final int? remainingApprovalHours;

  /// Còn lại bao nhiêu phút đến cafe approval deadline (tính từ server).
  final int? remainingApprovalMinutes;

  /// Cafe đã duyệt chưa.
  final bool? isCafeApproved;

  /// Thời điểm cafe duyệt (nếu có).
  final DateTime? approvedAt;

  /// Vai trò của user hiện tại với reservation này (Host | Member).
  ///
  /// Được backend trả về trong `GET /api/v1/reservations/my`. Null nếu
  /// reservation lấy từ endpoint khác (vd: `GET /api/v1/reservations/{id}`)
  /// — fallback suy ra từ [isHost].
  final ReservationParticipationType? participationType;

  const ReservationEntity({
    required this.id,
    required this.hostId,
    this.hostDisplayName,
    required this.cafeId,
    required this.cafeName,
    this.cafeAddress,
    required this.gameId,
    required this.gameName,
    required this.playDate,
    // BR-NEW-15 (2026-08-18): `timeSlot` không còn là input bắt buộc từ
    // client (BE tự resolve từ `preferredStartTime` + `preferredEndTime`).
    // Tuy nhiên BE vẫn trả về trong response cho backward compatibility
    // — đặt default `TimeSlot.evening` để tránh breaking change ở các
    // call site cũ (vd: tests). Có thể bỏ default sau khi dọn hết callers.
    this.timeSlot = TimeSlot.evening,
    this.preferredStartTime,
    this.preferredEndTime,
    required this.scheduledTime,
    this.scheduledEndTime,
    this.recruitmentDeadline,
    required this.minPlayers,
    required this.maxPlayers,
    required this.finalDeposit,
    this.depositRatePerPerson = 0,
    this.baseDeposit = 0,
    this.riskMultiplier = 1.0,
    this.minDepositApplied = 0,
    required this.status,
    required this.currentPlayers,
    this.lobbyId,
    this.lobbyShareCode,
    this.lobbyStatus,
    this.isPrivate = false,
    this.requiresCafeApproval = false,
    this.cafeApprovalDeadline,
    this.cafeRejectionReason,
    this.refundPolicyApplied,
    required this.createdAt,
    this.updatedAt,
    this.isHost,
    this.canCancel,
    this.checkedInAt,
    this.actualEndAt,
    this.playedRatio,
    this.endReason,
    this.tableNumber,
    this.cancelledBy,
    this.cancelReason,
    this.remainingApprovalHours,
    this.remainingApprovalMinutes,
    this.isCafeApproved,
    this.approvedAt,
    this.participationType,
  });

  /// Tính số ghế còn trống
  int get remainingSlots => maxPlayers - currentPlayers;

  /// Lobby đã đầy chưa
  bool get isLobbyFull => currentPlayers >= maxPlayers;

  /// Lobby đã đạt minPlayers chưa
  bool get hasReachedMinPlayers => currentPlayers >= minPlayers;

  /// Resolve vai trò của user với reservation này, fallback từ [isHost] nếu
  /// backend không trả về `participationType`.
  ///
  /// Logic:
  /// - Nếu backend đã trả `participationType` (vd: từ `/my`) → dùng trực tiếp.
  /// - Ngược lại, suy ra từ `isHost`:
  ///   - `isHost = true` → `host`
  ///   - `isHost = false` hoặc `null` → `member`
  ///
  /// Dùng cho UI cần phân biệt host/member để render badge/ribbon tương ứng.
  ReservationParticipationType get effectiveParticipationType {
    if (participationType != null) return participationType!;
    if (isHost == true) return ReservationParticipationType.host;
    return ReservationParticipationType.member;
  }

  /// True nếu user hiện tại là host của reservation này (đã trả cọc).
  bool get isUserHost => effectiveParticipationType == ReservationParticipationType.host;

  /// True nếu user hiện tại là member tham gia reservation của người khác.
  bool get isUserMember => effectiveParticipationType == ReservationParticipationType.member;

  /// Tính thời gian còn lại đến recruitment deadline
  Duration get timeToDeadline {
    if (recruitmentDeadline == null) return Duration.zero;
    return recruitmentDeadline!.difference(DateTime.now());
  }

  /// Kiểm tra còn trong recruitment window không
  bool get isWithinRecruitmentWindow =>
      recruitmentDeadline != null &&
      DateTime.now().isBefore(recruitmentDeadline!);

  /// Tính buffer time (thời gian từ now đến deadline)
  int get bufferMinutes => timeToDeadline.inMinutes;

  /// Copy with selected fields.
  ///
  /// Dùng khi cần mutate 1-2 field (vd: enrich `currentPlayers` từ lobby
  /// detail) mà không muốn copy nguyên entity.
  ReservationEntity copyWith({
    String? id,
    String? hostId,
    String? hostDisplayName,
    String? cafeId,
    String? cafeName,
    String? cafeAddress,
    String? gameId,
    String? gameName,
    DateTime? playDate,
    TimeSlot? timeSlot,
    String? preferredStartTime,
    String? preferredEndTime,
    DateTime? scheduledTime,
    DateTime? scheduledEndTime,
    DateTime? recruitmentDeadline,
    int? minPlayers,
    int? maxPlayers,
    int? finalDeposit,
    int? depositRatePerPerson,
    int? baseDeposit,
    double? riskMultiplier,
    int? minDepositApplied,
    ReservationStatus? status,
    int? currentPlayers,
    String? lobbyId,
    String? lobbyShareCode,
    LobbyStatus? lobbyStatus,
    bool? isPrivate,
    bool? requiresCafeApproval,
    DateTime? cafeApprovalDeadline,
    String? cafeRejectionReason,
    String? refundPolicyApplied,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isHost,
    bool? canCancel,
    DateTime? checkedInAt,
    DateTime? actualEndAt,
    double? playedRatio,
    String? endReason,
    String? tableNumber,
    String? cancelledBy,
    String? cancelReason,
    int? remainingApprovalHours,
    int? remainingApprovalMinutes,
    bool? isCafeApproved,
    DateTime? approvedAt,
    ReservationParticipationType? participationType,
  }) {
    return ReservationEntity(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostDisplayName: hostDisplayName ?? this.hostDisplayName,
      cafeId: cafeId ?? this.cafeId,
      cafeName: cafeName ?? this.cafeName,
      cafeAddress: cafeAddress ?? this.cafeAddress,
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      playDate: playDate ?? this.playDate,
      timeSlot: timeSlot ?? this.timeSlot,
      preferredStartTime: preferredStartTime ?? this.preferredStartTime,
      preferredEndTime: preferredEndTime ?? this.preferredEndTime,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      scheduledEndTime: scheduledEndTime ?? this.scheduledEndTime,
      recruitmentDeadline: recruitmentDeadline ?? this.recruitmentDeadline,
      minPlayers: minPlayers ?? this.minPlayers,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      finalDeposit: finalDeposit ?? this.finalDeposit,
      depositRatePerPerson: depositRatePerPerson ?? this.depositRatePerPerson,
      baseDeposit: baseDeposit ?? this.baseDeposit,
      riskMultiplier: riskMultiplier ?? this.riskMultiplier,
      minDepositApplied: minDepositApplied ?? this.minDepositApplied,
      status: status ?? this.status,
      currentPlayers: currentPlayers ?? this.currentPlayers,
      lobbyId: lobbyId ?? this.lobbyId,
      lobbyShareCode: lobbyShareCode ?? this.lobbyShareCode,
      lobbyStatus: lobbyStatus ?? this.lobbyStatus,
      isPrivate: isPrivate ?? this.isPrivate,
      requiresCafeApproval: requiresCafeApproval ?? this.requiresCafeApproval,
      cafeApprovalDeadline: cafeApprovalDeadline ?? this.cafeApprovalDeadline,
      cafeRejectionReason: cafeRejectionReason ?? this.cafeRejectionReason,
      refundPolicyApplied: refundPolicyApplied ?? this.refundPolicyApplied,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isHost: isHost ?? this.isHost,
      canCancel: canCancel ?? this.canCancel,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      actualEndAt: actualEndAt ?? this.actualEndAt,
      playedRatio: playedRatio ?? this.playedRatio,
      endReason: endReason ?? this.endReason,
      tableNumber: tableNumber ?? this.tableNumber,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      remainingApprovalHours: remainingApprovalHours ?? this.remainingApprovalHours,
      remainingApprovalMinutes: remainingApprovalMinutes ?? this.remainingApprovalMinutes,
      isCafeApproved: isCafeApproved ?? this.isCafeApproved,
      approvedAt: approvedAt ?? this.approvedAt,
      participationType: participationType ?? this.participationType,
    );
  }

  @override
  List<Object?> get props => [
        id,
        hostId,
        hostDisplayName,
        cafeId,
        cafeName,
        cafeAddress,
        gameId,
        gameName,
        playDate,
        timeSlot,
        preferredStartTime,
        preferredEndTime,
        scheduledTime,
        scheduledEndTime,
        recruitmentDeadline,
        minPlayers,
        maxPlayers,
        finalDeposit,
        depositRatePerPerson,
        baseDeposit,
        riskMultiplier,
        minDepositApplied,
        status,
        currentPlayers,
        lobbyId,
        lobbyShareCode,
        lobbyStatus,
        isPrivate,
        requiresCafeApproval,
        cafeApprovalDeadline,
        cafeRejectionReason,
        refundPolicyApplied,
        createdAt,
        updatedAt,
        isHost,
        canCancel,
        checkedInAt,
        actualEndAt,
        playedRatio,
        endReason,
        tableNumber,
        remainingApprovalHours,
        remainingApprovalMinutes,
        isCafeApproved,
        approvedAt,
        participationType,
      ];
}

/// Extension chuyển `refundPolicyApplied` (raw string từ backend) thành
/// label tiếng Việt dễ đọc cho UI.
///
/// Backend các giá trị BR-REFUND-02 (BVC v2) trả về:
/// - `Cancel-Grace`: huỷ trong 15 phút đầu sau khi confirm → hoàn 100%.
/// - `Cancel-24h`: huỷ trước 24 giờ trước giờ chơi → hoàn 100%.
/// - `Cancel-Less24h`: huỷ dưới 24 giờ trước giờ chơi (ngoài grace) →
///   hoàn 0%, có thể bị trừ Karma.
///
/// Lưu ý: tier `Cancel-6h` (50% hoàn) đã bị BVC v2 bỏ — extension này
/// fallback về raw string nếu nhận giá trị không xác định (giữ backward-
/// compat nếu backend cũ / dữ liệu cũ).
extension RefundPolicyLabelX on String? {
  String get refundPolicyLabel {
    final raw = this;
    if (raw == null || raw.isEmpty) return 'Không áp dụng';
    switch (raw) {
      case 'Cancel-Grace':
        return 'Hoàn 100% (trong 15 phút đầu)';
      case 'Cancel-24h':
        return 'Hoàn 100% (trước 24 giờ)';
      case 'Cancel-Less24h':
        return 'Không hoàn — phạt Karma';
      default:
        return raw;
    }
  }
}
