import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/friend_entity.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/entities/lobby_summary.dart';
import '../../models/lobby_model.dart';
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
      // gameTemplateId là REQUIRED; backend `400` nếu thiếu.
      if (filter.gameId == null) {
        return const Left<Failure, List<LobbySummary>>(
          ServerFailure(message: 'Thiếu gameTemplateId'),
        );
      }
      final body = <String, dynamic>{
        'gameTemplateId': filter.gameId,
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
      await _dio.post<dynamic>(
        ApiEndpoints.lobbyDetail.replaceAll('{id}', lobbyId),
        data: {'action': 'invite', 'friendId': friendId},
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
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    // Tạm thời trả về empty list để UI render được.
    await Future.delayed(const Duration(milliseconds: 200));
    return const Right<Failure, List<FriendEntity>>([]);
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
