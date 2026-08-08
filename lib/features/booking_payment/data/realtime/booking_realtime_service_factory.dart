import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/realtime/booking_realtime_service.dart';

/// Factory trì hoãn việc khởi tạo `BookingRealtimeService` cho tới khi
/// có access token. Service SignalR bắt buộc phải có JWT trước khi
/// `connect()` được gọi — nên ta không thể đăng ký service dưới dạng
/// `lazySingleton` ngay từ app boot.
///
/// Usage:
/// ```dart
/// final factory = sl<BookingRealtimeServiceFactory>();
/// final service = await factory.getOrCreate();
/// ```
class BookingRealtimeServiceFactory {
  BookingRealtimeService? _service;
  final FlutterSecureStorage _storage;

  BookingRealtimeServiceFactory({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Trả về service hiện tại (hoặc tạo mới nếu chưa có).
  /// Đọc token từ secure storage mỗi lần — đảm bảo token mới nhất
  /// (sau refresh) được dùng.
  Future<BookingRealtimeService> getOrCreate() async {
    if (_service != null && _service!.isConnected) return _service!;
    final token = await _readAccessToken();
    _service = BookingRealtimeService(token);
    return _service!;
  }

  /// Đóng + xoá instance hiện tại. Dùng khi logout.
  Future<void> dispose() async {
    final svc = _service;
    if (svc != null) {
      await svc.dispose();
    }
    _service = null;
  }

  /// Trả về service ngay lập tức nếu đã tạo (có thể null). Dùng cho
  /// cleanup ngay từ UI mà không cần chờ đọc token.
  BookingRealtimeService? get currentOrNull => _service;

  Future<String> _readAccessToken() async {
    return await _storage.read(key: 'access_token') ?? '';
  }
}