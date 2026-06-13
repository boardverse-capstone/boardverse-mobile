import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/error/exceptions.dart';
import '../../../core/error/failures.dart';
import '../domain/entities/profile_entity.dart';
import '../domain/repositories/profile_repository.dart';
import 'datasources/profile_remote_datasource.dart';
import 'models/create_profile_request_model.dart';
import 'models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource remoteDatasource;

  ProfileRepositoryImpl({required this.remoteDatasource});

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
  Future<Either<Failure, ProfileEntity>> createProfile(
    CreateProfileRequestModel request,
  ) async {
    try {
      final response = await remoteDatasource.createProfile(request);
      return Right(response.data!.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on DioException catch (e) {
      return Left(_mapDioException(e));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
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
