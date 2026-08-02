import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../domain/entities/device_token_entity.dart';
import '../domain/repositories/notification_repository.dart';
import 'datasources/base/notification_remote_datasource.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDatasource datasource;

  NotificationRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, DeviceTokenEntity>> registerDeviceToken(
    RegisterDeviceTokenEntity payload,
  ) =>
      datasource.registerDeviceToken(payload);

  @override
  Future<Either<Failure, Unit>> deleteDeviceToken(String id) =>
      datasource.deleteDeviceToken(id);
}