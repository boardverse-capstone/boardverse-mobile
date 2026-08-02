/// Domain entities cho Notification module (FCM device tokens).
///
/// Mirror `.agents/docs/apis_docs/notifications.md`.
library;

class DeviceTokenEntity {
  final String id;
  final String userId;
  final String platform;
  final String? appVersion;
  final String? deviceModel;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  const DeviceTokenEntity({
    required this.id,
    required this.userId,
    required this.platform,
    this.appVersion,
    this.deviceModel,
    required this.createdAt,
    required this.lastSeenAt,
  });
}

class RegisterDeviceTokenEntity {
  final String token;
  final String platform; // 'android' | 'ios' | 'web'
  final String? appVersion;
  final String? deviceModel;

  const RegisterDeviceTokenEntity({
    required this.token,
    required this.platform,
    this.appVersion,
    this.deviceModel,
  });
}
