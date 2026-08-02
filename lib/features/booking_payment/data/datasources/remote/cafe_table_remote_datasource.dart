import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/cafe_table_entity.dart';
import '../../models/cafe_table_model.dart';
import '../base/cafe_table_remote_datasource.dart';

/// Dio implementation cho API tra bàn trống của Player.
class CafeTableRemoteDatasourceImpl implements CafeTableRemoteDatasource {
  final Dio dio;

  CafeTableRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, List<CafeTableEntity>>> getAvailableTables({
    required String cafeId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    required int seatCount,
  }) async {
    try {
      final path = ApiEndpoints.cafeAvailableTables.replaceAll(
        '{cafeId}',
        cafeId,
      );
      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {
          'scheduledStartTime': scheduledStartTime.toUtc().toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toUtc().toIso8601String(),
          'seatCount': seatCount,
        },
      );
      final api = ApiResponse<dynamic>.fromJson(response.data ?? const {});
      if (!api.isSuccess) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể lấy danh sách bàn trống',
          ),
        );
      }

      final raw = api.data;
      final items = raw is List
          ? raw
          : raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : const <dynamic>[];
      final tables = items
          .whereType<Map<String, dynamic>>()
          .map(CafeTableModel.fromJson)
          .map((model) => model.toEntity())
          .where((table) => table.id.isNotEmpty && table.isAvailable)
          .toList();
      return Right(tables);
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      if (code == 403) {
        return Left(
          ForbiddenFailure(
            message: message ?? 'Player chưa được cấp quyền xem bàn trống',
          ),
        );
      }
      if (code == 404) {
        return Left(
          NotFoundFailure(
            message: message ?? 'API tra bàn trống chưa được backend hỗ trợ',
          ),
        );
      }
      return Left(
        NetworkFailure(
          message: message ?? error.message ?? 'Không thể kết nối server',
        ),
      );
    } catch (error) {
      return Left(
        ServerFailure(message: 'Không thể đọc danh sách bàn trống: $error'),
      );
    }
  }
}
