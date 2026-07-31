import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_invite_entity.dart';
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
  /// POST /api/v1/lobbies — tạo lobby mới.
  /// Body theo spec `lobby.md` và Swagger `CreateLobbyRequestDto`:
  /// ```json
  /// {
  ///   "gameTemplateId": "uuid",
  ///   "scheduledStartTime": "ISO-8601 UTC",
  ///   "maxMembers": 2..20,
  ///   "seatCount": 1..50,
  ///   "cancellationLeadTimeMinutes": 5..1440,
  ///   "isPrivate": false,
  ///   "cafeId": "uuid"  // optional — gắn lobby với quán cụ thể
  /// }
  /// ```
  /// Tham số `searchRadiusKm` và `minimumKarma` vẫn là client-only (BR-10
  /// áp dụng trên join/search, không phải lúc tạo).
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  });

  /// POST /api/v1/lobbies/{lobbyId}/join
  Future<Either<Failure, bool>> joinLobby(String lobbyId, String? inviteCode);

  /// POST /api/v1/lobbies/{lobbyId}/leave
  Future<Either<Failure, void>> leaveLobby(String lobbyId);

  /// GET /api/v1/lobbies/{lobbyId}
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId);

  /// POST /api/v1/lobbies/search — body chứa gameTemplateId, location,
  /// radius và minKarmaScore (xem spec `lobby.md:138-152`).
  /// Trả về danh sách summary (không kèm danh sách members đầy đủ).
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
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
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    int limit = 50,
  });

  /// POST /api/v1/lobbies/{lobbyId}/close — Host only.
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/lock — Host only.
  /// Status chuyển Open → Full, broadcast `LobbyFull`.
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/open-karma-window — Host only.
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId);

  /// POST /api/v1/lobbies/{lobbyId}/auto-booking — chỉ mock (server-
  /// side sẽ tự trigger sau khi `LobbyFull` event; client không gọi
  /// trừ khi mock). Giữ lại để tương thích `LobbyRepository` cũ.
  Future<Either<Failure, String>> autoCreateBooking(String lobbyId);

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
    required String memberId,
  });

  /// POST /api/v1/lobbies/{lobbyId}/ready
  /// Member bấm Ready/Unready khi lobby FULL.
  Future<Either<Failure, LobbyEntity>> setReady(String lobbyId);

  /// GET /api/v1/lobbies/hosted
  /// Lấy danh sách lobby do user này host (cả active lẫn đã đóng).
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies();

  /// GET /api/v1/lobbies/joined
  /// Lấy danh sách lobby mà user đang tham gia.
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies();

  /// POST /api/v1/lobbies/{lobbyId}/report
  /// Báo cáo phòng chờ vi phạm.
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String reason,
    String? description,
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
