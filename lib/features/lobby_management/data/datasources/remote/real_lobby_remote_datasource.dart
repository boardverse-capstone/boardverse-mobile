import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/data/models/friend_model.dart';
import 'package:boardverse/features/friend_management/domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_invite_entity.dart';
import '../../../domain/entities/lobby_invitable_friend.dart';
import '../../../domain/entities/lobby_share_info.dart';
import '../../../domain/entities/lobby_summary.dart';
import '../../../domain/entities/lobby_chat_message.dart';
import '../../../domain/entities/match_result_entity.dart';
import '../../models/lobby_model.dart';
import '../../models/lobby_invite_model.dart';
import '../../models/lobby_invitable_friend_model.dart';
import '../../models/lobby_share_info_model.dart';
import '../../models/match_result_model.dart';
import '../../models/elo_update_model.dart';
import '../base/lobby_remote_datasource.dart';

/// Triển khai gọi REST API thật theo spec `.agents/docs/apis_docs/lobby.md`.
///
/// Lưu ý mapping field:
/// - **response parsing**: dùng `LobbyModel.fromJson` hiện có (camelCase).
///   Nếu backend trả PascalCase cần thêm converter (xem plan §Câu hỏi 1).
///
/// **Lưu ý migrate (Reservation/BVC):**
/// - Không còn `createLobby`/`autoCreateBooking`/`createLobbyForExistingBooking`.
///   Việc tạo lobby đi qua flow Reservation: `quote → confirm` (xem
///   `lib/features/reservation/...`). Chỉ bind trong DI khi
///   `AppConfig.useMockLobbyData = false`.
class RealLobbyRemoteDatasource implements LobbyRemoteDatasource {
  final Dio _dio;

  RealLobbyRemoteDatasource({required this._dio});

  // ════════════════════════════════════════════════════════════════════
  // Lobby CRUD
  // ════════════════════════════════════════════════════════════════════

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
    bool excludeSelfOverlapping = true,
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
        'excludeSelfOverlapping': excludeSelfOverlapping,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.lobbiesSearch,
        data: body,
      );
      final items = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
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
    String? gameTemplateId,
    double? latitude,
    double? longitude,
    double? radiusKm,
    int limit = 50,
    bool excludeSelfOverlapping = true,
  }) async {
    try {
      // GET /api/v1/lobbies/discoverable — flow Browse lobbies.
      // Server đã filter theo vị trí user + visibility, không cần gửi
      // `gameTemplateId` (optional). Hỗ trợ filter optional theo game + geo.
      // ignore: use_null_aware_elements
      final query = <String, dynamic>{
        'limit': limit,
        if (gameTemplateId != null && gameTemplateId.isNotEmpty)
          'gameTemplateId': gameTemplateId,
        // ignore: use_null_aware_elements
        if (latitude != null) 'latitude': latitude,
        // ignore: use_null_aware_elements
        if (longitude != null) 'longitude': longitude,
        // ignore: use_null_aware_elements
        if (radiusKm != null) 'radiusKm': radiusKm,
        'excludeSelfOverlapping': excludeSelfOverlapping,
      };
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lobbiesDiscoverable,
        queryParameters: query,
      );
      // Backend bọc response trong envelope `{ statusCode, message, data, ... }`.
      // Phải unwrap `data` trước khi cast sang List.
      final payload = res.data ?? const <String, dynamic>{};
      final dynamic rawList = payload['data'] ?? payload['items'] ?? payload;
      if (rawList is! List) {
        return const Left<Failure, List<LobbyEntity>>(
          ServerFailure(message: 'Phản hồi không hợp lệ từ server.'),
        );
      }
      final items = rawList
          .whereType<Map<String, dynamic>>()
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
        data: inviteCode != null ? {'inviteCode': inviteCode} : {},
      );
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
      // GET /api/v1/friends — trả về FriendSummaryDto[] (tất cả bạn bè).
      // KHÔNG filter theo online status vì:
      // - API /activity chỉ trả bạn bè đang online → không thấy bạn offline
      // - Khi gửi invite, server sẽ gửi notification đến friend dù online/offline
      // - UI sẽ hiển thị badge "online" dựa trên activityStatus từ response
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.friends,
      );
      final friends = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
          .map((json) => FriendModel.fromJson(json).toEntity())
          .toList();
      // Trả về tất cả bạn bè - UI sẽ hiển thị online status qua activityStatus
      return Right<Failure, List<FriendEntity>>(friends);
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
  Future<Either<Failure, void>> dissolveLobby({
    required String lobbyId,
    String? reason,
  }) async {
    try {
      final path = ApiEndpoints.lobbyDissolve(lobbyId);
      final body = reason != null ? {'reason': reason} : null;
      await _dio.delete<Map<String, dynamic>>(
        path,
        data: body,
      );
      // 200: lobby đã giải tán (hard delete thành công).
      return const Right<Failure, void>(null);
    } on DioException catch (e) {
      // 409: lobby đã booking thành công / đang trong phiên chơi /
      // đã đóng — không thể giải tán.
      if (e.response?.statusCode == 409) {
        final apiMsg = e.response?.data is Map
            ? (e.response!.data as Map)['message'] as String?
            : null;
        return Left<Failure, void>(ServerFailure(
          message: apiMsg ??
              'Phòng đã đặt cọc hoặc đang trong phiên chơi, không thể giải tán.',
          statusCode: 409,
        ));
      }
      return Left<Failure, void>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, void>(
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
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lobbyInvitesPending,
      );
      final items = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
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
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lobbyInvitesMe,
        queryParameters: queryParams,
      );
      final items = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
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

      // Backend `POST /api/v1/lobbies/invites/{inviteId}/accept` trả về
      // `LobbyInviteResponseDto` (xem `lobby-invite.md` §Accept invite):
      //   { inviteId, lobbyId, status, ... }
      // — KHÔNG phải `LobbyDto` đầy đủ. Trước đây code cố parse như
      // `LobbyModel.fromJson(_unwrap(res.data))` ⇒ throw `TypeError`
      // (`json['id'] as String` không tồn tại) ⇒ UI báo "Lỗi không xác
      // định" dù backend đã accept thành công.
      //
      // Flow fix: parse invite DTO → lấy `lobbyId` → fetch
      // `GET /api/v1/lobbies/{lobbyId}` để trả full `LobbyEntity`.
      final raw = _unwrap(res.data);
      final inviteModel = LobbyInviteModel.fromJson(raw);
      final lobbyId = inviteModel.lobbyId;

      // Fallback nếu lobbyId thiếu trong response (không nên xảy ra
      // theo spec nhưng defensive): trả LobbyEntity rỗng để cubit không
      // crash, đồng thời log để debug.
      if (lobbyId.isEmpty) {
        return Left<Failure, LobbyEntity>(
          ServerFailure(
            message: 'Lỗi không xác định: invite response thiếu lobbyId',
          ),
        );
      }

      final lobbyRes = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.lobbyDetail.replaceAll('{id}', lobbyId),
      );
      final lobbyModel = LobbyModel.fromJson(_unwrap(lobbyRes.data));
      return Right<Failure, LobbyEntity>(lobbyModel.toEntity());
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

  @override
  Future<Either<Failure, List<LobbyInviteEntity>>> getLobbyInvites({
    required String lobbyId,
    LobbyInviteStatus? status,
    int limit = 100,
  }) async {
    try {
      final path = ApiEndpoints.lobbyInvites.replaceAll('{lobbyId}', lobbyId);
      final query = <String, dynamic>{'limit': limit};
      if (status != null) query['status'] = _statusToQuery(status);
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final raw = _unwrapList(res.data);
      final list = raw
          .map((e) => LobbyInviteModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Right<Failure, List<LobbyInviteEntity>>(
        list.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyInviteEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyInviteEntity>> resendInvite(String inviteId) async {
    try {
      final path = ApiEndpoints.lobbyInvitesResend.replaceAll(
        '{inviteId}',
        inviteId,
      );
      final res = await _dio.post<dynamic>(path);
      final raw = _unwrap(res.data);
      final model = LobbyInviteModel.fromJson(raw);
      return Right<Failure, LobbyInviteEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, LobbyInviteEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyInviteEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, List<LobbyInvitableFriend>>> getInvitableFriends({
    required String lobbyId,
    String? search,
    bool onlineOnly = false,
    int? minKarma,
    List<LobbyInviteFriendStatus> statusFilter = const [],
    int limit = 100,
  }) async {
    try {
      final path = ApiEndpoints.lobbyInvitableFriends.replaceAll(
        '{lobbyId}',
        lobbyId,
      );
      final query = <String, dynamic>{'onlineOnly': onlineOnly, 'limit': limit};
      if (search != null && search.trim().isNotEmpty) {
        query['search'] = search.trim();
      }
      if (minKarma != null) query['minKarma'] = minKarma;
      if (statusFilter.isNotEmpty) {
        query['status'] = statusFilter.map(_friendStatusToQuery).join(',');
      }
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final raw = _unwrapList(res.data);
      final list = raw
          .map(
            (e) => LobbyInvitableFriendModel.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();
      return Right<Failure, List<LobbyInvitableFriend>>(
        list.map((m) => m.toEntity()).toList(),
      );
    } on DioException catch (e) {
      return Left<Failure, List<LobbyInvitableFriend>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyInvitableFriend>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  /// Map enum sang PascalCase query value.
  String _statusToQuery(LobbyInviteStatus s) {
    switch (s) {
      case LobbyInviteStatus.pending:
        return 'Pending';
      case LobbyInviteStatus.accepted:
        return 'Accepted';
      case LobbyInviteStatus.declined:
        return 'Declined';
      case LobbyInviteStatus.cancelled:
        return 'Cancelled';
      case LobbyInviteStatus.expired:
        return 'Expired';
    }
  }

  String _friendStatusToQuery(LobbyInviteFriendStatus s) {
    switch (s) {
      case LobbyInviteFriendStatus.invitable:
        return 'Invitable';
      case LobbyInviteFriendStatus.invitePending:
        return 'InvitePending';
      case LobbyInviteFriendStatus.inviteAccepted:
        return 'InviteAccepted';
      case LobbyInviteFriendStatus.inviteNotPending:
        return 'InviteNotPending';
      case LobbyInviteFriendStatus.alreadyMember:
        return 'AlreadyMember';
      case LobbyInviteFriendStatus.blockedByThem:
        return 'BlockedByThem';
      case LobbyInviteFriendStatus.blockedByMe:
        return 'BlockedByMe';
      case LobbyInviteFriendStatus.lobbyClosed:
        return 'LobbyClosed';
      case LobbyInviteFriendStatus.unknown:
        return '';
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

  /// Unwrap danh sách từ envelope `{ "data": [ ... ] }`. Một số endpoint
  /// backend trả thẳng array không bọc — fallback khi `data` không tồn tại.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'] ?? raw['items'];
      if (data is List) return data;
    }
    return const <dynamic>[];
  }

  /// Map JSON đơn giản → LobbySummary (không kèm members).
  LobbySummary _summaryFromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v == null) return DateTime.now();
      // Strip trailing 'Z' để parse thành local time thay vì UTC
      final s = v.toString();
      final normalized = s.endsWith('Z') ? s.substring(0, s.length - 1) : s;
      return DateTime.parse(normalized);
    }
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
      // Visibility: dùng `parseVisibility` để hỗ trợ cả `isPrivate` (BE
      // mới) lẫn `isPublic` (schema cũ). Trước đây chỉ đọc `isPublic`,
      // gây bug: lobby public (isPrivate: false) bị mobile hiển thị
      // nhầm thành private khi BE không gửi `isPublic`.
      isPublic: LobbyModel.parseVisibility(
        isPublic: json['isPublic'],
        isPrivate: json['isPrivate'],
        visibility: json['visibility'],
      ),
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

  // ════════════════════════════════════════════════════════════════════
  // Host-only actions (Transfer, Kick, Ready)
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, LobbyEntity>> transferHost({
    required String lobbyId,
    required String newHostId,
  }) async {
    try {
      final path = ApiEndpoints.lobbyTransferHost(lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'newHostUserId': newHostId},
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
  Future<Either<Failure, LobbyEntity>> kickMember({
    required String lobbyId,
    required String targetUserId,
    String? reason,
  }) async {
    try {
      final path = ApiEndpoints.lobbyKick(lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'targetUserId': targetUserId,
          ...?reason != null ? {'reason': reason} : null,
        },
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
  Future<Either<Failure, LobbyEntity>> setReady({
    required String lobbyId,
    required bool isReady,
  }) async {
    try {
      final path = ApiEndpoints.lobbyReady(lobbyId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'isReady': isReady},
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
  Future<Either<Failure, LobbyEntity>> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (description != null) body['description'] = description;
      if (maxMembers != null) body['maxMembers'] = maxMembers;
      if (isPrivate != null) body['isPrivate'] = isPrivate;
      if (minKarmaScore != null) body['minKarmaScore'] = minKarmaScore;

      final res = await _dio.patch<Map<String, dynamic>>(
        '${ApiEndpoints.lobbiesList}/$lobbyId',
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

  // ════════════════════════════════════════════════════════════════════
  // Lobby Lists (Hosted & Joined)
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<LobbyEntity>>> getHostedLobbies() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.lobbyHosted);
      final items = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
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

  @override
  Future<Either<Failure, List<LobbyEntity>>> getJoinedLobbies() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.lobbyJoined);
      final items = _unwrapList(res.data)
          .whereType<Map<String, dynamic>>()
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
  // Lobby Social (Report & Chat)
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, void>> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) async {
    try {
      final path = ApiEndpoints.lobbyReport(lobbyId);
      await _dio.post<Map<String, dynamic>>(
        path,
        data: {
          'category': category,
          'reason': reason,
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

  // ════════════════════════════════════════════════════════════════════
  // Chat Messages
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, List<LobbyChatMessage>>> getChatMessages({
    required String lobbyId,
    String? beforeCursor,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
      };
      if (beforeCursor != null) {
        queryParams['beforeCursor'] = beforeCursor;
      }

      final res = await _dio.get<Map<String, dynamic>>(
        '/api/v1/lobbies/$lobbyId/messages',
        queryParameters: queryParams,
      );

      final data = _unwrapList(res.data);
      final messages = data
          .whereType<Map<String, dynamic>>()
          .map((json) => LobbyChatMessage.fromJson(json))
          .toList();

      return Right<Failure, List<LobbyChatMessage>>(messages);
    } on DioException catch (e) {
      return Left<Failure, List<LobbyChatMessage>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<LobbyChatMessage>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, LobbyChatMessage>> sendChatMessage({
    required String lobbyId,
    required String content,
  }) async {
    try {
      final body = {'content': content};
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/v1/lobbies/$lobbyId/messages',
        data: body,
      );

      final message = LobbyChatMessage.fromJson(_unwrap(res.data));
      return Right<Failure, LobbyChatMessage>(message);
    } on DioException catch (e) {
      return Left<Failure, LobbyChatMessage>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, LobbyChatMessage>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }
}
