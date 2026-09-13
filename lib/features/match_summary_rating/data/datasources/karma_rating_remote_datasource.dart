import 'package:dio/dio.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/rating_entity.dart';
import '../models/karma_rating_models.dart';

/// Gọi REST API thật cho UserRatingController theo spec
/// `.agents/docs/apis_docs/user-ratings.md`:
///
/// - `GET /api/v1/users/ratings/karma/lobbies/{lobbyId}` — context.
/// - `POST /api/v1/users/ratings/karma` — submit cross-rating.
abstract class KarmaRatingRemoteDatasource {
  Future<Either<Failure, KarmaRatingContextEntity>> getContext(String lobbyId);

  Future<Either<Failure, SubmitKarmaRatingsResultEntity>> submitRatings({
    required String lobbyId,
    required List<KarmaRatingEntry> entries,
  });
}

class RealKarmaRatingRemoteDatasource implements KarmaRatingRemoteDatasource {
  final Dio _dio;

  RealKarmaRatingRemoteDatasource({required this._dio});

  @override
  Future<Either<Failure, KarmaRatingContextEntity>> getContext(
    String lobbyId,
  ) async {
    try {
      final path = ApiEndpoints.usersRatingsKarmaContext(lobbyId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final context = KarmaRatingContextModel.fromJson(_unwrap(res.data));
      return Right<Failure, KarmaRatingContextEntity>(context.toEntity());
    } on DioException catch (e) {
      return Left<Failure, KarmaRatingContextEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, KarmaRatingContextEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, SubmitKarmaRatingsResultEntity>> submitRatings({
    required String lobbyId,
    required List<KarmaRatingEntry> entries,
  }) async {
    try {
      final body = {
        'lobbyId': lobbyId,
        'ratings': entries
            .map(
              (e) => {
                'targetUserId': e.targetUserId,
                'tags': e.tags.map((t) => t.apiValue).toList(),
              },
            )
            .toList(),
      };
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.usersRatingsKarma,
        data: body,
      );
      final model = SubmitKarmaRatingsResultModel.fromJson(_unwrap(res.data));
      return Right<Failure, SubmitKarmaRatingsResultEntity>(model.toEntity());
    } on DioException catch (e) {
      return Left<Failure, SubmitKarmaRatingsResultEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, SubmitKarmaRatingsResultEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  /// Backend trả envelope `{ "data": { ... } }` theo convention chung —
  /// unwrap để call site không phải đụng vào envelope.
  Map<String, dynamic> _unwrap(Map<String, dynamic>? raw) {
    if (raw == null) return const <String, dynamic>{};
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
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
              'Phòng chưa mở đánh giá hoặc dữ liệu không hợp lệ.',
          statusCode: code,
        );
      case 401:
        return ServerFailure(
          message: apiMsg ?? 'Phiên đăng nhập hết hạn',
          statusCode: code,
        );
      case 403:
        return ServerFailure(
          message: apiMsg ?? 'Bạn không phải thành viên của phòng này',
          statusCode: code,
        );
      case 404:
        return ServerFailure(
          message: apiMsg ?? 'Không tìm thấy phòng',
          statusCode: code,
        );
      case 409:
        // Đã đánh giá người này trước đó — UI xử lý nhẹ nhàng.
        return ServerFailure(
          message: apiMsg ?? 'Bạn đã đánh giá người này trước đó.',
          statusCode: code,
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: apiMsg ?? 'Lỗi server ($code)',
          statusCode: code,
        );
      default:
        return NetworkFailure(message: e.message ?? 'Không thể kết nối server');
    }
  }
}
