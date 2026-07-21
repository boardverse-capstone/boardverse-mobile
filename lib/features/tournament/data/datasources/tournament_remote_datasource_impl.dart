import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/constants/api_endpoints.dart';
import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/features/tournament/data/models/tournament_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/participant_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/match_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/elo_history_model.dart';
import 'package:boardverse_mobile/features/tournament/data/models/leaderboard_model.dart';
import 'package:boardverse_mobile/features/tournament/data/datasources/base/tournament_remote_datasource.dart';

/// Implementation of TournamentRemoteDatasource using Dio client.
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

      final data = response.data as List<dynamic>;
      return data
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TournamentModel>> getUpcomingTournaments({
    String? gameTemplateId,
  }) async {
    try {
      final queryParams = gameTemplateId != null
          ? {'gameTemplateId': gameTemplateId}
          : null;

      final response = await _dio.get(
        ApiEndpoints.tournamentsUpcoming,
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();
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

      return TournamentModel.fromJson(response.data as Map<String, dynamic>);
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

      final data = response.data as List<dynamic>;
      return data
          .map((json) =>
              TournamentParticipantModel.fromJson(json as Map<String, dynamic>))
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

      return TournamentParticipantModel.fromJson(
        response.data as Map<String, dynamic>,
      );
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

      final data = response.data as List<dynamic>;
      return data
          .map((json) =>
              TournamentMatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
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

      final data = response.data as List<dynamic>;
      return data
          .map((json) =>
              TournamentMatchModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<TournamentMatchModel> getMatchById(String matchId) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentMatchById(matchId),
      );

      return TournamentMatchModel.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> register(String tournamentId) async {
    try {
      await _dio.post(
        ApiEndpoints.tournamentRegister(tournamentId),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> unregister(String tournamentId) async {
    try {
      await _dio.post(
        ApiEndpoints.tournamentUnregister(tournamentId),
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<TournamentModel>> getMyRegistrations({
    String? status,
  }) async {
    try {
      final queryParams = status != null ? {'status': status} : null;

      final response = await _dio.get(
        ApiEndpoints.tournamentsMyRegistrations,
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((json) => TournamentModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<EloHistoryModel>> getMyEloHistory() async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentsMyEloHistory,
      );

      final data = response.data as List<dynamic>;
      return data
          .map((json) => EloHistoryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    int topCount = 100,
  }) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.tournamentsLeaderboard,
        queryParameters: {'topCount': topCount},
      );

      final data = response.data as List<dynamic>;
      return data
          .map((json) =>
              LeaderboardEntryModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ServerException _mapDioError(DioException e) {
    final message = e.response?.data?['message'] as String? ?? e.message ?? 'Unknown error';
    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
    );
  }
}
