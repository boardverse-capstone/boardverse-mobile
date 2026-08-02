import '../../../features/booking_payment/domain/entities/booking_entity.dart';
import '../../../features/booking_payment/domain/entities/deposit_config_entity.dart';
import '../../../features/booking_payment/domain/entities/deposit_status_entity.dart';
import '../../../features/booking_payment/domain/repositories/booking_repository.dart';

/// Helper gọn cho banner "Tiếp tục thanh toán" trên tab Bookings.
///
/// Gói gọn các bước resume flow:
/// - Ưu tiên `pendingDepositId` (vì nếu user vừa mở SePay thì đó là ID
///   duy nhất có thể fetch status realtime; trong khi `pendingBookingId`
///   có thể đã bị xoá do deep-link).
/// - Fallback về `pendingBookingId` khi không có deposit.
/// - Fetch booking + config để prefill UI.
class BookingPersistenceResumeHelper {
  final BookingRepository _repo;

  BookingPersistenceResumeHelper(this._repo);

  /// Id resume ưu tiên: deposit trước, booking sau.
  Future<String?> readPendingId() async {
    final deposit = await _repo.getPendingDepositId();
    final id = deposit.fold((_) => null, (v) => v);
    if (id != null && id.isNotEmpty) return id;
    final booking = await _repo.getPendingBookingId();
    return booking.fold((_) => null, (v) => v);
  }

  Future<void> clearPending() async {
    await _repo.clearPendingBookingId();
    await _repo.clearPendingDepositId();
  }

  Future<BookingEntity?> fetchBooking(String bookingId) async {
    final result = await _repo.getBookingById(bookingId);
    return result.fold((_) => null, (v) => v);
  }

  Future<DepositConfigEntity?> fetchDepositConfig(String cafeId) async {
    final result = await _repo.getDepositConfig(cafeId);
    return result.fold((_) => null, (v) => v);
  }

  /// Lấy trạng thái deposit (nếu `depositId` là ID thật của deposit).
  Future<DepositStatusEntity?> fetchDepositStatus(String depositId) async {
    final result = await _repo.getDepositStatus(depositId);
    return result.fold((_) => null, (v) => v);
  }

  /// Backward-compat alias — các nơi cũ đang gọi `readPendingBookingId`.
  Future<String?> readPendingBookingId() => readPendingId();
}