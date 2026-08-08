import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/paginated_response.dart';
import '../models/models.dart';

/// Base interface cho reservation remote datasource
abstract class ReservationRemoteDatasource {
  /// Lấy danh sách reservations (phân trang, filter theo status/date/cafe)
  Future<Either<Failure, PaginatedResponse<ReservationModel>>> getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  });

  /// Tạo quote (không tạo DB row)
  Future<Either<Failure, ReservationQuoteModel>> createQuote(QuoteRequestModel request);

  /// Confirm reservation (atomic transaction)
  Future<Either<Failure, ReservationConfirmResultModel>> confirmReservation(
      ConfirmRequestModel request);

  /// Cancel reservation
  Future<Either<Failure, ReservationCancelResultModel>> cancelReservation(
    String reservationId,
    String? reason,
    String idempotencyKey,
  );

  /// Lấy chi tiết reservation
  Future<Either<Failure, ReservationModel>> getReservation(String reservationId);

  /// Cafe approval
  Future<Either<Failure, void>> cafeApproval(
    String reservationId,
    CafeApprovalRequestModel request,
  );
}

/// Implementation using Dio
class ReservationRemoteDatasourceImpl implements ReservationRemoteDatasource {
  final Dio dio;

  ReservationRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, PaginatedResponse<ReservationModel>>> getReservations({
    List<String>? statuses,
    DateTime? playDate,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Swagger query params are PascalCase (ASP.NET Core default binding).
      // See `.agents/docs/swagger.json` line 10204–10260:
      //   Statuses / PlayDate / CafeId / HostedByMe / JoinedByMe / Page / PageSize
      // Sending lowercase would silently drop filters.
      final queryParams = <String, dynamic>{
        'Page': page,
        'PageSize': pageSize,
      };

      if (statuses != null && statuses.isNotEmpty) {
        queryParams['Statuses'] = statuses;
      }
      if (playDate != null) {
        queryParams['PlayDate'] = playDate.toIso8601String().split('T').first;
      }
      if (cafeId != null) {
        queryParams['CafeId'] = cafeId;
      }
      if (hostedByMe != null) {
        queryParams['HostedByMe'] = hostedByMe;
      }
      if (joinedByMe != null) {
        queryParams['JoinedByMe'] = joinedByMe;
      }

      final response = await dio.get(
        ApiEndpoints.reservations,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          return Right(PaginatedResponse<ReservationModel>(
            items: [],
            page: page,
            pageSize: pageSize,
            totalItems: 0,
            totalPages: 0,
            hasNextPage: false,
            hasPreviousPage: false,
          ));
        }
        return Right(PaginatedResponse<ReservationModel>.fromJson(
          data,
          ReservationModel.fromJson,
        ));
      }

      return Left(ServerFailure(message: 'Failed to get reservations: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReservationQuoteModel>> createQuote(
      QuoteRequestModel request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.reservationQuote,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Right(
            ReservationQuoteModel.fromJson(response.data as Map<String, dynamic>));
      }

      return Left(ServerFailure(message: 'Failed to create quote: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReservationConfirmResultModel>> confirmReservation(
      ConfirmRequestModel request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.reservationConfirm,
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Right(ReservationConfirmResultModel.fromJson(
            response.data as Map<String, dynamic>));
      }

      return Left(ServerFailure(
          message: 'Failed to confirm reservation: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReservationCancelResultModel>> cancelReservation(
    String reservationId,
    String? reason,
    String idempotencyKey,
  ) async {
    try {
      final body = <String, dynamic>{'idempotencyKey': idempotencyKey};
      if (reason != null) body['reason'] = reason;
      final response = await dio.post(
        ApiEndpoints.reservationCancel(reservationId),
        data: body,
      );

      if (response.statusCode == 200) {
        return Right(ReservationCancelResultModel.fromJson(
            response.data as Map<String, dynamic>));
      }

      return Left(ServerFailure(
          message: 'Failed to cancel reservation: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ReservationModel>> getReservation(
      String reservationId) async {
    try {
      final response = await dio.get(
        ApiEndpoints.reservationDetail(reservationId),
      );

      if (response.statusCode == 200) {
        return Right(
            ReservationModel.fromJson(response.data['data'] as Map<String, dynamic>));
      }

      return Left(ServerFailure(
          message: 'Failed to get reservation: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cafeApproval(
    String reservationId,
    CafeApprovalRequestModel request,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.reservationCafeApproval(reservationId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return const Right(null);
      }

      return Left(ServerFailure(
          message: 'Failed to approve reservation: ${response.statusCode}'));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  Failure _handleDioError(DioException e) {
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] as String? ?? 'Unknown error';

      switch (statusCode) {
        case 400:
          return BadRequestFailure(message: message);
        case 401:
          return UnauthorizedFailure(message: 'Unauthorized');
        case 403:
          return ForbiddenFailure(message: message);
        case 404:
          return NotFoundFailure(message: message);
        case 409:
          return ConflictFailure(message: message);
        default:
          return ServerFailure(message: message);
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure(message: 'Connection timeout');
      case DioExceptionType.connectionError:
        return NetworkFailure(message: 'No internet connection');
      default:
        return ServerFailure(message: e.message ?? 'Unknown error');
    }
  }
}
