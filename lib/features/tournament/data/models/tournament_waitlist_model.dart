import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';

/// Model cho các endpoint T-03 Tournament Waitlist.
///
/// Lưu ý: backend trả về nhiều shape khác nhau tùy endpoint — `POST /waitlist`
/// trả entry với `waitlistEntryId`, `GET /waitlist` trả list entry thuần
/// (không có `id`), `GET /waitlist/me` trả wrapper [MyWaitlistStatus],
/// `POST /waitlist/confirm|decline` trả [WaitlistActionResult] rút gọn.
///
/// Model này parse tất cả — từng `fromJson` factory sẽ tự tolerate field
/// optional theo endpoint tương ứng.
class TournamentWaitlistModel {
  final String? waitlistEntryId;
  final String? id;
  final String tournamentId;
  final String? tournamentName;
  final String userId;
  final String? username;
  final int position;
  final DateTime joinedAt;
  final int? karmaScore;
  final int? elo;
  final String? status;
  final DateTime? promotionDeadline;

  const TournamentWaitlistModel({
    this.waitlistEntryId,
    this.id,
    required this.tournamentId,
    this.tournamentName,
    required this.userId,
    this.username,
    required this.position,
    required this.joinedAt,
    this.karmaScore,
    this.elo,
    this.status,
    this.promotionDeadline,
  });

  /// Parse từ entry bất kỳ (POST /waitlist response, list item, etc.).
  /// Tolerant với nhiều alias field (`id` vs `waitlistEntryId`,
  /// `tournamentName` vs `tournamentTitle`, ...).
  factory TournamentWaitlistModel.fromJson(Map<String, dynamic> json) {
    final id = json['waitlistEntryId'] as String? ?? json['id'] as String?;
    final tournamentName =
        (json['tournamentName'] ?? json['tournamentTitle']) as String?;
    final userName = (json['username'] ?? json['userName']) as String?;
    final joinedAtRaw = json['joinedAt'] as String?;
    final promotionRaw = json['promotionDeadline'] as String?;

    return TournamentWaitlistModel(
      waitlistEntryId: id,
      id: id,
      tournamentId: (json['tournamentId'] as String?) ?? '',
      tournamentName: tournamentName,
      userId: (json['userId'] as String?) ?? '',
      username: userName,
      position: (json['position'] as int?) ?? 0,
      joinedAt: joinedAtRaw != null
          ? DateTime.tryParse(joinedAtRaw) ?? DateTime.now()
          : DateTime.now(),
      karmaScore: json['karmaScore'] as int?,
      elo: json['elo'] as int?,
      status: json['status'] as String?,
      promotionDeadline: promotionRaw != null
          ? DateTime.tryParse(promotionRaw)
          : null,
    );
  }

  TournamentWaitlistEntry toEntity({
    required String fallbackTournamentName,
  }) {
    return TournamentWaitlistEntry(
      id: id ?? waitlistEntryId,
      tournamentId: tournamentId,
      tournamentName: tournamentName ?? fallbackTournamentName,
      userId: userId,
      username: username ?? 'Unknown',
      position: position,
      joinedAt: joinedAt,
      karmaScore: karmaScore,
      elo: elo,
      status: WaitlistEntryStatusX.fromApi(status),
      promotionDeadline: promotionDeadline,
    );
  }
}

/// Model cho wrapper `GET /waitlist/me`.
class MyWaitlistStatusModel {
  final bool isInWaitlist;
  final String? entryId;
  final int? position;
  final String? status;
  final DateTime? joinedAt;
  final DateTime? promotionDeadline;
  final String? tournamentId;
  final String? tournamentName;

  const MyWaitlistStatusModel({
    required this.isInWaitlist,
    this.entryId,
    this.position,
    this.status,
    this.joinedAt,
    this.promotionDeadline,
    this.tournamentId,
    this.tournamentName,
  });

  factory MyWaitlistStatusModel.fromJson(Map<String, dynamic> json) {
    final joinedRaw = json['joinedAt'] as String?;
    final promoRaw = json['promotionDeadline'] as String?;
    return MyWaitlistStatusModel(
      isInWaitlist: json['isInWaitlist'] as bool? ?? false,
      entryId: json['waitlistEntryId'] as String?,
      position: json['position'] as int?,
      status: json['status'] as String?,
      joinedAt:
          joinedRaw != null ? DateTime.tryParse(joinedRaw) : null,
      promotionDeadline:
          promoRaw != null ? DateTime.tryParse(promoRaw) : null,
      tournamentId: json['tournamentId'] as String?,
      tournamentName:
        (json['tournamentName'] ?? json['tournamentTitle']) as String?,
    );
  }

  MyWaitlistStatus toEntity() => MyWaitlistStatus(
        isInWaitlist: isInWaitlist,
        entryId: entryId,
        position: position,
        status: status != null
            ? WaitlistEntryStatusX.fromApi(status)
            : null,
        joinedAt: joinedAt,
        promotionDeadline: promotionDeadline,
        tournamentId: tournamentId,
        tournamentName: tournamentName,
      );
}

/// Model cho `POST /waitlist/confirm|decline` — response rút gọn.
class WaitlistActionResultModel {
  final String waitlistEntryId;
  final String tournamentId;
  final String? status;

  const WaitlistActionResultModel({
    required this.waitlistEntryId,
    required this.tournamentId,
    this.status,
  });

  factory WaitlistActionResultModel.fromJson(Map<String, dynamic> json) {
    return WaitlistActionResultModel(
      waitlistEntryId: (json['waitlistEntryId'] as String?) ?? '',
      tournamentId: (json['tournamentId'] as String?) ?? '',
      status: json['status'] as String?,
    );
  }

  WaitlistActionResult toEntity() => WaitlistActionResult(
        waitlistEntryId: waitlistEntryId,
        tournamentId: tournamentId,
        status: WaitlistEntryStatusX.fromApi(status),
      );
}