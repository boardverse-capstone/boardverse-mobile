import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/core/network/api_response.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/karma_history_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/player_location_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:boardverse_mobile/features/profile/data/datasources/profile_remote_datasource.dart';
import 'package:boardverse_mobile/features/profile/data/models/create_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/karma_history_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/player_location_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/profile_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_avatar_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_location_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_progress_request_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl({required this.remoteDatasource});

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() => _guardEntity(
        remoteDatasource.getProfile(),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, ProfileEntity>> createProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) =>
      _guardEntity(
        remoteDatasource.createProfile(
          CreateProfileRequestModel(
            bio: bio,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
            phoneNumber: phoneNumber,
          ),
        ),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  }) =>
      _guardEntity(
        remoteDatasource.updateProfile(
          UpdateProfileRequestModel(
            bio: bio,
            firstName: firstName,
            lastName: lastName,
            dateOfBirth: dateOfBirth,
          ),
        ),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, ProfileEntity>> updateAvatar(String avatarUrl) =>
      _guardEntity(
        remoteDatasource.updateAvatar(
          UpdateAvatarRequestModel(avatarUrl: avatarUrl),
        ),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, void>> deleteProfile() => _guardVoid(
        remoteDatasource.deleteProfile(),
      );

  @override
  Future<Either<Failure, PlayerLocationEntity>> getLocation() => _guardEntity(
        remoteDatasource.getLocation(),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, PlayerLocationEntity>> updateLocation({
    required double latitude,
    required double longitude,
    required int source,
  }) =>
      _guardEntity(
        remoteDatasource.updateLocation(
          UpdateLocationRequestModel(
            latitude: latitude,
            longitude: longitude,
            source: source,
          ),
        ),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, void>> deleteLocation() => _guardVoid(
        remoteDatasource.deleteLocation(),
      );

  @override
  Future<Either<Failure, KarmaHistoryEntity>> getKarmaHistory() =>
      _guardEntity(
        remoteDatasource.getKarmaHistory(),
        (model) => model.toEntity(),
      );

  @override
  Future<Either<Failure, ProfileEntity>> updateProgress({
    required int globalElo,
    required int level,
  }) =>
      _guardEntity(
        remoteDatasource.updateProgress(
          UpdateProgressRequestModel(
            globalElo: globalElo,
            level: level,
          ),
        ),
        (model) => model.toEntity(),
      );

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Centralised error-guard for endpoints that return a typed model.
  ///
  /// Runs the [remoteCall], unwraps the typed payload via [extract], and
  /// converts any [ServerException] / [DioException] / unexpected error into
  /// the corresponding [Failure].
  Future<Either<Failure, T>> _guardEntity<M, T>(
    Future<ApiResponse<M>> remoteCall,
    T Function(M model) extract,
  ) async {
    try {
      final response = await remoteCall;
      final model = response.data;
      if (model == null) {
        return const Left(
          ServerFailure(message: 'API trả về dữ liệu rỗng.'),
        );
      }
      return Right(extract(model));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  /// Same as `_guardEntity` but discards the response body (e.g. `DELETE`).
  Future<Either<Failure, void>> _guardVoid(
    Future<ApiResponse<dynamic>> remoteCall,
  ) async {
    try {
      await remoteCall;
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  Failure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final data = e.response?.data;
        if (data is Map<String, dynamic> && data.containsKey('message')) {
          return ServerFailure(
            message: data['message'] as String,
            statusCode: e.response?.statusCode,
          );
        }
        return ServerFailure(
          message: e.message ?? 'Đã xảy ra lỗi không mong muốn.',
          statusCode: e.response?.statusCode,
        );
      default:
        return ServerFailure(
          message: e.message ?? 'Đã xảy ra lỗi không mong muốn.',
        );
    }
  }
}
