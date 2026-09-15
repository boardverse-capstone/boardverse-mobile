import 'package:dartz/dartz.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_invite_entity.dart';
import '../../../domain/entities/lobby_invitable_friend.dart';
import '../../../domain/entities/lobby_share_info.dart';
import '../../../domain/entities/lobby_summary.dart';
import '../../../domain/entities/lobby_chat_message.dart';
import '../../../domain/entities/match_result_entity.dart';
import '../../models/elo_update_model.dart';

/// Abstraction cho tầng Data của Lobby — tách khỏi [LobbyRepository] (domain).
///
/// Hai implementation sẽ implement interface này:
/// - `MockLobbyRemoteDatasource` (in-memory store + simulated realtime)
/// - `RealLobbyRemoteDatasource` (gọi REST backend + SignalR Hub)
///
/// Việc switch tuân theo `AppConfig.useMockLobbyData` ở tầng DI.
abstract class LobbyRemoteDatasource {
  /// POST /api/v1/lobbies/{lobbyId}/join
  Future<Either<Failure, bool>> joinLobby(String lobbyId, String? inviteCode);

  /// POST /api/v1/lobbies/{lobbyId}/leave
  Future<Either<Failure, void>> leaveLobby(String lobbyId);

  /// GET /api/v1/lobbies/{lobbyId}
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId);

  /// POST /api/v1/lobbies/search — body chứa gameTemplateId, location,
  /// radius và minKarmaScore (xem spec `lobby.md:138-152`).
  /// Trả về danh sách summary (không kèm danh sách members đầy đủ).
  ///
  /// [excludeSelfOverlapping] = true để server loại bỏ các lobby có lịch
  /// trùng với reservation của user hiện tại.
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
    bool excludeSelfOverlapping = true,
  });

  /// GET /api/v1/lobbies/discoverable?limit=N — flow Browse lobbies cho
  /// Player. Server trả về các lobby đang hoạt động (`status = open|full`)
  /// đã được filter theo vị trí + visibility của user. **Không yêu cầu
  /// `gameTemplateId`** nên phù hợp cho tab "Phòng chờ".
  ///
  /// Trả về `List<LobbyEntity>` (đầy đủ thông tin) thay vì `LobbySummary`
  /// để caller có thể hiển thị Preview Page mà không cần gọi thêm
  /// `getLobbyById`. Lưu ý: response có field alias khác
  /// (`gameTemplateId` ↔ `gameId`, `memberAvatars[]` ↔ `players[]`, ...)
  /// — đã được xử lý trong `LobbyModel.fromJson`.
  ///
  /// [excludeSelfOverlapping] = true để server loại bỏ lobby trùng lịch
  /// với reservation của user hiện tại (BR: tránh join 2 lobby cùng giờ).
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  });

  /// POST /api/v1/lobbies/{lobbyId}/close — Host only.
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/change-time — Host only (BR-NEW-15).
  ///
  /// Body: `{ preferredStartTime?: "HH:mm:ss", preferredEndTime?: "HH:mm:ss" }`.
  /// Cả 2 field đều nullable — `null` = giữ nguyên giá trị cũ.
  /// Chỉ áp dụng khi lobby còn ở trạng thái cho phép
  /// (`Open`/`Viable`/`Full`/`PendingCafeApproval`). Sau khi host gọi
  /// thành công, server trả về lobby với `preferredStartTime` /
  /// `preferredEndTime` mới + recalculated `scheduledTime` + `timeoutAt`.
  Future<Either<Failure, LobbyEntity>> changeLobbyTime({
    required String lobbyId,
    String? preferredStartTime,
    String? preferredEndTime,
  });

  /// DELETE /api/v1/lobbies/{lobbyId} — Host giải tán lobby (hard delete).
  /// Hard-delete toàn bộ Lobby + Members + Messages + Invites + Reports.
  /// Chỉ host mới gọi. Không áp dụng khi lobby đã check-in hoặc
  /// đã đóng/rating. Backend trả 409 nếu lobby đã booking thành công.
  ///
  /// Body (optional): { reason: "string" }
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  });

  /// POST /api/v1/lobbies/{lobbyId}/lock — Host only.
  /// Status chuyển Open → Full, broadcast `LobbyFull`.
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/open-karma-window — Host only.
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/transfer-host
  /// Host chuyển quyền host cho thành viên khác.
  /// Body: { newHostUserId: "guid" }
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  });

  /// POST /api/v1/lobbies/{lobbyId}/kick
  /// Host kick thành viên khỏi lobby.
  /// Body: { targetUserId: "guid", reason: "..." }
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  });

  /// POST /api/v1/lobbies/{lobbyId}/ready
  /// Member bấm Ready/Unready khi lobby FULL.
  /// Body: { isReady: true }
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  });

  /// GET /api/v1/lobbies/hosted
  /// Lấy danh sách lobby do user này host (cả active lẫn đã đóng).
  ///
  /// **Deprecated (BVC v2)**: prefer [getMyLobbies].
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies();

  /// GET /api/v1/lobbies/joined
  /// Lấy danh sách lobby mà user đang tham gia.
  ///
  /// **Deprecated (BVC v2)**: prefer [getMyLobbies].
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies();

  /// GET /api/v1/lobbies/my
  ///
  /// **BR-NEW-MY-LOBBY-SORT (2026-09-14):** Backend bổ sung query params:
  /// - `statuses`: mảng int (enum value) — lọc theo LobbyStatus.
  /// - `statusFilter`: comma-separated string — vd "InProgress,Viable,Full".
  ///
  /// Backend tự sắp xếp kết quả: active statuses trước (InProgress,
  /// WaitingCheckIn, Viable, Full, Open, RatingOpen), rồi terminal
  /// statuses (Closed, TimeoutFailed, ...), trong mỗi nhóm sắp theo
  /// thời gian mới nhất.
  ///
  /// Nếu không truyền filter, backend trả tất cả (backend tự filter
  /// BR-MEMBER-CLEANUP-01 — chỉ lobby còn active).
  Future<Either<Failure, List<LobbyEntity>>> getMyLobbies({
    /// Danh sách int enum LobbyStatus cần lọc. VD: [0, 4, 14] = Open, InProgress, Viable.
    List<int>? statuses,

    /// Comma-separated LobbyStatus names. VD: "InProgress,Viable,Full".
    /// Backend sẽ union với `statuses` nếu cả 2 cùng truyền.
    String? statusFilter,
  });

  /// POST /api/v1/lobbies/{lobbyId}/report
  /// Báo cáo phòng chờ vi phạm.
  /// Body: { category: "Harassment", reason: "..." }
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  });

  /// PATCH /api/v1/lobbies/{lobbyId}
  /// Host cập nhật thông tin lobby (description, maxMembers, isPrivate, minKarmaScore).
  /// Tất cả field optional — chỉ field gửi mới được cập nhật.
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
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

  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId);

  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends();

  // ─── Share Code & Invite Methods ───────────────────────────────────────────

  /// GET /api/v1/lobbies/{lobbyId}/share-info
  /// Lấy thông tin share code của lobby.
  Future<Either<Failure, LobbyShareInfo>> getShareInfo(String lobbyId);

  /// POST /api/v1/lobbies/join-by-code
  /// Join lobby bằng share code.
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(String shareCode);

  /// GET /api/v1/lobbies/invites/me/pending
  /// Lấy danh sách lời mời đang chờ.
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingInvites();

  /// GET /api/v1/lobbies/invites/me?status={status}
  /// Lấy tất cả lời mời với filter status (optional).
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllInvites(LobbyInviteStatus? status);

  /// POST /api/v1/lobbies/invites/{inviteId}/accept
  /// Accept lời mời (tự động join lobby).
  Future<Either<Failure, LobbyEntity>> acceptInvite(String inviteId);

  /// POST /api/v1/lobbies/invites/{inviteId}/decline
  /// Decline lời mời.
  Future<Either<Failure, void>> declineInvite(String inviteId);

  /// DELETE /api/v1/lobbies/invites/{inviteId}
  /// Host hủy lời mời đã gửi.
  Future<Either<Failure, void>> cancelInvite(String inviteId);

  /// POST /api/v1/lobbies/{lobbyId}/invites
  /// Gửi lời mời tham gia lobby.
  Future<Either<Failure, void>> sendLobbyInvite(String lobbyId, String inviteeId, String? message);

  /// GET /api/v1/lobbies/{lobbyId}/invites
  /// Lấy lịch sử invite của lobby (Pending/Accepted/Declined/Expired/Cancelled).
  /// [status] optional filter. [limit] 1-200, default 100.
  /// Backend trả về `LobbyInviteResponseDto[]` sắp xếp theo CreatedAt desc.
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  });

  /// POST /api/v1/lobbies/invites/{inviteId}/resend
  /// Gửi lại invite đã ở terminal state (Declined/Expired/Cancelled).
  /// Trả về invite mới (Pending) với ExpiresAt mới = now + 24h.
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(String inviteId);

  /// GET /api/v1/lobbies/{lobbyId}/invitable-friends
  /// Lấy danh sách bạn bè kèm trạng thái invite (đã server-side tính).
  /// [search] case-insensitive contains username.
  /// [onlineOnly] chỉ Online/RecentlyActive.
  /// [minKarma] lọc bạn dưới ngưỡng.
  /// [statusFilter] danh sách [LobbyInviteFriendStatus] sẽ join thành
  /// comma-separated string (vd: `Invitable,InvitePending`).
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  });

  // ─── Match Results Methods ─────────────────────────────────────────────────

  /// GET /api/v1/matches/results/lobbies/{lobbyId}
  /// Lấy trạng thái đồng thuận kết quả trận đấu.
  Future<Either<Failure, MatchResultEntity>> getMatchResultStatus(String lobbyId);

  /// POST /api/v1/matches/results
  /// Submit kết quả trận đấu.
  Future<Either<Failure, MatchResultSubmitResponseModel>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  });

  /// Update lobby status (timeoutFailed / hostCancelled / ...).
  /// Note: Backend usually auto-transitions status; this is for special cases.
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  );
}
