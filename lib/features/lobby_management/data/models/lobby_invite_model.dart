import '../../domain/entities/lobby_invite_entity.dart';

/// Model cho API response của lobby invite.
class LobbyInviteModel {
  final String inviteId;
  final String lobbyId;
  final String? lobbyName;
  final String inviterId;
  final String? inviterUsername;
  final String inviterName;
  final String inviterAvatar;
  final String inviteeId;
  final String? inviteeUsername;
  final String? message;
  final LobbyInviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? respondedAt;
  final String? gameName;
  final String? cafeName;
  final int? currentMembers;
  final int? maxMembers;

  const LobbyInviteModel({
    required this.inviteId,
    required this.lobbyId,
    this.lobbyName,
    required this.inviterId,
    this.inviterUsername,
    required this.inviterName,
    required this.inviterAvatar,
    required this.inviteeId,
    this.inviteeUsername,
    this.message,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
    this.gameName,
    this.cafeName,
    this.currentMembers,
    this.maxMembers,
  });

  factory LobbyInviteModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      // Strip trailing 'Z' để parse thành local time thay vì UTC
      final s = v.toString();
      final normalized = s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
      return DateTime.parse(normalized);
    }

    // Server DTO mới (LobbyInviteResponseDto) trả về các field dạng
    // PascalCase + có sẵn `inviterUsername` / `inviteeUsername` /
    // `respondedAt`. Fallback về cấu trúc cũ (nested `inviter` object)
    // để tương thích ngược nếu backend chưa rollout.
    final rawInviterName = (json['inviter']?['username'] ??
            json['inviterUsername'] ??
            json['inviterName'] ??
            'Người dùng')
        .toString();
    final rawInviterId = (json['inviter']?['userId'] ??
            json['inviterId'] ??
            '')
        .toString();
    final rawInviterAvatar = (json['inviter']?['avatarUrl'] ??
            json['inviterAvatar'] ??
            '')
        .toString();

    return LobbyInviteModel(
      inviteId: (json['inviteId'] ?? json['id'] ?? '').toString(),
      lobbyId: (json['lobbyId'] ?? '').toString(),
      lobbyName: json['lobbyName']?.toString(),
      inviterId: rawInviterId,
      inviterUsername: json['inviterUsername']?.toString(),
      inviterName: rawInviterName,
      inviterAvatar: rawInviterAvatar,
      inviteeId: (json['invitee']?['userId'] ??
              json['inviteeId'] ??
              '')
          .toString(),
      inviteeUsername: json['inviteeUsername']?.toString(),
      message: json['message'] as String?,
      status: LobbyInviteStatus.fromString(json['status'] as String?),
      createdAt: parseDate(json['createdAt'] ?? json['sentAt']),
      expiresAt: parseDate(json['expiresAt']),
      respondedAt: json['respondedAt'] != null
          ? parseDate(json['respondedAt'])
          : null,
      // Game/cafe name + member counts được đọc từ nested `lobby` object
      // (DTO mới) hoặc root (DTO cũ). Trả về `null` nếu cả hai đều vắng
      // — tránh hiển thị "Board Game" / "Quán" / "1/4" fallback gây nhiễu
      // (BR-NEW-12). UI sẽ ẩn chip tương ứng khi field null.
      gameName: (json['lobby']?['gameName'] ?? json['gameName'])?.toString(),
      cafeName: (json['lobby']?['cafeName'] ?? json['cafeName'])?.toString(),
      currentMembers: json['lobby']?['currentMembers'] as int? ??
          json['currentPlayers'] as int?,
      maxMembers: json['lobby']?['maxMembers'] as int? ??
          json['maxPlayers'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
    'inviteId': inviteId,
    'lobbyId': lobbyId,
    'lobbyName': lobbyName,
    'inviterId': inviterId,
    'inviterUsername': inviterUsername,
    'inviterName': inviterName,
    'inviterAvatar': inviterAvatar,
    'inviteeId': inviteeId,
    'inviteeUsername': inviteeUsername,
    'message': message,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'respondedAt': respondedAt?.toIso8601String(),
    'gameName': gameName,
    'cafeName': cafeName,
    'currentMembers': currentMembers,
    'maxMembers': maxMembers,
  };

  LobbyInviteEntity toEntity() => LobbyInviteEntity(
    inviteId: inviteId,
    lobbyId: lobbyId,
    lobbyName: lobbyName,
    inviterId: inviterId,
    inviterUsername: inviterUsername,
    inviterName: inviterName,
    inviterAvatar: inviterAvatar,
    inviteeId: inviteeId,
    inviteeUsername: inviteeUsername,
    message: message,
    status: status,
    createdAt: createdAt,
    expiresAt: expiresAt,
    respondedAt: respondedAt,
    gameName: gameName,
    cafeName: cafeName,
    currentMembers: currentMembers,
    maxMembers: maxMembers,
  );
}
