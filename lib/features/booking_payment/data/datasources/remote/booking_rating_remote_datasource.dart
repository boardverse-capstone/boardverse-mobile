import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/booking_rating_submission_entity.dart';
import '../../../domain/entities/no_show_vote_result_entity.dart';
import '../../../domain/entities/rating_status_entity.dart';
import '../base/booking_rating_remote_datasource.dart';

/// Dio implementation cho BookingRatingController (gap #4 + #5).
///
/// Endpoints xem `.agents/docs/apis_docs/booking-rating.md`.
class BookingRatingRemoteDatasourceImpl
    implements BookingRatingRemoteDatasource {
  final Dio dio;

  BookingRatingRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, NoShowVoteResultEntity>> submitNoShowVote({
    required String bookingId,
    required List<String> absentMemberIds,
    DateTime? votedAt,
  }) async {
    try {
      final path =
          ApiEndpoints.bookingNoShowVotes.replaceAll('{bookingId}', bookingId);
      final body = <String, dynamic>{
        'bookingId': bookingId,
        'absentMemberIds': absentMemberIds,
        if (votedAt != null) 'votedAt': votedAt.toUtc().toIso8601String(),
      };
      final response = await dio.post<Map<String, dynamic>>(path, data: body);
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      if (!api.isSuccess || api.data == null) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể ghi nhận vote no-show',
          ),
        );
      }
      return Right(_parseNoShowResult(api.data!));
    } on DioException catch (error) {
      return Left(_mapDioError(error, 'Không thể ghi nhận vote no-show'));
    } catch (error) {
      return Left(
        ServerFailure(message: 'Không thể xử lý vote no-show: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, RatingSubmissionResultEntity>> submitRatings(
    BookingRatingSubmissionEntity submission,
  ) async {
    try {
      final path =
          ApiEndpoints.bookingRatings.replaceAll('{bookingId}', submission.bookingId);
      final body = <String, dynamic>{
        'bookingId': submission.bookingId,
        'ratings': submission.ratings
            .map(
              (r) => <String, dynamic>{
                'ratedUserId': r.ratedUserId,
                'attitude': r.attitude,
                'sportsmanship': r.sportsmanship,
                'punctuality': r.punctuality,
                if (r.comment != null && r.comment!.isNotEmpty)
                  'comment': r.comment,
              },
            )
            .toList(),
      };
      final response = await dio.post<Map<String, dynamic>>(path, data: body);
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      if (!api.isSuccess || api.data == null) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể gửi chấm điểm',
          ),
        );
      }
      final data = api.data!;
      return Right(
        RatingSubmissionResultEntity(
          bookingId: data['bookingId'] as String? ?? submission.bookingId,
          voterId: data['voterId'] as String? ?? '',
          submittedAt: data['submittedAt'] is String
              ? DateTime.parse(data['submittedAt'] as String).toLocal()
              : DateTime.now(),
          ratedCount: (data['ratedCount'] as num?)?.toInt() ??
              submission.ratings.length,
        ),
      );
    } on DioException catch (error) {
      return Left(_mapDioError(error, 'Không thể gửi chấm điểm'));
    } catch (error) {
      return Left(
        ServerFailure(message: 'Không thể xử lý chấm điểm: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, RatingStatusEntity>> getRatingStatus(
    String bookingId,
  ) async {
    try {
      final path = ApiEndpoints.bookingRatingsStatus
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
            fallbackMessage: 'Không thể lấy trạng thái chấm điểm',
          ),
        );
      }
      final data = api.data!;
      return Right(
        RatingStatusEntity(
          bookingId: data['bookingId'] as String? ?? bookingId,
          canRate: data['canRate'] as bool? ?? false,
          rateDeadline: data['rateDeadline'] is String
              ? DateTime.parse(data['rateDeadline'] as String).toLocal()
              : null,
          alreadyRated: data['alreadyRated'] as bool? ?? false,
          ratedUserIds:
              (data['ratedUserIds'] as List?)?.cast<String>() ?? const [],
          missingMemberIds:
              (data['missingMemberIds'] as List?)?.cast<String>() ?? const [],
        ),
      );
    } on DioException catch (error) {
      return Left(_mapDioError(error, 'Không thể lấy trạng thái chấm điểm'));
    } catch (error) {
      return Left(
        ServerFailure(
          message: 'Không thể xử lý trạng thái chấm điểm: $error',
        ),
      );
    }
  }

  NoShowVoteResultEntity _parseNoShowResult(Map<String, dynamic> json) {
    final countsRaw = (json['currentVoteCounts'] as Map?) ?? const <dynamic, dynamic>{};
    final counts = <String, VoteCountEntity>{};
    countsRaw.forEach((key, value) {
      if (value is Map) {
        final map = value.cast<String, dynamic>();
        counts[key.toString()] = VoteCountEntity(
          absentVotes: (map['absentVotes'] as num?)?.toInt() ?? 0,
          presentVotes: (map['presentVotes'] as num?)?.toInt() ?? 0,
          totalMembers: (map['totalMembers'] as num?)?.toInt() ?? 0,
        );
      }
    });

    return NoShowVoteResultEntity(
      bookingId: json['bookingId'] as String? ?? '',
      voterId: json['voterId'] as String? ?? '',
      absentMemberIds:
          (json['absentMemberIds'] as List?)?.cast<String>() ?? const [],
      currentVoteCounts: counts,
      noShowConfirmedMembers:
          (json['noShowConfirmedMembers'] as List?)?.cast<String>() ?? const [],
      processedAt: json['processedAt'] is String
          ? DateTime.parse(json['processedAt'] as String).toLocal()
          : null,
    );
  }

  Failure _mapDioError(DioException error, String fallback) {
    final code = error.response?.statusCode;
    final message = error.response?.data is Map
        ? (error.response!.data as Map)['message']?.toString()
        : null;
    switch (code) {
      case 400:
        return BadRequestFailure(message: message ?? 'Dữ liệu không hợp lệ');
      case 403:
        return ForbiddenFailure(
          message: message ?? 'Bạn không phải lobby member',
        );
      case 404:
        return NotFoundFailure(
          message: message ?? 'Không tìm thấy booking/lobby',
        );
      case 409:
        return ConflictFailure(
          message: message ?? 'Booking không ở trạng thái cho phép',
        );
      default:
        return NetworkFailure(
          message: message ?? error.message ?? fallback,
        );
    }
  }
}
