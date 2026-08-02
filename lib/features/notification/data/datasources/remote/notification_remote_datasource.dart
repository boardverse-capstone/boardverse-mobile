import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/error/failures.dart';
import '../../../../../core/network/api_response.dart';
import '../../../domain/entities/device_token_entity.dart';
import '../base/notification_remote_datasource.dart';

/// Dio implementation cho `POST/DELETE /api/notifications/device-tokens`.
class NotificationRemoteDatasourceImpl
    implements NotificationRemoteDatasource {
  final Dio dio;

  NotificationRemoteDatasourceImpl({required this.dio});

  @override
  Future<Either<Failure, DeviceTokenEntity>> registerDeviceToken(
    RegisterDeviceTokenEntity payload,
  ) async {
    try {
      final response = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.notificationDeviceTokens,
        data: {
          'token': payload.token,
          'platform': payload.platform,
          if (payload.appVersion != null) 'appVersion': payload.appVersion,
          if (payload.deviceModel != null) 'deviceModel': payload.deviceModel,
        },
      );
      final api = ApiResponse<Map<String, dynamic>>.fromJson(
        response.data ?? const {},
        fromJsonT: (json) => json as Map<String, dynamic>,
      );
      if (!api.isSuccess || api.data == null) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể đăng ký device token',
          ),
        );
      }
      final data = api.data!;
      return Right(
        DeviceTokenEntity(
          id: data['id'] as String? ?? '',
          userId: data['userId'] as String? ?? '',
          platform: data['platform'] as String? ?? payload.platform,
          appVersion: data['appVersion'] as String?,
          deviceModel: data['deviceModel'] as String?,
          createdAt: DateTime.parse(data['createdAt'] as String).toLocal(),
          lastSeenAt: DateTime.parse(data['lastSeenAt'] as String).toLocal(),
        ),
      );
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      switch (code) {
        case 400:
          return Left(
            BadRequestFailure(message: message ?? 'Giá trị không hợp lệ'),
          );
        case 401:
          return Left(
            UnauthorizedFailure(message: message ?? 'Thiếu token đăng nhập'),
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
        ServerFailure(message: 'Không thể đăng ký device token: $error'),
      );
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteDeviceToken(String id) async {
    try {
      final response = await dio.delete<Map<String, dynamic>>(
        ApiEndpoints.notificationDeviceTokenDelete(id),
      );
      final api = ApiResponse<dynamic>.fromJson(response.data ?? const {});
      if (!api.isSuccess) {
        return Left(
          FailureFromApiResponseX.fromApiResponse(
            api,
            fallbackMessage: 'Không thể xóa device token',
          ),
        );
      }
      return const Right(unit);
    } on DioException catch (error) {
      final code = error.response?.statusCode;
      final message = error.response?.data is Map
          ? (error.response!.data as Map)['message']?.toString()
          : null;
      if (code == 404) {
        return Left(
          NotFoundFailure(
            message: message ?? 'Không tìm thấy device token để xóa',
          ),
        );
      }
      return Left(
        NetworkFailure(
          message: message ?? error.message ?? 'Không thể kết nối server',
        ),
      );
    } catch (error) {
      return Left(
        ServerFailure(message: 'Không thể xóa device token: $error'),
      );
    }
  }
}
