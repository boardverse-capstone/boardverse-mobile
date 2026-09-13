import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/paginated_response.dart';
import '../../domain/entities/entities.dart';
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

  /// Tìm kiếm reservations theo tên game và/hoặc khoảng ngày.
  ///
  /// `GET /api/v1/reservations/search` — hỗ trợ fuzzy search theo gameName
  /// và lọc theo khoảng fromDate/toDate, status, cafeId. Phục vụ Player
  /// tra cứu lại lịch hẹn trong lịch sử.
  ///
  /// Docs: `.agents/docs/apis_docs/reservation.md` §GET /search.
  /// Swagger: `.agents/docs/swagger.json` line 16375+.
  Future<Either<Failure, PaginatedResponse<ReservationModel>>> searchReservations({
    String? gameName,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? statuses,
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

  /// Cancel reservation sau khi đã check-in (BR-REFUND-04/05)
  Future<Either<Failure, ReservationCancelAfterCheckinResultModel>> cancelAfterCheckin(
    CancelAfterCheckinRequest request,
  );

  /// Check extend availability (BR-EXT-01..05)
  Future<Either<Failure, ExtendAvailabilityResultModel>> checkExtendAvailability(
    String reservationId,
    int extensionMinutes,
  );

  /// Check-in bằng QR code (POS)
  Future<Either<Failure, CheckInByCodeResultModel>> checkInByCode(
    String reservationCode,
    CheckInByCodeRequest request,
  );

  /// Lấy tất cả reservation của user (Host + Member) cho màn hình "Lịch sử".
  ///
  /// `GET /api/v1/reservations/my` — endpoint mới (Sep 2026) gộp cả host
  /// lẫn member, có 2 summary count (`hostedCount` + `joinedCount`).
  ///
  /// Mỗi item có field `participationType` (Host | Member) — frontend dùng
  /// để render UI phân biệt "Tôi tạo" vs "Tôi tham gia".
  ///
  /// Docs: `.agents/docs/apis_docs/reservation.md` §GET /my.
  Future<Either<Failure, MyReservationsRawResult>> getMyReservations({
    ReservationParticipationType? participationType,
    List<String>? statuses,
    String? cafeId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  });
}

/// Raw result từ `GET /api/v1/reservations/my` — kết hợp
/// [PaginatedResponse] với 2 summary count (hostedCount, joinedCount).
///
/// Tách riêng khỏi [MyReservationsResult] (ở domain layer) để datasource
/// không bị phụ thuộc vào entity ReservationEntity — chỉ model layer mới
/// biết cách map JSON sang entity.
class MyReservationsRawResult {
  final PaginatedResponse<ReservationModel> paginated;
  final int hostedCount;
  final int joinedCount;

  const MyReservationsRawResult({
    required this.paginated,
    required this.hostedCount,
    required this.joinedCount,
  });
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
  Future<Either<Failure, PaginatedResponse<ReservationModel>>> searchReservations({
    String? gameName,
    DateTime? fromDate,
    DateTime? toDate,
    List<String>? statuses,
    String? cafeId,
    bool? hostedByMe,
    bool? joinedByMe,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Swagger query params are PascalCase (ASP.NET Core default binding):
      //   GameName / FromDate / ToDate / Statuses / CafeId /
      //   HostedByMe / JoinedByMe / Page / PageSize
      // Sending lowercase would silently drop filters.
      final queryParams = <String, dynamic>{
        'Page': page,
        'PageSize': pageSize,
      };

      if (gameName != null && gameName.trim().isNotEmpty) {
        queryParams['GameName'] = gameName.trim();
      }
      if (fromDate != null) {
        queryParams['FromDate'] = fromDate.toIso8601String().split('T').first;
      }
      if (toDate != null) {
        queryParams['ToDate'] = toDate.toIso8601String().split('T').first;
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['Statuses'] = statuses;
      }
      if (cafeId != null && cafeId.isNotEmpty) {
        queryParams['CafeId'] = cafeId;
      }
      if (hostedByMe != null) {
        queryParams['HostedByMe'] = hostedByMe;
      }
      if (joinedByMe != null) {
        queryParams['JoinedByMe'] = joinedByMe;
      }

      final response = await dio.get(
        ApiEndpoints.reservationsSearch,
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

      return Left(ServerFailure(
          message: 'Failed to search reservations: ${response.statusCode}'));
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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

      // Backend có thể trả 200 OK hoặc 201 Created tuỳ endpoint
      // (createQuote/confirmReservation thường 201, cancel có thể 200).
      // Coi cả 2xx là thành công để tránh UI báo "Failed to confirm
      // reservation: 201" khi backend đúng chuẩn HTTP semantics.
      if (response.statusCode == 200 || response.statusCode == 201) {
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

      if (response.statusCode == 200 || response.statusCode == 201) {
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

  @override
  Future<Either<Failure, ReservationCancelAfterCheckinResultModel>>
      cancelAfterCheckin(CancelAfterCheckinRequest request) async {
    try {
      final response = await dio.post(
        ApiEndpoints.reservationCancelAfterCheckin(request.reservationId),
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        return Right(
          ReservationCancelAfterCheckinResultModel.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }

      return Left(ServerFailure(
        message: 'Failed to cancel after checkin: ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExtendAvailabilityResultModel>>
      checkExtendAvailability(
    String reservationId,
    int extensionMinutes,
  ) async {
    try {
      final response = await dio.get(
        ApiEndpoints.reservationExtendAvailability(reservationId),
        queryParameters: {'extensionMinutes': extensionMinutes},
      );

      if (response.statusCode == 200) {
        return Right(
          ExtendAvailabilityResultModel.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }

      return Left(ServerFailure(
        message: 'Failed to check extend availability: ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CheckInByCodeResultModel>> checkInByCode(
    String reservationCode,
    CheckInByCodeRequest request,
  ) async {
    try {
      final response = await dio.post(
        ApiEndpoints.reservationCheckInByCode(reservationCode),
        data: request.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Right(
          CheckInByCodeResultModel.fromJson(
            response.data as Map<String, dynamic>,
          ),
        );
      }

      return Left(ServerFailure(
        message: 'Failed to check in by code: ${response.statusCode}',
      ));
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MyReservationsRawResult>> getMyReservations({
    ReservationParticipationType? participationType,
    List<String>? statuses,
    String? cafeId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Swagger query params are PascalCase (ASP.NET Core default binding):
      //   ParticipationType / Statuses / CafeId / FromDate / ToDate /
      //   Page / PageSize
      // Sending lowercase would silently drop filters.
      final queryParams = <String, dynamic>{
        'Page': page,
        'PageSize': pageSize,
      };

      if (participationType != null) {
        queryParams['ParticipationType'] = participationType.apiValue;
      }
      if (statuses != null && statuses.isNotEmpty) {
        queryParams['Statuses'] = statuses;
      }
      if (cafeId != null && cafeId.isNotEmpty) {
        queryParams['CafeId'] = cafeId;
      }
      if (fromDate != null) {
        queryParams['FromDate'] = fromDate.toIso8601String().split('T').first;
      }
      if (toDate != null) {
        queryParams['ToDate'] = toDate.toIso8601String().split('T').first;
      }

      final response = await dio.get(
        ApiEndpoints.reservationsMy,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>?;
        if (data == null) {
          return Right(MyReservationsRawResult(
            paginated: PaginatedResponse<ReservationModel>(
              items: const [],
              page: page,
              pageSize: pageSize,
              totalItems: 0,
              totalPages: 0,
              hasNextPage: false,
              hasPreviousPage: false,
            ),
            hostedCount: 0,
            joinedCount: 0,
          ));
        }

        final paginated = PaginatedResponse<ReservationModel>.fromJson(
          data,
          ReservationModel.fromJson,
        );
        // Summary counts — backend trả trong cùng envelope `data`.
        // Fallback 0 nếu backend cũ chưa trả field này.
        final hostedCount = (data['hostedCount'] as num?)?.toInt() ?? 0;
        final joinedCount = (data['joinedCount'] as num?)?.toInt() ?? 0;

        return Right(MyReservationsRawResult(
          paginated: paginated,
          hostedCount: hostedCount,
          joinedCount: joinedCount,
        ));
      }

      return Left(ServerFailure(
        message: 'Failed to get my reservations: ${response.statusCode}',
      ));
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
