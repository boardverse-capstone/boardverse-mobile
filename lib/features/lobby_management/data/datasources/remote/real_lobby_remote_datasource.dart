import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/constants/api_endpoints.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/friend_management/data/models/friend_model.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_invite_entity.dart';
import '../../../domain/entities/lobby_share_info.dart';
import '../../../domain/entities/lobby_summary.dart';
import '../../../domain/entities/match_result_entity.dart';
import '../../models/lobby_model.dart';
import '../../models/lobby_invite_model.dart';
import '../../models/lobby_share_info_model.dart';
import '../../models/match_result_model.dart';
import '../../models/elo_update_model.dart';
import '../base/lobby_remote_datasource.dart';

/// Triển khai gọi REST API thật theo spec `.agents/docs/apis_docs/lobby.md`.
///
/// Lưu ý mapping field:
/// - **client → server**: `createLobby` body đổi từ `gameId/cafeId/...` sang
///   `gameTemplateId/scheduledStartTime/maxMembers/cancellationLeadTimeMinutes`.
///   Backend ignore các field client-only (`isPublic`, `searchRadiusKm`, ...).
/// - **search**: chuyển từ GET query params → POST body theo spec.
/// - **response parsing**: dùng `LobbyModel.fromJson` hiện có (camelCase).
///   Nếu backend trả PascalCase cần thêm converter (xem plan §Câu hỏi 1).
///
/// Chỉ bind trong DI khi `AppConfig.useMockLobbyData = false`.
class RealLobbyRemoteDatasource implements LobbyRemoteDatasource {
  final Dio _dio;

  RealLobbyRemoteDatasource({required this._dio});

  // ════════════════════════════════════════════════════════════════════
  // Lobby CRUD
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    try {
      // Backend spec `lobby.md:48-56`:
      // {
      //   "gameTemplateId": "uuid",
      //   "scheduledStartTime": "ISO-8601 UTC",
      //   "maxMembers": 2..4,
      //   "cancellationLeadTimeMinutes": 30
      // }
      final body = <String, dynamic>{
        'gameTemplateId': gameId,
        'scheduledStartTime': scheduledTime.toUtc().toIso8601String(),
        'maxMembers': additionalSlots + 1,
        'cancellationLeadTimeMinutes': leadTime?.inMinutes ?? 30,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.lobbiesList,
        data: body,
      );
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyDetail.replaceAll('{id}', lobbyId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final raw = _unwrap(res.data);
      if (raw.isEmpty) return const Right<Failure, LobbyEntity?>(null);
      final model = LobbyModel.fromJson(raw);
      return Right<Failure, LobbyEntity?>(model.toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const Right<Failure, LobbyEntity?>(null);
      }
      return Left<Failure, LobbyEntity?>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity?>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LobbySummary>>> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    required LobbySearchFilter filter,
    required double currentUserKarma,
  }) async {
    try {
      // Backend spec `lobby.md:138-152` — POST body thay vì GET query.
      // `gameTemplateId` là REQUIRED ở spec; nếu client không truyền
      // (luồng "Tìm tất cả phòng gần bạn" từ Discovery tab) thì gửi
      // kèm latitude/longitude/radiusKm và KHÔNG gửi gameTemplateId
      // — server sẽ trả 400 nếu strict, ngược lại trả về list mixed.
      // Hiện tại spec strict: thiếu gameTemplateId → 400.
      final body = <String, dynamic>{
        if (filter.gameId != null) 'gameTemplateId': filter.gameId,
        if (filter.radiusKm != null) 'radiusKm': filter.radiusKm,
        if (filter.minKarma != null) 'minKarmaScore': filter.minKarma,
        // latitude/longitude luôn gửi nếu có.
        'latitude': latitude,
        'longitude': longitude,
      };
      final res = await _dio.post<List<dynamic>>(
        ApiEndpoints.lobbiesSearch,
        data: body,
      );
      final items = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(_summaryFromJson)
          .toList();
      return Right<Failure, List<LobbySummary>>(items);
    } on DioException catch (e) {
      return Left<Failure, List<LobbySummary>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbySummary>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LobbyEntity>>> discoverableLobbies({
    int limit = 50,
  }) async {
    try {
      // GET /api/v1/lobbies/discoverable?limit=N — flow Browse lobbies.
      // Server đã filter theo vị trí user + visibility, không cần gửi
      // location từ client. Pagination chỉ qua `limit` (mặc định 50).
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.lobbiesDiscoverable,
        queryParameters: {'limit': limit},
      );
      final items = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map((json) => LobbyModel.fromJson(json).toEntity())
          .toList();
      return Right<Failure, List<LobbyEntity>>(items);
    } on DioException catch (e) {
      return Left<Failure, List<LobbyEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Member actions
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, bool>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async {
    try {
      final path = ApiEndpoints.lobbyJoin.replaceAll('{id}', lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'inviteCode': ?inviteCode},
      );
      // 200 trả về LobbyResponseDto cập nhật — ta chỉ cần bool.
      return Right<Failure, bool>(res.statusCode == 200);
    } on DioException catch (e) {
      return Left<Failure, bool>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, bool>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyLeave.replaceAll('{id}', lobbyId);
      await _dio.post<dynamic>(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async {
    try {
      // Spec `lobby-invite.md`: gửi invite qua
      // `POST /api/v1/lobbies/{lobbyId}/invites` với body `{ inviteeId, message }`.
      // Method `sendLobbyInvite` đã implement đúng; ta delegate và bỏ
      // implementation cũ (POST lên `/api/v1/lobbies/{id}` với
      // `{action, friendId}`) vốn không match backend.
      return sendLobbyInvite(lobbyId, friendId, null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    try {
      // GET /api/v1/friends/activity — trả về FriendActivityDto[] (xem
      // friend.md). Lobby cần filter ra những bạn bè đang `Online` để
      // hiển thị trong sheet "Mời bạn bè vào phòng".
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.friendsActivity);
      final friends = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map((json) => FriendModel.fromJson(json).toEntity())
          .toList();
      // Chỉ trả về bạn bè đang online / recentlyActive để UI render
      // badge "online" hợp lý. Server có thể trả cả offline; client
      // filter để giảm noise trong sheet mời.
      return Right<Failure, List<FriendEntity>>(
        friends
            .where((f) =>
                f.activityStatus == ActivityStatus.online ||
                f.activityStatus == ActivityStatus.recentlyActive)
            .toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<FriendEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<FriendEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Host-only actions (BR-07/BR-08/Karma window)
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LobbyEntity>> closeLobby(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyClose.replaceAll('{id}', lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> lockLobby(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyLock.replaceAll('{id}', lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> openKarmaWindow(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyOpenKarmaWindow.replaceAll(
        '{id}',
        lobbyId,
      );
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> autoCreateBooking(String lobbyId) async {
    // backend lobby.md không expose endpoint này cho client — backend tự
    // trigger khi `LobbyFull` event. Method này chỉ dùng cho mock mode.
    // Nếu backend vẫn cung cấp endpoint nội bộ, xem
    // `ApiEndpoints.lobbyAutoBooking` (legacy) và điều chỉnh sau.
    return const Left<Failure, String>(
      ServerFailure(
        message:
            'autoCreateBooking không được expose trên real API — backend tự trigger.',
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // Share Code & Invite Methods
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LobbyShareInfo>> getShareInfo(String lobbyId) async {
    try {
      final path = ApiEndpoints.lobbyShareInfo.replaceAll('{lobbyId}', lobbyId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final model = LobbyShareInfoModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyShareInfo>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyShareInfo>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyShareInfo>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> joinLobbyByCode(String shareCode) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.lobbyJoinByCode,
        data: {'shareCode': shareCode},
      );
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getPendingInvites() async {
    try {
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.lobbyInvitesPending,
      );
      final items = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map((json) => LobbyInviteModel.fromJson(json).toEntity())
          .toList();
      return Right<Failure, List<LobbyInviteEntity>>(items);
    } on DioException catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getAllInvites(
    LobbyInviteStatus? status,
  ) async {
    try {
      final queryParams = status != null ? {'status': status.name} : <String, dynamic>{};
      final res = await _dio.get<List<dynamic>>(
        ApiEndpoints.lobbyInvitesMe,
        queryParameters: queryParams,
      );
      final items = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map((json) => LobbyInviteModel.fromJson(json).toEntity())
          .toList();
      return Right<Failure, List<LobbyInviteEntity>>(items);
    } on DioException catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> acceptInvite(String inviteId) async {
    try {
      final path = ApiEndpoints.lobbyInviteAccept.replaceAll('{inviteId}', inviteId);
      final res = await _dio.post<Map<String, dynamic>>(path);
      final model = LobbyModel.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> declineInvite(String inviteId) async {
    try {
      final path = ApiEndpoints.lobbyInviteDecline.replaceAll('{inviteId}', inviteId);
      await _dio.post<Map<String, dynamic>>(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> cancelInvite(String inviteId) async {
    try {
      final path = ApiEndpoints.lobbyInviteDetail.replaceAll('{inviteId}', inviteId);
      await _dio.delete<Map<String, dynamic>>(path);
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> sendLobbyInvite(
    String lobbyId,
    String inviteeId,
    String? message,
  ) async {
    try {
      final path = ApiEndpoints.lobbyInvites.replaceAll('{lobbyId}', lobbyId);
      await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'inviteeId': inviteeId,
          ...?message != null ? {'message': message} : null,
        },
      );
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // Match Results Methods
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, MatchResultEntity>> getMatchResultStatus(String lobbyId) async {
    try {
      final path = ApiEndpoints.matchResultByLobby.replaceAll('{lobbyId}', lobbyId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final model = MatchResultModel.fromJson(_unwrap(res.data));
      return Right<Failure, MatchResultEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, MatchResultEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, MatchResultEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, MatchResultSubmitResponseModel>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.matchResultsSubmit,
        data: {
          'lobbyId': lobbyId,
          'outcome': outcome.value,
        },
      );
      final model = MatchResultSubmitResponseModel.fromJson(_unwrap(res.data));
      return Right<Failure, MatchResultSubmitResponseModel>(model);
    } on DioException catch (e) {
      return Left<Failure, MatchResultSubmitResponseModel>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, MatchResultSubmitResponseModel>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Backend trả envelope `{ "data": { ... } }` (theo convention chung của
  /// team — verify qua response mẫu ở Phase 4).
  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return const <String, dynamic>{};
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  /// Map JSON đơn giản → LobbySummary (không kèm members).
  LobbySummary _summaryFromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) =>
        v == null ? DateTime.now() : DateTime.parse(v.toString());
    return LobbySummary(
      id: (json['id'] ?? json['lobbyId'] ?? '').toString(),
      gameId: (json['gameId'] ?? json['gameTemplateId'] ?? '').toString(),
      gameName: (json['gameName'] ?? '').toString(),
      gameImageUrl: (json['gameImageUrl'] ?? '').toString(),
      cafeId: (json['cafeId'] ?? '').toString(),
      cafeName: (json['cafeName'] ?? '').toString(),
      hostName: (json['hostName'] ?? '').toString(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      currentPlayers: (json['currentPlayers'] as num?)?.toInt() ?? 0,
      maxPlayers: (json['maxPlayers'] as num?)?.toInt() ?? 0,
      minPlayers: (json['minPlayers'] as num?)?.toInt() ?? 0,
      minimumKarma: (json['minimumKarma'] as num?)?.toDouble() ?? 0,
      scheduledTime: parseDate(
        json['scheduledTime'] ?? json['scheduledStartTime'],
      ),
      timeoutAt: parseDate(json['timeoutAt']),
      status: _parseStatus(json['status']),
      isPublic: json['isPublic'] as bool? ?? true,
    );
  }

  LobbyStatus _parseStatus(dynamic raw) {
    final s = raw?.toString().toLowerCase().trim() ?? 'open';
    switch (s) {
      case 'open':
        return LobbyStatus.open;
      case 'full':
        return LobbyStatus.full;
      case 'inprogress':
      case 'in_progress':
      case 'in-progress':
        return LobbyStatus.inProgress;
      case 'ratingopen':
      case 'rating_open':
      case 'rating-open':
        return LobbyStatus.ratingOpen;
      case 'closed':
        return LobbyStatus.closed;
      case 'timeoutfailed':
      case 'timeout_failed':
      case 'timeout-failed':
        return LobbyStatus.timeoutFailed;
      case 'hostcancelled':
      case 'host_cancelled':
      case 'host-cancelled':
        return LobbyStatus.hostCancelled;
      default:
        return LobbyStatus.open;
    }
  }

  @override
  Future<Either<Failure, LobbyEntity>> updateLobbyStatus(
    String lobbyId,
    LobbyStatus newStatus,
  ) async {
    try {
      final response = await _dio.post(
        '${ApiEndpoints.lobbiesList}/$lobbyId/status',
        data: {'status': newStatus.name},
      );
      final lobby = LobbyModel.fromJson(response.data as Map<String, dynamic>);
      return Right(lobby.toEntity());
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final apiMsg = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString()
        : null;
    switch (code) {
      case 400:
        return ServerFailure(
          message: apiMsg ?? 'Dữ liệu không hợp lệ',
          statusCode: code,
        );
      case 401:
        return ServerFailure(
          message: apiMsg ?? 'Phiên đăng nhập hết hạn',
          statusCode: code,
        );
      case 403:
        return ServerFailure(
          message: apiMsg ?? 'Không có quyền truy cập',
          statusCode: code,
        );
      case 404:
        return ServerFailure(
          message: apiMsg ?? 'Không tìm thấy phòng',
          statusCode: code,
        );
      case 409:
        return ServerFailure(
          message: apiMsg ?? 'Phòng đã đầy / đã tham gia / không đủ Karma',
          statusCode: code,
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure(message: 'Lỗi server ($code)', statusCode: code);
      default:
        return NetworkFailure(message: e.message ?? 'Không thể kết nối server');
    }
  }
}
