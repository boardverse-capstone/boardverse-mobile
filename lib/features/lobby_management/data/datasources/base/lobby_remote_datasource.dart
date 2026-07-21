import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_summary.dart';

/// Abstraction cho tầng Data của Lobby — tách khỏi [LobbyRepository] (domain).
///
/// Hai implementation sẽ implement interface này:
/// - `MockLobbyRemoteDatasource` (in-memory store + simulated realtime)
/// - `RealLobbyRemoteDatasource` (gọi REST backend + SignalR Hub)
///
/// Việc switch tuân theo `AppConfig.useMockLobbyData` ở tầng DI.
abstract class LobbyRemoteDatasource {
  /// POST /api/v1/lobbies — tạo lobby mới.
  /// Body theo spec `lobby.md`:
  /// ```json
  /// {
  ///   "gameTemplateId": "uuid",
  ///   "scheduledStartTime": "ISO-8601 UTC",
  ///   "maxMembers": 2..4,
  ///   "cancellationLeadTimeMinutes": 30
  /// }
  /// ```
  /// Tham số bổ sung (`searchRadiusKm`, `minimumKarma`, `isPublic`, ...)
  /// mang tính client-only và sẽ bị bỏ qua ở backend — giữ lại trong
  /// interface để không vỡ Cubit hiện tại.
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

  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId);

  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends();
}
