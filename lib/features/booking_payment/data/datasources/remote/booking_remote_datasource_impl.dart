import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/booking_entity.dart';
import '../../../domain/entities/booking_history_entity.dart';
import '../../../domain/entities/deposit_config_entity.dart';
import '../../../domain/entities/deposit_payment_entity.dart';
import '../../../domain/entities/deposit_status_entity.dart';
import '../../../domain/entities/lobby_booking_summary_entity.dart';
import '../../models/booking_model.dart';
import '../../models/deposit_config_model.dart';
import '../../models/deposit_payment_model.dart';
import '../../models/deposit_status_model.dart';
import '../base/booking_remote_datasource.dart';

/// Triển khai gọi REST API thật qua [Dio] — đặc tả `.agents/docs/apis_docs/booking.md` + `payment.md`.
///
/// Mọi response đều parse `ApiResponse.fromJson` (envelope `data`).
/// Lỗi map sang `Failure` thông qua `Failure.fromApiResponse` sau khi
/// unwrap từ `DioException`.
class BookingRemoteDatasourceImpl implements BookingRemoteDatasource {
  final Dio dio;

  BookingRemoteDatasourceImpl({required this.dio});

  // ─── Booking CRUD ─────────────────────────────────────────────────

  @override
  Future<Either<Failure, DepositConfigEntity>> getDepositConfig(
    String cafeId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.depositConfig.replaceAll('{cafeId}', cafeId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositConfigModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, BookingEntity>> createBooking({
    String? lobbyId,
    required String cafeId,
    required String cafeTableId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    int? playerQuantity,
  }) =>
      _wrap(() async {
        final body = <String, dynamic>{
          // Walk-in: cho phép lobbyId = null (gap #3).
          'lobbyId': lobbyId,
          'cafeId': cafeId,
          'cafeTableId': cafeTableId,
          'scheduledStartTime': scheduledStartTime.toUtc().toIso8601String(),
          'scheduleEndTime': scheduleEndTime.toUtc().toIso8601String(),
          'playerQuantity': ?playerQuantity,
        };
        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.bookingCreate,
          data: body,
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return BookingModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, BookingEntity>> getBookingById(String id) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingDetail.replaceAll('{id}', id);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return BookingModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, BookingEntity?>> getBookingByLobby(String lobbyId) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingByLobby.replaceAll('{lobbyId}', lobbyId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<dynamic>.fromJson(res.data ?? const {});
        if (api.statusCode == 404) {
          return null;
        }
        _ensureSuccess(api);
        final data = api.data;
        if (data == null) return null;
        return BookingModel.fromJson(data as Map<String, dynamic>).toEntity();
      });

  @override
  Future<Either<Failure, BookingEntity>> cancelBookingByPlayer({
    required String bookingId,
    required String reason,
  }) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingCancel.replaceAll('{id}', bookingId);
        final res = await dio.delete<Map<String, dynamic>>(
          path,
          queryParameters: {'reason': reason},
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return BookingModel.fromJson(api.data ?? const {}).toEntity();
      });

  // ─── Payments ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, DepositPaymentEntity>> createDepositPayment(
    String bookingId,
  ) =>
      _wrap(() async {
        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.bookingDeposit,
          data: {'bookingId': bookingId},
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, DepositPaymentEntity>>
      createDepositPaymentWithDetails({
    required String bookingId,
    String? cafeId,
    String? lobbyId,
    DateTime? scheduledStartTime,
    int? seatCount,
    double? amount,
  }) =>
          _wrap(() async {
            final body = <String, dynamic>{'bookingId': bookingId};
            if (cafeId != null) body['cafeId'] = cafeId;
            if (lobbyId != null) body['lobbyId'] = lobbyId;
            if (scheduledStartTime != null) {
              body['scheduledStartTime'] =
                  scheduledStartTime.toUtc().toIso8601String();
            }
            if (seatCount != null) body['seatCount'] = seatCount;
            if (amount != null) body['amount'] = amount;

            final res = await dio.post<Map<String, dynamic>>(
              ApiEndpoints.bookingDeposit,
              data: body,
            );
            final api = ApiResponse<Map<String, dynamic>>.fromJson(
              res.data ?? const {},
              fromJsonT: (json) => json as Map<String, dynamic>,
            );
            _ensureSuccess(api);
            return DepositPaymentModel.fromJson(api.data ?? const {})
                .toEntity();
          });

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositStatus(
    String depositId,
  ) =>
      _wrap(() async {
        final path =
            ApiEndpoints.bookingDepositDetail.replaceAll('{id}', depositId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, DepositStatusEntity>> getDepositByOrder(
    String orderId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingDepositByOrder
            .replaceAll('{orderId}', orderId);
        final res = await dio.get<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, DepositPaymentEntity>> regenerateDepositQr(
    String depositId,
  ) =>
      _wrap(() async {
        final path = ApiEndpoints.bookingDepositRegenerateQr
            .replaceAll('{id}', depositId);
        final res = await dio.post<Map<String, dynamic>>(path);
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositPaymentModel.fromJson(api.data ?? const {}).toEntity();
      });

  @override
  Future<Either<Failure, DepositStatusEntity>> refundDeposit({
    required String depositId,
    required String reason,
  }) =>
      _wrap(() async {
        final res = await dio.post<Map<String, dynamic>>(
          ApiEndpoints.bookingDepositRefund,
          data: {
            'depositId': depositId,
            'reason': reason,
          },
        );
        final api = ApiResponse<Map<String, dynamic>>.fromJson(
          res.data ?? const {},
          fromJsonT: (json) => json as Map<String, dynamic>,
        );
        _ensureSuccess(api);
        return DepositStatusModel.fromJson(api.data ?? const {}).toEntity();
      });

  // ─── Lobby helpers ────────────────────────────────────────────────

  @override
  Future<Either<Failure, LobbyBookingSummaryEntity>> getLobbyBookingSummary(
    String lobbyId,
  ) =>
      _wrap(() async {
        final result = await getBookingByLobby(lobbyId);
        return result.fold(
          (failure) => throw failure, // caught by _wrap
          (booking) => LobbyBookingSummaryEntity(
            lobbyId: lobbyId,
            bookingId: booking?.id,
          ),
        );
      });

  @override
  Future<Either<Failure, List<String>>> getHostedLobbyIds() =>
      _wrap(() async {
        final res = await dio.get<Map<String, dynamic>>(
          ApiEndpoints.lobbyHosted,
        );
        final api = ApiResponse<dynamic>.fromJson(res.data ?? const {});
        _ensureSuccess(api);
        return _extractLobbyIds(api.data);
      });

  @override
  Future<Either<Failure, List<String>>> getJoinedLobbyIds() =>
      _wrap(() async {
        final res = await dio.get<Map<String, dynamic>>(
          ApiEndpoints.lobbyJoined,
        );
        final api = ApiResponse<dynamic>.fromJson(res.data ?? const {});
        _ensureSuccess(api);
        return _extractLobbyIds(api.data);
      });

  static List<String> _extractLobbyIds(dynamic raw) {
    if (raw is List) {
      return raw
          .map((e) => (e as Map<String, dynamic>)['id'] as String?)
          .whereType<String>()
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final items = raw['items'] ?? raw['data'] ?? raw['lobbies'];
      if (items is List) {
        return items
            .map((e) => (e as Map<String, dynamic>)['id'] as String?)
            .whereType<String>()
            .toList();
      }
    }
    return const [];
  }

  @override
  Future<List<BookingHistoryEntity>> noopHistoryShim() async => const [];

  // ─── Helpers ──────────────────────────────────────────────────────

  /// Mọi promise trong repo đều wrap qua đây — trả `Either<Failure, T>`.
  Future<Either<Failure, T>> _wrap<T>(Future<T> Function() body) async {
    try {
      final value = await body();
      return Right<Failure, T>(value);
    } on Failure catch (f) {
      return Left<Failure, T>(f);
    } on DioException catch (e) {
      return Left<Failure, T>(_mapDioError(e));
    } catch (e) {
      return Left<Failure, T>(
        ServerFailure(message: 'Lỗi không xác định: $e'),
      );
    }
  }

  void _ensureSuccess(ApiResponse<dynamic> api) {
    if (api.isSuccess) return;
    throw FailureFromApiResponseX.fromApiResponse(
      api,
      fallbackMessage: 'Yêu cầu thất bại (${api.statusCode})',
    );
  }

  Failure _mapDioError(DioException e) {
    final code = e.response?.statusCode;
    final apiMsg = e.response?.data is Map
        ? (e.response!.data as Map)['message']?.toString()
        : null;

    switch (code) {
      case 400:
        return BadRequestFailure(message: apiMsg ?? 'Dữ liệu không hợp lệ');
      case 401:
        return UnauthorizedFailure(
          message: apiMsg ?? 'Phiên đăng nhập hết hạn',
        );
      case 403:
        return ForbiddenFailure(message: apiMsg ?? 'Bạn không có quyền');
      case 404:
        return NotFoundFailure(message: apiMsg ?? 'Không tìm thấy tài nguyên');
      case 409:
        return ConflictFailure(message: apiMsg ?? 'Xung đột dữ liệu');
      case 429:
        return RateLimitFailure(
          message: apiMsg ?? 'Bạn thao tác quá nhanh, thử lại sau',
        );
      case 500:
      case 502:
      case 503:
        return ServerFailure(
          message: apiMsg ?? 'Lỗi server ($code)',
          statusCode: code,
        );
      default:
        return NetworkFailure(
          message: e.message ?? 'Không thể kết nối server',
        );
    }
  }
}
