import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/lobby_entity.dart';
import '../../../domain/repositories/lobby_repository.dart';

/// Skeleton cho remote data source của Lobby (Task 3) — phase sau sẽ tích hợp
/// với backend thật. Hiện không được bind trong `injection.dart` cho đến khi
/// `AppConfig.useMockData = false`.
///
/// Method signatures khớp với [LobbyRepository] để dễ dàng switch.
class LobbyRemoteDatasource {
  final Dio _dio;

  LobbyRemoteDatasource({required this._dio});

  /// POST /api/Lobbies
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
      final response = await _dio.post(
        ApiEndpoints.lobbiesList,
        data: {
          'gameId': gameId,
          'cafeId': cafeId,
          'scheduledTime': scheduledTime.toIso8601String(),
          'additionalSlots': additionalSlots,
          'isPublic': isPublic,
          'searchRadiusKm': searchRadiusKm,
          'minimumKarma': minimumKarma,
          'leadTimeMinutes': leadTime?.inMinutes,
        },
      );
      return _toEntity(response);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// POST /api/Lobbies/{id}/join
  Future<Either<Failure, void>> joinLobby(String id, String? inviteCode) async {
    try {
      await _dio.post(
        ApiEndpoints.lobbyJoin.replaceAll('{id}', id),
        data: {'inviteCode': inviteCode},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// POST /api/Lobbies/{id}/leave
  Future<Either<Failure, void>> leaveLobby(String id) async {
    try {
      await _dio.post(ApiEndpoints.lobbyLeave.replaceAll('{id}', id));
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// POST /api/Lobbies/{id}/cancel
  Future<Either<Failure, void>> cancelLobby(
    String id,
    String reasonCode,
  ) async {
    try {
      await _dio.post(
        ApiEndpoints.lobbyCancel.replaceAll('{id}', id),
        data: {'reasonCode': reasonCode},
      );
      return const Right(null);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// GET /api/Lobbies/search?lat=&lng=&radiusKm=&minKarma=&gameId=
  Future<Either<Failure, List<Map<String, dynamic>>>> searchLobbies({
    required double latitude,
    required double longitude,
    double? radiusKm,
    double? minKarma,
    String? gameId,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.lobbiesSearch,
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
          'radiusKm': radiusKm,
          'minKarma': minKarma,
          'gameId': gameId,
        },
      );
      final list = (response.data as List).cast<Map<String, dynamic>>();
      return Right(list);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// POST /api/Lobbies/{id}/auto-booking
  Future<Either<Failure, String>> autoCreateBooking(String id) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.lobbyAutoBooking.replaceAll('{id}', id),
      );
      return Right(response.data['bookingId'] as String);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// PATCH /api/Lobbies/{id}/status
  Future<Either<Failure, LobbyEntity>> updateStatus(
    String id,
    String status,
  ) async {
    try {
      final response = await _dio.patch(
        ApiEndpoints.lobbyStatus.replaceAll('{id}', id),
        data: {'status': status},
      );
      return _toEntity(response);
    } on DioException catch (e) {
      return Left(_mapDioError(e));
    }
  }

  /// (Skeletal) Helper map response → entity.
  Either<Failure, LobbyEntity> _toEntity(Response response) {
    final raw = response.data as Map<String, dynamic>;
    // Khi backend hoàn thiện, sử dụng LobbyModel.fromJson(...)
    // Hiện trả về 1 LobbyEntity stub để type system không phàn nàn.
    final lobby = LobbyEntity(
      id: raw['id'] as String,
      gameId: raw['gameId'] as String,
      gameName: raw['gameName'] as String? ?? '',
      cafeId: raw['cafeId'] as String,
      cafeName: raw['cafeName'] as String? ?? '',
      hostId: raw['hostId'] as String? ?? '',
      hostName: raw['hostName'] as String? ?? '',
      scheduledTime: DateTime.parse(raw['scheduledTime'] as String),
      currentPlayers: raw['currentPlayers'] as int,
      maxPlayers: raw['maxPlayers'] as int,
      minPlayers: raw['minPlayers'] as int,
      isPublic: raw['isPublic'] as bool? ?? true,
      inviteCode: raw['inviteCode'] as String?,
      status: LobbyStatus.open,
      players: const [],
      createdAt: DateTime.now(),
      timeoutAt: DateTime.now().add(const Duration(minutes: 20)),
      bookingId: raw['bookingId'] as String?,
      minimumKarma: (raw['minimumKarma'] as num?)?.toDouble() ?? 0,
      searchRadiusKm: (raw['searchRadiusKm'] as num?)?.toDouble() ?? 5,
    );
    return Right(lobby);
  }

  ServerFailure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final msg = e.response?.data is Map<String, dynamic>
        ? (e.response!.data as Map<String, dynamic>)['message'] as String?
        : null;
    return ServerFailure(
      message: msg ?? 'Lỗi mạng: ${e.message ?? 'không rõ'}',
      statusCode: code,
    );
  }
}
