import 'package:equatable/equatable.dart';

/// Trạng thái của 1 entry trong waitlist — map từ backend enum.
enum WaitlistEntryStatus {
  /// Đang chờ slot trống.
  waiting,

  /// Đã được promote lên participant.
  promoted,

  /// Hết hạn (không phản hồi trong 24h).
  expired,

  /// Tự rời khỏi waitlist / từ chối offer.
  cancelled,
}

extension WaitlistEntryStatusX on WaitlistEntryStatus {
  String get apiKey {
    switch (this) {
      case WaitlistEntryStatus.waiting:
        return 'Waiting';
      case WaitlistEntryStatus.promoted:
        return 'Promoted';
      case WaitlistEntryStatus.expired:
        return 'Expired';
      case WaitlistEntryStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get displayLabel {
    switch (this) {
      case WaitlistEntryStatus.waiting:
        return 'Đang chờ';
      case WaitlistEntryStatus.promoted:
        return 'Đã tham gia';
      case WaitlistEntryStatus.expired:
        return 'Hết hạn';
      case WaitlistEntryStatus.cancelled:
        return 'Đã hủy';
    }
  }

  static WaitlistEntryStatus fromApi(String? raw) {
    switch (raw) {
      case 'Waiting':
        return WaitlistEntryStatus.waiting;
      case 'Promoted':
        return WaitlistEntryStatus.promoted;
      case 'Expired':
        return WaitlistEntryStatus.expired;
      case 'Cancelled':
        return WaitlistEntryStatus.cancelled;
      default:
        return WaitlistEntryStatus.waiting;
    }
  }
}

/// 1 entry trong waitlist của tournament.
///
/// Backend `GET /tournaments/{id}/waitlist` trả về list các entry này
/// (kèm `position`, `joinedAt`, `karmaScore`, `elo`). Khi user join sẽ
/// nhận được 1 entry riêng từ `POST /waitlist`.
class TournamentWaitlistEntry extends Equatable {
  /// ID entry. Có thể null ở các response chỉ liệt kê (vd danh sách
  /// public) — khi đó UI không cần thao tác leave/confirm/decline.
  final String? id;

  final String tournamentId;
  final String tournamentName;

  final String userId;
  final String username;

  /// Vị trí trong hàng chờ (1 = đầu tiên).
  final int position;

  final DateTime joinedAt;

  /// Karma + Elo snapshot lúc join (tùy response).
  final int? karmaScore;
  final int? elo;

  /// Status — luôn có ở danh sách, optional ở endpoint `me`.
  final WaitlistEntryStatus status;

  /// Deadline phản hồi offer (nếu backend cung cấp) — chỉ có ở
  /// endpoint `/me` khi user đang `Promoted` (cần confirm).
  final DateTime? promotionDeadline;

  const TournamentWaitlistEntry({
    this.id,
    required this.tournamentId,
    required this.tournamentName,
    required this.userId,
    required this.username,
    required this.position,
    required this.joinedAt,
    this.karmaScore,
    this.elo,
    this.status = WaitlistEntryStatus.waiting,
    this.promotionDeadline,
  });

  @override
  List<Object?> get props => [
        id,
        tournamentId,
        tournamentName,
        userId,
        username,
        position,
        joinedAt,
        karmaScore,
        elo,
        status,
        promotionDeadline,
      ];
}

/// Trạng thái waitlist của user hiện tại (cho `/me` endpoint).
///
/// Khi chưa join: [isInWaitlist] = false và tất cả field khác null.
class MyWaitlistStatus extends Equatable {
  final bool isInWaitlist;

  /// ID entry waitlist (dùng cho leave/confirm/decline).
  final String? entryId;

  final int? position;
  final WaitlistEntryStatus? status;
  final DateTime? joinedAt;
  final DateTime? promotionDeadline;

  final String? tournamentId;
  final String? tournamentName;

  const MyWaitlistStatus({
    required this.isInWaitlist,
    this.entryId,
    this.position,
    this.status,
    this.joinedAt,
    this.promotionDeadline,
    this.tournamentId,
    this.tournamentName,
  });

  /// Convenience: khi đang `Waiting` và có offer cần confirm.
  bool get hasPendingOffer =>
      status == WaitlistEntryStatus.promoted &&
      promotionDeadline != null;

  @override
  List<Object?> get props => [
        isInWaitlist,
        entryId,
        position,
        status,
        joinedAt,
        promotionDeadline,
        tournamentId,
        tournamentName,
      ];
}

/// Response trả về khi join waitlist thành công (`POST /waitlist`).
///
/// Trùng schema với [TournamentWaitlistEntry] nhưng là response wrapper —
/// giữ riêng để dễ mở rộng (vd thêm `expiresAt`, `noticeSentAt`).
class JoinWaitlistResult extends Equatable {
  final String waitlistEntryId;
  final String tournamentId;
  final String tournamentName;
  final String userId;
  final String username;
  final int position;
  final DateTime joinedAt;
  final WaitlistEntryStatus status;

  const JoinWaitlistResult({
    required this.waitlistEntryId,
    required this.tournamentId,
    required this.tournamentName,
    required this.userId,
    required this.username,
    required this.position,
    required this.joinedAt,
    required this.status,
  });

  @override
  List<Object?> get props => [
        waitlistEntryId,
        tournamentId,
        tournamentName,
        userId,
        username,
        position,
        joinedAt,
        status,
      ];
}

/// Response confirm/decline — backend chỉ trả 3 field.
class WaitlistActionResult extends Equatable {
  final String waitlistEntryId;
  final String tournamentId;
  final WaitlistEntryStatus status;

  const WaitlistActionResult({
    required this.waitlistEntryId,
    required this.tournamentId,
    required this.status,
  });

  @override
  List<Object?> get props => [waitlistEntryId, tournamentId, status];
}