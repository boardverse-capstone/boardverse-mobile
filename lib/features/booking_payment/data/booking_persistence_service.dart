import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service lưu `pendingBookingId` để resume flow sau khi kill app.
///
/// Pattern tham chiếu: `lib/features/lobby_management/data/lobby_persistence_service.dart`.
class BookingPersistenceService {
  static const _pendingBookingKey = 'pending_booking_id';

  final FlutterSecureStorage _storage;

  BookingPersistenceService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> savePendingBookingId(String id) async {
    await _storage.write(key: _pendingBookingKey, value: id);
  }

  Future<String?> getPendingBookingId() async {
    return _storage.read(key: _pendingBookingKey);
  }

  Future<void> clearPendingBookingId() async {
    await _storage.delete(key: _pendingBookingKey);
  }

  Future<bool> hasPendingBooking() async {
    final id = await getPendingBookingId();
    return id != null && id.isNotEmpty;
  }
}