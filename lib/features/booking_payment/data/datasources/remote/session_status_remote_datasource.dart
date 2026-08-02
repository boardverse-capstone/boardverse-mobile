import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/session_member_entity.dart';
import '../../../domain/entities/session_status_entity.dart';
import '../base/session_status_remote_datasource.dart';

/// Dio implementation cho `GET /api/bookings/{bookingId}/session-status`
/// (gap #8).
///
/// Response schema mirror `.agents/docs/apis_docs/booking.md` §197-227.
class SessionStatusRemoteDatasourceImpl
    implements SessionStatusRemoteDatasource {
  final Dio dio;

  SessionStatusRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, SessionStatusEntity>> getSessionStatus(
    String bookingId,
  ) async {
    try {
      final path = ApiEndpoints.bookingSessionStatus
          .replaceAll('{bookingId}', bookingId);
      final response = await dio.get<Map<String, dynamic>>(path);
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      if (!api.isSuccess || api.data == null) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể lấy trạng thái phiên chơi',
          ),
        );
      }
      return Right(_parseEntity(api.data!));
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      switch (code) {
        case 403:
          return Left(
            ForbiddenFailure(
              message: message ?? 'Bạn không phải lobby member đã check-in',
            ),
          );
        case 404:
          return Left(
            NotFoundFailure(message: message ?? 'Không tìm thấy booking'),
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
        ServerFailure(message: 'Không thể đọc trạng thái phiên: $error'),
      );
    }
  }

  SessionStatusEntity _parseEntity(Map<String, dynamic> json) {
    final membersRaw = (json['members'] as List?) ?? const <dynamic>[];
    final members = membersRaw
        .whereType<Map<String, dynamic>>()
        .map(_parseMember)
        .toList();

    EstimatedBillEntity? estimatedBill;
    final billRaw = json['estimatedFinalBill'];
    if (billRaw is Map<String, dynamic>) {
      estimatedBill = EstimatedBillEntity(
        subtotal: (billRaw['subtotal'] as num?)?.toDouble() ?? 0,
        penalty: (billRaw['penalty'] as num?)?.toDouble() ?? 0,
        depositApplied: (billRaw['depositApplied'] as num?)?.toDouble() ?? 0,
        total: (billRaw['total'] as num?)?.toDouble() ?? 0,
      );
    }

    return SessionStatusEntity(
      bookingId: json['bookingId'] as String? ?? '',
      activeSessionId: json['activeSessionId'] as String?,
      sessionStatus: json['sessionStatus'] as String? ?? 'Active',
      startedAt: json['startedAt'] is String
          ? DateTime.parse(json['startedAt'] as String).toLocal()
          : null,
      currentDurationMinutes:
          (json['currentDurationMinutes'] as num?)?.toInt() ?? 0,
      members: members,
      estimatedFinalBill: estimatedBill,
    );
  }

  SessionMemberEntity _parseMember(Map<String, dynamic> json) {
    final statusRaw = json['status'] as String? ?? 'Active';
    return SessionMemberEntity(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String? ?? '',
      status: _parseStatus(statusRaw),
      leftAt: json['leftAt'] is String
          ? DateTime.parse(json['leftAt'] as String).toLocal()
          : null,
      partialBillAmount: (json['partialBillAmount'] as num?)?.toDouble() ?? 0,
      partialBillPaid: json['partialBillPaid'] as bool? ?? false,
      mergedIntoSessionId: json['mergedIntoSessionId'] as String?,
    );
  }

  SessionMemberStatus _parseStatus(String raw) {
    switch (raw) {
      case 'LeftEarly':
        return SessionMemberStatus.leftEarly;
      case 'CheckedOut':
        return SessionMemberStatus.checkedOut;
      case 'Active':
      default:
        return SessionMemberStatus.active;
    }
  }
}
