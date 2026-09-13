import '../../domain/entities/session_history_entity.dart';

/// Model for GET /api/v1/sessions/me/history response
class SessionHistoryResponseModel {
  final List<SessionHistoryItemModel> items;

  const SessionHistoryResponseModel({
    required this.items,
  });

  factory SessionHistoryResponseModel.fromJson(Map<String, dynamic> json) {
    return SessionHistoryResponseModel(
      items: (json['data'] as List?)
              ?.map((e) => SessionHistoryItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Single session history item
class SessionHistoryItemModel {
  final String sessionId;
  final String cafeName;
  final String cafeId;
  final String? lobbyId;
  final String gameName;
  final String sessionStatus;
  final DateTime joinedAt;
  final DateTime joinedAtOffset;
  final DateTime? paidAt;
  final DateTime? paidAtOffset;
  final int totalMinutesPlayed;
  final int totalAmountDue;
  final String memberStatus;
  final String currency;

  const SessionHistoryItemModel({
    required this.sessionId,
    required this.cafeName,
    required this.cafeId,
    this.lobbyId,
    required this.gameName,
    required this.sessionStatus,
    required this.joinedAt,
    required this.joinedAtOffset,
    this.paidAt,
    this.paidAtOffset,
    required this.totalMinutesPlayed,
    required this.totalAmountDue,
    required this.memberStatus,
    required this.currency,
  });

  factory SessionHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return SessionHistoryItemModel(
      sessionId: json['sessionId'] as String,
      cafeName: json['cafeName'] as String,
      cafeId: json['cafeId'] as String,
      lobbyId: json['lobbyId'] as String?,
      gameName: json['gameName'] as String,
      sessionStatus: json['sessionStatus'] as String? ?? '',
      joinedAt: DateTime.parse(json['joinedAt'] as String),
      joinedAtOffset: DateTime.parse(json['joinedAtOffset'] as String),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      paidAtOffset: json['paidAtOffset'] != null
          ? DateTime.parse(json['paidAtOffset'] as String)
          : null,
      totalMinutesPlayed: (json['totalMinutesPlayed'] as num?)?.toInt() ?? 0,
      totalAmountDue: (json['totalAmountDue'] as num?)?.toInt() ?? 0,
      memberStatus: json['memberStatus'] as String? ?? '',
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'cafeName': cafeName,
      'cafeId': cafeId,
      'lobbyId': lobbyId,
      'gameName': gameName,
      'sessionStatus': sessionStatus,
      'joinedAt': joinedAt.toIso8601String(),
      'joinedAtOffset': joinedAtOffset.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'paidAtOffset': paidAtOffset?.toIso8601String(),
      'totalMinutesPlayed': totalMinutesPlayed,
      'totalAmountDue': totalAmountDue,
      'memberStatus': memberStatus,
      'currency': currency,
    };
  }

  SessionHistoryEntity toEntity() => SessionHistoryEntity(
        sessionId: sessionId,
        cafeName: cafeName,
        cafeId: cafeId,
        lobbyId: lobbyId,
        gameName: gameName,
        sessionStatus: sessionStatus,
        joinedAt: joinedAt,
        joinedAtOffset: joinedAtOffset,
        paidAt: paidAt,
        paidAtOffset: paidAtOffset,
        totalMinutesPlayed: totalMinutesPlayed,
        totalAmountDue: totalAmountDue,
        memberStatus: memberStatus,
        currency: currency,
      );
}
