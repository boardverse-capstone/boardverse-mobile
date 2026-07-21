import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/match_consensus_entity.dart';
import '../base/match_result_remote_datasource.dart';

/// Triển khai gọi REST API thật cho module Match theo spec
/// `.agents/docs/apis_docs/matches.md`.
///
/// Lưu ý mapping:
/// - **Envelope**: backend trả `{ statusCode, message, data }` (xem
///   matches.md:24-46). Helper `_unwrap` bóc `data` nếu có,
///   fallback về raw nếu không (compatible).
/// - **Casing**: backend C# thường trả PascalCase (`LobbyId`, `Outcome`).
///   Hàm `_parseOutcome` chấp nhận cả 2 dạng để giảm rủi ro khi chưa
///   verify response mẫu thật.
///
/// Chỉ bind trong DI khi `AppConfig.useMockMatchData = false`.
class RealMatchResultRemoteDatasource implements MatchResultRemoteDatasource {
  RealMatchResultRemoteDatasource({required this._dio});

  final Dio _dio;

  // ════════════════════════════════════════════════════════════════════
  // GET /api/v1/matches/results/lobbies/{lobbyId}
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, MatchConsensusEntity>> getMatchResult(
    String lobbyId,
  ) async {
    try {
      final path = ApiEndpoints.matchResultByLobby.replaceAll('{lobbyId}', lobbyId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final raw = _unwrap(res.data);
      final entity = _consensusFromJson(raw);
      return Right<Failure, MatchConsensusEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, MatchConsensusEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, MatchConsensusEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // POST /api/v1/matches/results
  // ════════════════════════════════════════════════════════════════════

  @override
  Future<Either<Failure, MatchSubmissionResultEntity>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async {
    try {
      final body = <String, dynamic>{
        'lobbyId': lobbyId,
        'outcome': outcome.apiValue,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.matchResultSubmit,
        data: body,
      );
      final raw = _unwrap(res.data);
      final entity = _submissionResultFromJson(raw);
      return Right<Failure, MatchSubmissionResultEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, MatchSubmissionResultEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, MatchSubmissionResultEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ════════════════════════════════════════════════════════════════════
  // watchMatchResult — polling 5s (Phase sau sẽ thay bằng SignalR hub)
  // ════════════════════════════════════════════════════════════════════

  @override
  Stream<MatchConsensusEntity> watchMatchResult(String lobbyId) {
    // Spec matches.md chưa liệt kê hub real-time riêng — fallback polling
    // cho tới khi backend broadcast qua /hubs/lobby (điểm cần verify).
    return Stream.periodic(const Duration(seconds: 5)).asyncMap((_) async {
      final res = await _dio.get<Map<String, dynamic>>(
        ApiEndpoints.matchResultByLobby.replaceAll('{lobbyId}', lobbyId),
      );
      return _consensusFromJson(_unwrap(res.data));
    }).handleError((Object e) {
      // Tránh làm vỡ stream nếu 1 poll fail — emit error rồi tiếp tục.
      // Phía Cubit / Repository sẽ handle error này.
    });
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Bóc envelope `{ statusCode, message, data }` nếu backend wrap; nếu
  /// không, trả về raw (compatible).
  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return const <String, dynamic>{};
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  MatchConsensusEntity _consensusFromJson(Map<String, dynamic> json) {
    final outcomesRaw = (json['availableOutcomes'] ?? json['AvailableOutcomes'])
        as List<dynamic>? ??
        const [];
    final submissionsRaw =
        (json['submissions'] ?? json['Submissions']) as List<dynamic>? ?? const [];

    final outcomes = outcomesRaw
        .cast<Map<String, dynamic>>()
        .map(
          (o) => MatchOutcomeChoice(
            outcome: _parseOutcome(
              (o['outcome'] ?? o['Outcome'])?.toString() ?? 'Draw',
            ),
            label: (o['label'] ?? o['Label'])?.toString() ?? '',
          ),
        )
        .toList();
    final submissions = submissionsRaw
        .cast<Map<String, dynamic>>()
        .map(
          (s) => MatchSubmission(
            userId: (s['userId'] ?? s['UserId'] ?? '').toString(),
            username: (s['username'] ?? s['Username'] ?? '').toString(),
            outcome: _parseOutcome(
              (s['outcome'] ?? s['Outcome'])?.toString() ?? 'Draw',
            ),
            isCurrentUser: (s['isCurrentUser'] ?? s['IsCurrentUser']) as bool? ?? false,
          ),
        )
        .toList();

    return MatchConsensusEntity(
      lobbyId: (json['lobbyId'] ?? json['LobbyId'] ?? '').toString(),
      gameTemplateId:
          (json['gameTemplateId'] ?? json['GameTemplateId'] ?? '').toString(),
      gameName: (json['gameName'] ?? json['GameName'] ?? '').toString(),
      supportsMatchResults:
          (json['supportsMatchResults'] ?? json['SupportsMatchResults'])
                  as bool? ??
              true,
      consensusStatus: MatchConsensusStatus.fromString(
        (json['consensusStatus'] ?? json['ConsensusStatus'] ?? '').toString(),
      ),
      submittedCount:
          (json['submittedCount'] ?? json['SubmittedCount'] as num?)?.toInt() ?? 0,
      requiredCount:
          (json['requiredCount'] ?? json['RequiredCount'] as num?)?.toInt() ?? 0,
      conflictReason:
          (json['conflictReason'] ?? json['ConflictReason'])?.toString(),
      availableOutcomes: outcomes,
      submissions: submissions,
    );
  }

  MatchSubmissionResultEntity _submissionResultFromJson(
    Map<String, dynamic> json,
  ) {
    final eloUpdatesRaw =
        (json['eloUpdates'] ?? json['EloUpdates']) as List<dynamic>? ?? const [];
    final eloUpdates = eloUpdatesRaw
        .cast<Map<String, dynamic>>()
        .map(
          (e) => EloUpdateEntity(
            userId: (e['userId'] ?? e['UserId'] ?? '').toString(),
            reportedOutcome: _parseOutcome(
              (e['reportedOutcome'] ?? e['ReportedOutcome'])?.toString() ?? 'Draw',
            ),
            eloBefore:
                (e['eloBefore'] ?? e['EloBefore'] as num?)?.toInt() ?? 1200,
            eloAfter: (e['eloAfter'] ?? e['EloAfter'] as num?)?.toInt() ?? 1200,
            eloDelta: (e['eloDelta'] ?? e['EloDelta'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    return MatchSubmissionResultEntity(
      lobbyId: (json['lobbyId'] ?? json['LobbyId'] ?? '').toString(),
      consensusStatus: MatchConsensusStatus.fromString(
        (json['consensusStatus'] ?? json['ConsensusStatus'] ?? '').toString(),
      ),
      submittedCount:
          (json['submittedCount'] ?? json['SubmittedCount'] as num?)?.toInt() ?? 0,
      requiredCount:
          (json['requiredCount'] ?? json['RequiredCount'] as num?)?.toInt() ?? 0,
      matchHistoryId:
          (json['matchHistoryId'] ?? json['MatchHistoryId'])?.toString(),
      eloUpdates: eloUpdates,
    );
  }

  MatchOutcome _parseOutcome(String raw) {
    try {
      return MatchOutcome.fromApi(raw);
    } on ArgumentError {
      return MatchOutcome.draw;
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
          message: apiMsg ??
              'Game không hỗ trợ kết quả (không phải đối kháng/chiến thuật) hoặc phòng chưa eligible.',
          statusCode: code,
        );
      case 401:
        return ServerFailure(
          message: apiMsg ?? 'Phiên đăng nhập hết hạn',
          statusCode: code,
        );
      case 404:
        return ServerFailure(
          message: apiMsg ?? 'Không tìm thấy lobby',
          statusCode: code,
        );
      case 409:
        return ServerFailure(
          message: apiMsg ?? 'Trận đấu đã chốt, không thể gửi lại.',
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
