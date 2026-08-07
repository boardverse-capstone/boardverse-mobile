import 'package:equatable/equatable.dart';

/// Trạng thái của lời mời tham gia lobby.
enum LobbyInviteStatus {
  /// Lời mời đang chờ được chấp nhận hoặc từ chối.
  pending,

  /// Người được mời đã chấp nhận (auto-join lobby).
  accepted,

  /// Người được mời đã từ chối.
  declined,

  /// Người gửi đã hủy lời mời.
  cancelled,

  /// Lời mời đã hết hạn (>24h hoặc lobby đóng).
  expired;

  /// Chuyển từ string (API response) sang enum.
  static LobbyInviteStatus fromString(String? value) {
    if (value == null) return LobbyInviteStatus.pending;
    final normalized = value.toLowerCase().trim();
    for (final status in LobbyInviteStatus.values) {
      if (status.name == normalized) return status;
    }
    return LobbyInviteStatus.pending;
  }
}

/// Entity đại diện cho một lời mời tham gia lobby.
class LobbyInviteEntity extends Equatable {
  /// ID của lời mời.
  final String inviteId;

  /// ID của lobby được mời tham gia.
  final String lobbyId;

  /// Tên lobby (server trả về trong DTO mới).
  final String? lobbyName;

  /// ID của người gửi lời mời.
  final String inviterId;

  /// Username người gửi (server DTO `inviterUsername`).
  final String? inviterUsername;

  /// Tên hiển thị người gửi — alias cũ tương thích với DTO cũ
  /// (`inviter.name` hoặc fallback `inviterUsername`).
  final String inviterName;

  /// Avatar URL của người gửi lời mời.
  final String inviterAvatar;

  /// ID của người được mời.
  final String inviteeId;

  /// Username người được mời (server DTO `inviteeUsername`).
  final String? inviteeUsername;

  /// Lời nhắn kèm theo (nếu có).
  final String? message;

  /// Trạng thái hiện tại của lời mời.
  final LobbyInviteStatus status;

  /// Thời điểm tạo lời mời.
  final DateTime createdAt;

  /// Thời điểm lời mời hết hạn (24h sau khi gửi).
  final DateTime expiresAt;

  /// Thời điểm invitee accept/decline (server DTO `respondedAt`).
  /// Null nếu chưa phản hồi.
  final DateTime? respondedAt;

  /// Tên game của lobby.
  final String gameName;

  /// Tên cafe của lobby.
  final String cafeName;

  /// Số người hiện tại trong lobby.
  final int currentMembers;

  /// Số người tối đa của lobby.
  final int maxMembers;

  const LobbyInviteEntity({
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
    required this.gameName,
    required this.cafeName,
    required this.currentMembers,
    required this.maxMembers,
  });

  /// Kiểm tra lời mời có đang active (pending và chưa hết hạn).
  bool get isActive =>
      status == LobbyInviteStatus.pending &&
      DateTime.now().isBefore(expiresAt);

  /// Lời mời đã ở trạng thái terminal → có thể resend.
  bool get canResend =>
      status == LobbyInviteStatus.declined ||
      status == LobbyInviteStatus.expired ||
      status == LobbyInviteStatus.cancelled;

  /// Khoảng thời gian còn lại trước khi hết hạn.
  Duration get remainingTime => expiresAt.difference(DateTime.now());

  /// Số slot còn trống trong lobby.
  int get slotsRemaining => maxMembers - currentMembers;

  /// Lobby có còn chỗ không.
  bool get hasSlots => currentMembers < maxMembers;

  @override
  List<Object?> get props => [
    inviteId,
    lobbyId,
    lobbyName,
    inviterId,
    inviterUsername,
    inviterName,
    inviterAvatar,
    inviteeId,
    inviteeUsername,
    message,
    status,
    createdAt,
    expiresAt,
    respondedAt,
    gameName,
    cafeName,
    currentMembers,
    maxMembers,
  ];
}
