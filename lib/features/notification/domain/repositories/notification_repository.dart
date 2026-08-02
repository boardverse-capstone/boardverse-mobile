import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/device_token_entity.dart';

/// Domain repository cho Notification module (FCM device tokens).
abstract class NotificationRepository {
  /// POST /api/notifications/device-tokens — đăng ký / cập nhật FCM token.
  ///
  /// Idempotent: gọi nhiều lần với cùng token sẽ UPDATE timestamp + re-enable.
  Future<Either<Failure, DeviceTokenEntity>> registerDeviceToken(
    RegisterDeviceTokenEntity payload,
  );

  /// DELETE /api/notifications/device-tokens/{id} — xóa khi logout / gỡ app.
  Future<Either<Failure, Unit>> deleteDeviceToken(String id);
}
