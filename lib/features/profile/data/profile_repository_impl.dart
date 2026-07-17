import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:boardverse_mobile/core/error/exceptions.dart';
import 'package:boardverse_mobile/core/error/failures.dart';
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

  // ─── Profile ──────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ProfileEntity>> getProfile() async {
    try {
      final response = await remoteDatasource.getProfile();
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> createProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    try {
      final request = CreateProfileRequestModel(
        bio: bio,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
        phoneNumber: phoneNumber,
      );
      final response = await remoteDatasource.createProfile(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  }) async {
    try {
      final request = UpdateProfileRequestModel(
        bio: bio,
        firstName: firstName,
        lastName: lastName,
        dateOfBirth: dateOfBirth,
      );
      final response = await remoteDatasource.updateProfile(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, ProfileEntity>> updateAvatar(String avatarUrl) async {
    try {
      final request = UpdateAvatarRequestModel(avatarUrl: avatarUrl);
      final response = await remoteDatasource.updateAvatar(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteProfile() async {
    try {
      await remoteDatasource.deleteProfile();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  // ─── Location ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, PlayerLocationEntity>> getLocation() async {
    try {
      final response = await remoteDatasource.getLocation();
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, PlayerLocationEntity>> updateLocation({
    required double latitude,
    required double longitude,
    required int source,
  }) async {
    try {
      final request = UpdateLocationRequestModel(
        latitude: latitude,
        longitude: longitude,
        source: source,
      );
      final response = await remoteDatasource.updateLocation(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLocation() async {
    try {
      await remoteDatasource.deleteLocation();
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  // ─── Karma ────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, KarmaHistoryEntity>> getKarmaHistory() async {
    try {
      final response = await remoteDatasource.getKarmaHistory();
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  // ─── Progress ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, ProfileEntity>> updateProgress({
    required int globalElo,
    required int level,
  }) async {
    try {
      final request = UpdateProgressRequestModel(
        globalElo: globalElo,
        level: level,
      );
      final response = await remoteDatasource.updateProgress(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi đồng bộ dữ liệu: $e'));
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

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
