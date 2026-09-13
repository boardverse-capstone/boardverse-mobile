import 'package:dartz/dartz.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_invite_entity.dart';
import '../../domain/entities/lobby_invitable_friend.dart';
import '../../domain/entities/lobby_share_info.dart';
import '../../domain/entities/lobby_summary.dart';
import '../../domain/entities/lobby_chat_message.dart';

abstract class LobbyRepository {
  /// Legacy `createLobby` / `createLobbyForExistingBooking` /
  /// `autoCreateBookingWhenFull` đã bị xoá theo plan migrate Lobby sang
  /// Reservation/BVC. Lobby giờ được tạo nguyên tử qua
  /// `ReservationCubit.confirmReservation()`.

  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId);

  Future<Either<Failure, bool>> joinLobby(String lobbyId, String? inviteCode);

  Future<Either<Failure, void>> leaveLobby(String lobbyId);

  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId);

  // ─── Lobby Invites & Share Code (BR-LOBBY-INVITE-*) ─────────────────

  /// POST /api/v1/lobbies/{lobbyId}/invites — Gửi lời mời cho 1 user.
  /// [message] optional, tối đa 300 ký tự.
  Future<Either<Failure, void>> sendLobbyInvite({
    required String lobbyId,
    required String inviteeId,
    String? message,
  });

  /// GET /api/v1/lobbies/{lobbyId}/invites
  /// Lấy lịch sử invite của lobby, optional filter theo status.
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  });

  /// POST /api/v1/lobbies/invites/{inviteId}/resend
  /// Gửi lại invite đã ở terminal state.
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(String inviteId);

  /// GET /api/v1/lobbies/{lobbyId}/invitable-friends
  /// Lấy danh sách friend kèm trạng thái invite (server-side tính).
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  });

  /// GET /api/v1/lobbies/invites/me/pending — Inbox lời mời đang chờ
  /// (status = Pending, chưa hết hạn).
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingLobbyInvites();

  /// GET /api/v1/lobbies/invites/me?status={status}
  /// Lấy tất cả lời mời với filter status (optional).
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllLobbyInvites({
    LobbyInviteStatus? status,
  });

  /// POST /api/v1/lobbies/invites/{inviteId}/accept — Accept lời mời
  /// (tự động join lobby). Trả về LobbyEntity mới.
  Future<Either<Failure, LobbyEntity>> acceptLobbyInvite(String inviteId);

  /// POST /api/v1/lobbies/invites/{inviteId}/decline — Từ chối lời mời.
  Future<Either<Failure, void>> declineLobbyInvite(String inviteId);

  /// DELETE /api/v1/lobbies/invites/{inviteId} — Inviter hủy lời mời
  /// đã gửi.
  Future<Either<Failure, void>> cancelLobbyInvite(String inviteId);

  /// GET /api/v1/lobbies/{lobbyId}/share-info — Lấy share code của lobby
  /// (chỉ member mới xem được).
  Future<Either<Failure, LobbyShareInfo>> getLobbyShareInfo(String lobbyId);

  /// POST /api/v1/lobbies/join-by-code — Join lobby bằng share code.
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(String shareCode);

  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends();

  /// Realtime stream — phát lobby mỗi lần có thay đổi (join/leave/status/...).
  /// Đống dữ liệu mock nên tự động mô phỏng join mỗi ~5s.
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId);

  Future<Either<Failure, void>> cancelLobby(String lobbyId, String reasonCode);

  /// Host-only: đóng phòng thủ công (`POST /api/v1/lobbies/{id}/close`).
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId);

  /// Host-only: đổi giờ lobby (`POST /api/v1/lobbies/{id}/change-time`).
  /// BR-NEW-15 (2026-08-18): body chỉ nhận `preferredStartTime` /
  /// `preferredEndTime` (HH:mm:ss) — `null` = giữ nguyên.
  Future<Either<Failure, LobbyEntity>> changeLobbyTime({
    required String lobbyId,
    String? preferredStartTime,
    String? preferredEndTime,
  });

  /// Host giải tán lobby (hard delete toàn bộ records).
  /// `DELETE /api/v1/lobbies/{lobbyId}`.
  ///
  /// Khác với `closeLobby`: endpoint này xoá vĩnh viễn lobby khỏi DB.
  /// Chỉ áp dụng khi lobby chưa booking thành công. Backend trả 409 nếu
  /// lobby đã đặt cọc hoặc đang trong phiên chơi.
  ///
  /// Body (optional): { reason: "string" }
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  });

  /// Host-only: khoá phòng để chuyển sang flow booking
  /// (`POST /api/v1/lobbies/{id}/lock`). Status: Open → Full.
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId);

  /// Host-only: mở cửa sổ đánh giá Karma sau khi POS thanh toán xong
  /// (`POST /api/v1/lobbies/{id}/open-karma-window`).
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId);

  /// Stream raw [LobbyRealtimeEvent] cho 1 lobby — Cubit dùng để xử lý
  /// các event đặc biệt (timeout, host cancelled, booking confirmed)
  /// độc lập với việc fetch lại state.
  Stream<LobbyRealtimeEvent> watchLobbyEvents(String lobbyId);

  // ─── Mới cho Task 3 ─────────────────────────────────────────────────

  /// Tìm các lobby khả dụng quanh [latitude]/[longitude] áp dụng BR-10 filter.
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
    bool excludeSelfOverlapping = true,
  });

  /// GET /api/v1/lobbies/discoverable — Browse lobbies cho Player.
  /// Trả về `List<LobbyEntity>` đầy đủ thông tin (không phải summary).
  /// Server đã filter theo vị trí + visibility + status open/full.
  /// Không yêu cầu `gameTemplateId`, phù hợp cho flow "xem tất cả
  /// phòng chờ đang hoạt động" ở Discovery tab.
  ///
  /// Hỗ trợ filter optional theo `gameTemplateId`, `latitude/longitude/radiusKm`.
  /// [excludeSelfOverlapping] = true để server loại lobby trùng lịch với
  /// reservation của user hiện tại.
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  });

  /// Đổi trạng thái lobby (timeoutFailed / hostCancelled / full / ...).
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  );

  // ─── Host Actions ─────────────────────────────────────────────────

  /// POST /api/v1/lobbies/{lobbyId}/transfer-host
  /// Host chuyển quyền host cho thành viên khác.
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  });

  /// POST /api/v1/lobbies/{lobbyId}/kick
  /// Host kick thành viên khỏi lobby.
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  });

  /// POST /api/v1/lobbies/{lobbyId}/ready
  /// Member bấm Ready/Unready khi lobby FULL.
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  });

  /// PATCH /api/v1/lobbies/{lobbyId}
  /// Host cập nhật thông tin lobby (description, maxMembers, isPrivate, minKarmaScore).
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  });

  // ─── Lobby Lists ─────────────────────────────────────────────────

  /// GET /api/v1/lobbies/hosted
  /// Lấy danh sách lobby do user này host.
  ///
  /// **Deprecated (BVC v2)**: Ưu tiên dùng [getMyLobbies] — endpoint mới
  /// hợp nhất hosted + joined trong 1 response, đồng thời tự filter theo
  /// BR-MEMBER-CLEANUP-01 (chỉ trả lobby còn active).
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies();

  /// GET /api/v1/lobbies/joined
  /// Lấy danh sách lobby mà user đang tham gia.
  ///
  /// **Deprecated (BVC v2)**: Ưu tiên dùng [getMyLobbies].
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies();

  /// GET /api/v1/lobbies/my
  /// Trả về cả hosted + joined của user hiện tại trong cùng 1 response.
  /// Backend tự filter theo BR-MEMBER-CLEANUP-01:
  /// - Chỉ trả lobby có status thuộc active set:
  ///   `PendingActivation`, `PendingCafeApproval`, `Open`, `Viable`,
  ///   `Full`, `InProgress`, `RatingOpen`.
  /// - Lobby đã terminal (`Closed`, `TimeoutFailed`, `HostCancelled`,
  ///   `RejectedByCafe`, `ExpiredByCafe`, `Dissolved`) → tự động set
  ///   `IsActive=false` cho member rows → không xuất hiện trong list.
  ///
  /// Spec: `lobby.md` §Lobby listing endpoints + BR-MEMBER-CLEANUP-01.
  Future<Either<Failure, List<LobbyEntity>>> getMyLobbies();

  // ─── Lobby Social ─────────────────────────────────────────────────

  /// POST /api/v1/lobbies/{lobbyId}/report
  /// Báo cáo phòng chờ vi phạm.
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  });

  /// POST /api/v1/lobbies/{lobbyId}/messages
  /// Gửi tin nhắn chat trong lobby.
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  });

  /// GET /api/v1/lobbies/{lobbyId}/messages
  /// Lấy lịch sử chat trong lobby (cursor pagination).
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  });

  // ─── Dev simulation ─────────────────────────────────────────────────

  /// Mô phỏng thêm friend vào lobby (chỉ dev mode).
  /// Trả về lobby đã cập nhật; Left nếu lobby không tồn tại hoặc đã đầy.
  Future<Either<Failure, LobbyEntity>> simulateAddFriend({
    required String lobbyId,
    required String friendId,
  });
}
