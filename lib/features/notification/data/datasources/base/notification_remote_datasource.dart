import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/device_token_entity.dart';

abstract class NotificationRemoteDatasource {
  Future<Either<Failure, DeviceTokenEntity>> registerDeviceToken(
    RegisterDeviceTokenEntity payload,
  );

  Future<Either<Failure, Unit>> deleteDeviceToken(String id);
}
