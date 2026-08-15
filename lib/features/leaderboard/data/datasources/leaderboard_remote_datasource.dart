import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/leaderboard_kind.dart';
import '../models/leaderboard_response_model.dart';

/// Remote datasource cho leaderboard — gọi 3 endpoint backend
/// `/api/v1/leaderboard/{karma,elo,level}`.
abstract class LeaderboardRemoteDatasource {
  Future<LeaderboardResponseModel> fetch({
    required LeaderboardKind kind,
    int top = 50,
    int offset = 0,
  });
}

class LeaderboardRemoteDatasourceImpl implements LeaderboardRemoteDatasource {
  final Dio dio;

  LeaderboardRemoteDatasourceImpl({required this.dio});

  @override
  Future<LeaderboardResponseModel> fetch({
    required LeaderboardKind kind,
    int top = 50,
    int offset = 0,
  }) async {
    // Backend clamp `top` về [1, 100] và `offset` ≥ 0 — vẫn clamp ở
    // client để tránh gửi payload vô nghĩa (vd top=0).
    final clampedTop = top.clamp(1, 100);
    final clampedOffset = offset < 0 ? 0 : offset;

    final path = switch (kind) {
      LeaderboardKind.karma => ApiEndpoints.leaderboardKarma,
      LeaderboardKind.elo => ApiEndpoints.leaderboardElo,
      LeaderboardKind.level => ApiEndpoints.leaderboardLevel,
    };

    try {
      final response = await dio.get(
        path,
        queryParameters: {
          'top': clampedTop,
          'offset': clampedOffset,
        },
      );
      return LeaderboardResponseModel.fromJson(
        _unwrapMap(response.data),
        kind: kind,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Bóc lớp `data` của envelope `{ statusCode, message, data, ... }`.
  /// Một số build backend cũ trả thẳng — chấp nhận cả 2.
  Map<String, dynamic> _unwrapMap(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      if (!raw.containsKey('data')) return raw;
      final data = raw['data'];
      if (data is Map<String, dynamic>) return data;
      throw ServerException(
        message: raw['message']?.toString() ?? 'Response không hợp lệ',
        statusCode: raw['statusCode'] is num
            ? (raw['statusCode'] as num).toInt()
            : null,
      );
    }
    throw const ServerException(
      message: 'Response leaderboard không đúng định dạng envelope',
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
