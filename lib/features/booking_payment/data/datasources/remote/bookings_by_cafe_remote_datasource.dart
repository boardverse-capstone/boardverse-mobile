import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/cafe_booking_summary_entity.dart';
import '../../../domain/enums/booking_status.dart';
import '../base/bookings_by_cafe_remote_datasource.dart';

/// Dio implementation cho Player-view `GET /api/bookings/cafe/{cafeId}` (gap #14).
class BookingsByCafeRemoteDatasourceImpl
    implements BookingsByCafeRemoteDatasource {
  final Dio dio;

  BookingsByCafeRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, List<CafeBookingSummaryEntity>>> getBookingsForCafe(
    String cafeId,
  ) async {
    try {
      final path = ApiEndpoints.bookingsByCafe.replaceAll('{cafeId}', cafeId);
      final response = await dio.get<Map<String, dynamic>>(path);
      final api = ApiResponse<dynamic>.fromJson(response.data ?? const {});
      if (!api.isSuccess) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể lấy lịch đặt của quán',
          ),
        );
      }

      final raw = api.data;
      final items = raw is List
          ? raw
          : raw is Map<String, dynamic> && raw['items'] is List
              ? raw['items'] as List
              : const <dynamic>[];
      final bookings = items
          .whereType<Map<String, dynamic>>()
          .map(_parseItem)
          .where((b) => b.id.isNotEmpty)
          .toList();
      return Right(bookings);
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      switch (code) {
        case 403:
          return Left(
            ForbiddenFailure(
              message: message ?? 'Bạn không có quyền xem lịch quán này',
            ),
          );
        case 404:
          return Left(
            NotFoundFailure(message: message ?? 'Không tìm thấy quán'),
          );
        default:
          return Left(
            NetworkFailure(
              message: message ?? error.message ?? 'Không thể kết nối server',
            ),
          );
      }
    } catch (error) {
      return Left(
        ServerFailure(message: 'Không thể đọc lịch quán: $error'),
      );
    }
  }

  CafeBookingSummaryEntity _parseItem(Map<String, dynamic> json) {
    return CafeBookingSummaryEntity(
      id: json['id'] as String? ?? '',
      scheduledStartTime: DateTime.parse(json['scheduledStartTime'] as String)
          .toLocal(),
      scheduleEndTime: DateTime.parse(json['scheduleEndTime'] as String)
          .toLocal(),
      playerQuantity: (json['playerQuantity'] as num?)?.toInt() ?? 0,
      status: _parseStatus(
        json['status'],
        statusText: json['statusText'] as String?,
      ),
    );
  }

  BookingStatus _parseStatus(dynamic raw, {String? statusText}) {
    final fromText = BookingStatusX.fromStatusText(statusText);
    if (fromText != null) return fromText;
    if (raw is num) {
      final fromInt = BookingStatusX.fromInt(raw.toInt());
      if (fromInt != null) return fromInt;
    } else if (raw is String) {
      final fromText2 = BookingStatusX.fromStatusText(raw);
      if (fromText2 != null) return fromText2;
    }
    return BookingStatus.confirmed;
  }
}
