import '../../domain/entities/lobby_invite_entity.dart';

/// Model cho API response của lobby invite.
class LobbyInviteModel {
  final String inviteId;
  final String lobbyId;
  final String inviterId;
  final String inviterName;
  final String inviterAvatar;
  final String inviteeId;
  final String? message;
  final LobbyInviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String gameName;
  final String cafeName;
  final int currentMembers;
  final int maxMembers;

  const LobbyInviteModel({
    required this.inviteId,
    required this.lobbyId,
    required this.inviterId,
    required this.inviterName,
    required this.inviterAvatar,
    required this.inviteeId,
    this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.gameName,
    required this.cafeName,
    required this.currentMembers,
    required this.maxMembers,
  });

  factory LobbyInviteModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.parse(v.toString());
    }

    return LobbyInviteModel(
      inviteId: (json['inviteId'] ?? json['id'] ?? '').toString(),
      lobbyId: (json['lobbyId'] ?? '').toString(),
      inviterId: (json['inviter']?['userId'] ?? json['inviterId'] ?? '').toString(),
      inviterName: (json['inviter']?['username'] ?? json['inviterName'] ?? 'Người dùng').toString(),
      inviterAvatar: (json['inviter']?['avatarUrl'] ?? json['inviterAvatar'] ?? '').toString(),
      inviteeId: (json['invitee']?['userId'] ?? json['inviteeId'] ?? '').toString(),
      message: json['message'] as String?,
      status: LobbyInviteStatus.fromString(json['status'] as String?),
      createdAt: parseDate(json['createdAt'] ?? json['sentAt']),
      expiresAt: parseDate(json['expiresAt']),
      gameName: (json['lobby']?['gameName'] ?? json['gameName'] ?? 'Board Game').toString(),
      cafeName: (json['lobby']?['cafeName'] ?? json['cafeName'] ?? 'Quán').toString(),
      currentMembers: (json['lobby']?['currentMembers'] ?? json['currentPlayers'] ?? 1) as int,
      maxMembers: (json['lobby']?['maxMembers'] ?? json['maxPlayers'] ?? 4) as int,
    );
  }

  Map<String, dynamic> toJson() => {
    'inviteId': inviteId,
    'lobbyId': lobbyId,
    'inviterId': inviterId,
    'inviterName': inviterName,
    'inviterAvatar': inviterAvatar,
    'inviteeId': inviteeId,
    'message': message,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'gameName': gameName,
    'cafeName': cafeName,
    'currentMembers': currentMembers,
    'maxMembers': maxMembers,
  };

  LobbyInviteEntity toEntity() => LobbyInviteEntity(
    inviteId: inviteId,
    lobbyId: lobbyId,
    inviterId: inviterId,
    inviterName: inviterName,
    inviterAvatar: inviterAvatar,
    inviteeId: inviteeId,
    message: message,
    status: status,
    createdAt: createdAt,
    expiresAt: expiresAt,
    gameName: gameName,
    cafeName: cafeName,
    currentMembers: currentMembers,
    maxMembers: maxMembers,
  );
}
