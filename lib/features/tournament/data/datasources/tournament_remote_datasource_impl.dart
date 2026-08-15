import 'package:dio/dio.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/exceptions.dart';
import 'package:boardverse/features/tournament/data/models/tournament_model.dart';
import 'package:boardverse/features/tournament/data/models/participant_model.dart';
import 'package:boardverse/features/tournament/data/models/match_model.dart';
import 'package:boardverse/features/tournament/data/models/elo_history_model.dart';
import 'package:boardverse/features/tournament/data/models/my_registration_model.dart';
import 'package:boardverse/features/tournament/data/models/tournament_waitlist_model.dart';
import 'package:boardverse/features/tournament/data/models/tournament_spectator_model.dart';
import 'package:boardverse/features/tournament/data/datasources/base/tournament_remote_datasource.dart';

/// Implementation of TournamentRemoteDatasource using Dio client.
///
/// **Quan trọng — Backend response envelope:**
/// Mọi response từ BoardVerse API đều được wrap trong envelope:
/// ```json
/// {
///   "statusCode": 200,
///   "message": "OK",
///   "data": { ... actual payload ... },
///   "timestamp": "...",
///   "path": "..."
/// }
/// ```
/// Method [_unwrapMap] / [_unwrapList] sẽ bóc lớp `data` trước khi truyền
/// cho [Model.fromJson]. Nếu backend trả error envelope (`data: null`),
/// Dio sẽ throw exception — không cần xử lý riêng.
class TournamentRemoteDatasourceImpl implements TournamentRemoteDatasource {
  final Dio _dio;

  TournamentRemoteDatasourceImpl({required this._dio});

  @override
  Future<List<TournamentModel>> getOpenTournaments({
    String? gameTemplateId,
  }) async {
    try {
      final queryParams = gameTemplateId != null
          ? {'gameTemplateId': gameTemplateId}
          : null;

      final response = await _dio.get(
        ApiEndpoints.tournamentsOpen,
        queryParameters: queryParams,
      );

      final list = _unwrapList(response.data);
      return list.map((json) => TournamentModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TournamentModel> getTournamentDetail(String tournamentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentDetail(tournamentId),
      );

      return TournamentModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TournamentParticipantModel>> getParticipants(
    String tournamentId,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentParticipants(tournamentId),
      );

      final list = _unwrapList(response.data);
      return list
          .map((json) => TournamentParticipantModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TournamentParticipantModel> getParticipant(
    String tournamentId,
    String participantId,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentParticipant(tournamentId, participantId),
      );

      return TournamentParticipantModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TournamentMatchModel>> getMatches(String tournamentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentMatches(tournamentId),
      );

      final list = _unwrapList(response.data);
      return list.map((json) => TournamentMatchModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Lấy chi tiết 1 match từ danh sách matches của tournament.
  ///
  /// Backend hiện **không expose** endpoint `GET /tournaments/matches/{id}`
  /// (trả 404). Do đó mobile fetch toàn bộ matches rồi filter client-side
  /// theo [matchId]. Phù hợp với 4 round Swiss (≤ ~8 matches / tournament).
  @override
  Future<TournamentMatchModel> getMatchById(
    String tournamentId,
    String matchId,
  ) async {
    try {
      final matches = await getMatches(tournamentId);
      return matches.firstWhere(
        (m) => m.id == matchId,
        orElse: () => throw ServerException(
          message: 'Không tìm thấy trận đấu trong giải.',
          statusCode: 404,
        ),
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định: $e');
    }
  }

  @override
  Future<List<TournamentMatchModel>> getMatchesByRound(
    String tournamentId,
    int roundNumber,
  ) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentMatchesRound(tournamentId, roundNumber),
      );

      final list = _unwrapList(response.data);
      return list.map((json) => TournamentMatchModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> register(String tournamentId) async {
    try {
      await _dio.post(ApiEndpoints.tournamentRegister(tournamentId));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> unregister(String tournamentId) async {
    try {
      await _dio.post(ApiEndpoints.tournamentUnregister(tournamentId));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<MyRegistrationModel>> getMyRegistrations({String? status}) async {
    try {
      final queryParams = status != null ? {'status': status} : null;

      final response = await _dio.get(
        ApiEndpoints.tournamentsMyRegistrations,
        queryParameters: queryParams,
      );

      final list = _unwrapList(response.data);
      return list
          .map((json) => MyRegistrationModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<MyEloHistoryResponseModel> getMyEloHistory() async {
    try {
      final response = await _dio.get(ApiEndpoints.tournamentsMyEloHistory);

      // Endpoint trả về wrapper object (không phải array). Tự unwrap data
      // nếu có envelope; nếu backend trả thẳng thì dùng raw.
      final raw = response.data;
      final Map<String, dynamic> payload;
      if (raw is Map<String, dynamic> && raw.containsKey('data')) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          payload = data;
        } else if (data is List) {
          // Fallback: một số version cũ có thể trả list thẳng — vẫn wrap
          // lại để khớp shape mới.
          payload = {'history': data, 'currentElo': 1500};
        } else {
          payload = const {};
        }
      } else if (raw is Map<String, dynamic>) {
        payload = raw;
      } else {
        throw const ServerException(
          message:
              'Response /my-elo-history không đúng định dạng (expected object)',
        );
      }
      return MyEloHistoryResponseModel.fromJson(payload);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── T-03: Tournament Waitlist ──────────────────────────────────────────

  @override
  Future<TournamentWaitlistModel> joinWaitlist(String tournamentId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournamentWaitlistJoin(tournamentId),
      );
      return TournamentWaitlistModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TournamentWaitlistModel>> getWaitlist(
    String tournamentId, {
    int? page,
    int? pageSize,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (page != null) queryParams['page'] = page;
      if (pageSize != null) queryParams['pageSize'] = pageSize;

      final response = await _dio.get(
        ApiEndpoints.tournamentWaitlist(tournamentId),
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final list = _unwrapList(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => TournamentWaitlistModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<MyWaitlistStatusModel> getMyWaitlistStatus(
      String tournamentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentWaitlistMe(tournamentId),
      );
      // Trường hợp `data: null` (chưa join) → trả `isInWaitlist=false`.
      final raw = _unwrapMapNullable(response.data);
      if (raw == null) {
        return const MyWaitlistStatusModel(isInWaitlist: false);
      }
      return MyWaitlistStatusModel.fromJson(raw);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> leaveWaitlist(String tournamentId) async {
    try {
      await _dio.delete(ApiEndpoints.tournamentWaitlistLeave(tournamentId));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<WaitlistActionResultModel> confirmWaitlistOffer(
      String tournamentId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournamentWaitlistConfirm(tournamentId),
      );
      return WaitlistActionResultModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<WaitlistActionResultModel> declineWaitlistOffer(
      String tournamentId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournamentWaitlistDecline(tournamentId),
      );
      return WaitlistActionResultModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ─── T-04: Tournament Spectator ────────────────────────────────────────

  @override
  Future<List<TournamentSpectatorModel>> getSpectators(
      String tournamentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentSpectators(tournamentId),
      );
      final list = _unwrapList(response.data);
      return list
          .whereType<Map<String, dynamic>>()
          .map((json) => TournamentSpectatorModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<MySpectatorStatusModel> getMySpectatorStatus(
      String tournamentId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentSpectatorMe(tournamentId),
      );
      // Backend trả `data: null` khi user chưa spectate.
      final raw = _unwrapMapNullable(response.data);
      if (raw == null) {
        return const MySpectatorStatusModel(isSpectating: false);
      }
      return MySpectatorStatusModel(
        isSpectating: true,
        model: TournamentSpectatorModel.fromJson(raw),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TournamentSpectatorModel> startSpectating(String tournamentId) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.tournamentSpectatorJoin(tournamentId),
      );
      return TournamentSpectatorModel.fromJson(_unwrapMap(response.data));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> stopSpectating(String tournamentId) async {
    try {
      await _dio.delete(ApiEndpoints.tournamentSpectatorLeave(tournamentId));
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // Leaderboard đã tách ra feature riêng (`lib/features/leaderboard/`).
  // Xem `LeaderboardRepository.fetchLeaderboard(kind: ...)` — gọi các
  // endpoint mới `/api/v1/leaderboard/{karma,elo,level}`.

  // ─── Helpers ──────────────────────────────────────────────────────────

  /// Bóc lớp `data` của envelope `{ statusCode, message, data, ... }`.
  /// Direct object payloads (không có key `data`) cũng được chấp nhận.
  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (!raw.containsKey('data')) return raw;

      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;

      final message = raw['message']?.toString().trim();
      throw ServerException(
        message: message?.isNotEmpty == true
            ? message!
            : 'Response không chứa dữ liệu hợp lệ',
        statusCode: raw['statusCode'] is num
            ? (raw['statusCode'] as num).toInt()
            : null,
      );
    }
    throw const ServerException(
      message: 'Response không đúng định dạng envelope',
    );
  }

  /// Tolerant variant: trả null khi `data` không phải object (vd null khi
  /// user chưa join waitlist / chưa spectate). Caller xử lý default.
  Map<String, dynamic>? _unwrapMapNullable(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (!raw.containsKey('data')) return raw;
      final data = raw['data'];
      if (data == null) return null;
      if (data is Map<String, dynamic>) return data;
    }
    return null;
  }

  /// Bóc lớp `data` của envelope và cast sang `List<dynamic>`.
  List<dynamic> _unwrapList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final data = raw['data'];
      if (data is List) return data;
      // Một số endpoint (vd `leaderboard`) wrap thêm 1 cấp:
      // `{ statusCode, data: { data: [...], totalPlayers: N } }`
      if (data is Map<String, dynamic>) {
        final inner = data['data'];
        if (inner is List) return inner;
      }
      // Nếu data null và là success envelope → trả list rỗng
      if (data == null) return const [];
    }
    throw ServerException(
      message: 'Response không đúng định dạng envelope (expected array)',
      statusCode: null,
    );
  }

  ServerException _mapDioError(DioException e) {
    final message =
        e.response?.data?['message'] as String? ?? e.message ?? 'Unknown error';
    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
