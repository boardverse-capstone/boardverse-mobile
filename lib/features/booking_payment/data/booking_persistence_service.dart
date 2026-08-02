import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service lưu state `pendingBookingId` + `pendingDepositId` để resume
/// flow sau khi kill app.
///
/// Pattern tham chiếu: `lib/features/lobby_management/data/lobby_persistence_service.dart`.
class BookingPersistenceService {
  static const _pendingBookingKey = 'pending_booking_id';
  static const _pendingDepositKey = 'pending_deposit_id';

  final FlutterSecureStorage _storage;

  BookingPersistenceService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  // ─── Booking ──────────────────────────────────────────────────────
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

  // ─── Deposit ──────────────────────────────────────────────────────
  Future<void> savePendingDepositId(String id) async {
    await _storage.write(key: _pendingDepositKey, value: id);
  }

  Future<String?> getPendingDepositId() async {
    return _storage.read(key: _pendingDepositKey);
  }

  Future<void> clearPendingDepositId() async {
    await _storage.delete(key: _pendingDepositKey);
  }

  // ─── Logout ───────────────────────────────────────────────────────
  Future<void> clearAll() async {
    await _storage.delete(key: _pendingBookingKey);
    await _storage.delete(key: _pendingDepositKey);
  }
}
