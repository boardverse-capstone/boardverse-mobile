import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/cafe_availability_entity.dart';
import '../base/cafe_availability_remote_datasource.dart';

/// Dio implementation cho `GET /api/cafes/{cafeId}/availability` (gap #2).
///
/// Mirror response schema xem `.agents/docs/apis_docs/cafe-booking.md` §90-114.
class CafeAvailabilityRemoteDatasourceImpl
    implements CafeAvailabilityRemoteDatasource {
  final Dio dio;

  CafeAvailabilityRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, CafeAvailabilityEntity>> getAvailability({
    required String cafeId,
    required DateTime startTime,
    required DateTime endTime,
    int? seatCount,
    String? gameTemplateId,
  }) async {
    try {
      final path = ApiEndpoints.cafeAvailability.replaceAll('{cafeId}', cafeId);
      final query = <String, dynamic>{
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
      };
      if (seatCount != null) query['seatCount'] = seatCount;
      if (gameTemplateId != null) query['gameTemplateId'] = gameTemplateId;

      final response = await dio.get<Map<String, dynamic>>(
        path,
        queryParameters: query,
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      if (!api.isSuccess || api.data == null) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể khảo sát capacity quán',
          ),
        );
      }
      return Right(_parseEntity(api.data!));
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      if (code == 404) {
        return Left(
          NotFoundFailure(
            message: message ??
                'API availability chưa được backend hỗ trợ (gap #2)',
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
        ServerFailure(message: 'Không thể đọc availability: $error'),
      );
    }
  }

  CafeAvailabilityEntity _parseEntity(Map<String, dynamic> json) {
    final slotsRaw = (json['alternativeSlots'] as List?) ?? const <dynamic>[];
    final slots = slotsRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (s) => AlternativeSlotEntity(
            startTime: DateTime.parse(s['startTime'] as String).toLocal(),
            endTime: DateTime.parse(s['endTime'] as String).toLocal(),
            availableSeats: (s['availableSeats'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();

    return CafeAvailabilityEntity(
      cafeId: json['cafeId'] as String? ?? '',
      cafeName: json['cafeName'] as String? ?? '',
      requestedStartTime:
          DateTime.parse(json['requestedStartTime'] as String).toLocal(),
      requestedEndTime:
          DateTime.parse(json['requestedEndTime'] as String).toLocal(),
      hasCapacity: json['hasCapacity'] as bool? ?? false,
      availableSeats: (json['availableSeats'] as num?)?.toInt() ?? 0,
      totalSeats: (json['totalSeats'] as num?)?.toInt() ?? 0,
      availableGameBoxCount: (json['availableGameBoxCount'] as num?)?.toInt(),
      selectedGameAvailabilityStatus:
          json['selectedGameAvailabilityStatus'] as String?,
      alternativeSlots: slots,
    );
  }
}
