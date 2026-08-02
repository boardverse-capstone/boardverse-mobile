import 'dart:async';

import '../../domain/realtime/fcm_push_event.dart';

/// Lightweight abstraction cho FCM. Implementation thực tế dùng
/// `firebase_messaging` package — service này expose stream push events
/// để UI cubit lắng nghe.
///
/// **Quan trọng:** Implementation `FirebaseMessagingService` thực sự được
/// viết riêng (xem file `firebase_messaging_service.dart`) — file này
/// dùng như fallback khi firebase deps chưa cài. Trong production, DI sẽ
/// register Firebase impl thay vì `NullFcmService`.
abstract class FcmService {
  Stream<FcmPushEvent> get pushEvents;
  Stream<String> get tokenRefreshEvents;
  Future<String?> getToken();
  Future<void> requestPermission();
  Future<void> dispose();
}

/// Stub dùng khi Firebase deps chưa cài — emit không gì.
class NullFcmService implements FcmService {
  final _pushCtrl = StreamController<FcmPushEvent>.broadcast();
  final _tokenCtrl = StreamController<String>.broadcast();

  @override
  Stream<FcmPushEvent> get pushEvents => _pushCtrl.stream;
  @override
  Stream<String> get tokenRefreshEvents => _tokenCtrl.stream;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> requestPermission() async {}
  @override
  Future<void> dispose() async {
    await _pushCtrl.close();
    await _tokenCtrl.close();
  }
}