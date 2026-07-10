import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/booking_history_entity.dart';
import '../../../domain/entities/deposit_config_entity.dart';
import '../../../domain/enums/payment_method.dart';
import '../../models/booking_history_model.dart';
import '../../models/booking_model.dart';
import '../../models/deposit_config_model.dart';
import '../base/booking_remote_datasource.dart';

/// Triển khai gọi REST API thật qua [Dio].
///
/// Chỉ dùng khi `AppConfig.useMockData = false` (xem DI registration).
class BookingRemoteDatasourceImpl implements BookingRemoteDatasource {
  final Dio _dio;

  BookingRemoteDatasourceImpl({required this._dio});

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) async {
    try {
      final path = ApiEndpoints.depositConfig.replaceAll('{cafeId}', cafeId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final entity = DepositConfigModel.fromJson(res.data ?? {}).toEntity();
      return Right<Failure, DepositConfigEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, DepositConfigEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, DepositConfigEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    required String cafeId,
    required String gameId,
    required DateTime scheduledTime,
    required int seatCount,
    required double depositAmount,
    required PaymentMethod paymentMethod,
    required List<String> memberIds,
  }) async {
    try {
      final body = {
        'cafeId': cafeId,
        'gameId': gameId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'seatCount': seatCount,
        'depositAmount': depositAmount,
        'paymentMethod': paymentMethod.name,
        'memberIds': memberIds,
      };
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.createBooking,
        data: body,
      );
      final entity = BookingModel.fromJson(res.data ?? {}).toEntity();
      return Right<Failure, BookingEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, BookingEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, BookingEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) async {
    try {
      final path = ApiEndpoints.bookingDetail.replaceAll('{id}', id);
      final res = await _dio.get<Map<String, dynamic>>(path);
      final entity = BookingModel.fromJson(res.data ?? {}).toEntity();
      return Right<Failure, BookingEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, BookingEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, BookingEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> confirmBookingPayment({
    required String bookingId,
    required String paymentRef,
  }) async {
    try {
      final path = ApiEndpoints.confirmBooking.replaceAll('{id}', bookingId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'paymentRef': paymentRef},
      );
      final entity = BookingModel.fromJson(res.data ?? {}).toEntity();
      return Right<Failure, BookingEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, BookingEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, BookingEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) async {
    try {
      final path = ApiEndpoints.cancelBooking.replaceAll('{id}', bookingId);
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'reason': reason},
      );
      final entity = BookingModel.fromJson(res.data ?? {}).toEntity();
      return Right<Failure, BookingEntity>(entity);
    } on DioException catch (e) {
      return Left<Failure, BookingEntity>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, BookingEntity>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  @override
  Stream<BookingEntity> watchBookingStatus(String bookingId) {
    // Polling 3s — sẽ thay bằng WebSocket ở Task 4.
    return Stream.periodic(const Duration(seconds: 3))
        .asyncMap((_) async {
      final path = ApiEndpoints.bookingStatus.replaceAll('{id}', bookingId);
      final res = await _dio.get<Map<String, dynamic>>(path);
      return BookingModel.fromJson(res.data ?? {}).toEntity();
    });
  }

  @override
  Future<Either<Failure, List<BookingHistoryEntity>>> getBookingHistory() async {
    try {
      final res = await _dio.get<List<dynamic>>(ApiEndpoints.bookingHistory);
      final items = (res.data ?? [])
          .cast<Map<String, dynamic>>()
          .map(BookingHistoryModel.fromJson)
          .map((m) => m.toEntity())
          .toList();
      return Right<Failure, List<BookingHistoryEntity>>(items);
    } on DioException catch (e) {
      return Left<Failure, List<BookingHistoryEntity>>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, List<BookingHistoryEntity>>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────

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
      case 404:
        return ServerFailure(
          message: apiMsg ?? 'Không tìm thấy tài nguyên',
          statusCode: code,
        );
      case 409:
        return ServerFailure(
          message: apiMsg ?? 'Xung đột',
          statusCode: code,
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: 'Lỗi server ($code)',
          statusCode: code,
        );
      default:
        return NetworkFailure(message: e.message ?? 'Không thể kết nối server');
    }
  }
}