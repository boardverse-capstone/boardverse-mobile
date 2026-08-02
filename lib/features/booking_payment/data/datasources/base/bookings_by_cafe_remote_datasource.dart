import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/cafe_booking_summary_entity.dart';

/// GET /api/bookings/cafe/{cafeId} (xem `.agents/docs/apis_docs/booking.md`
/// §231-253 — gap #14).
///
/// Player view trả summary rút gọn (không lộ `verificationQRCode`, `paymentRef`,
/// `memberIds`). Manager/CafeStaff/Admin trả full DTO nhưng mobile chỉ dùng
/// Player view trong luồng này.
abstract class BookingsByCafeRemoteDatasource {
  Future<Either<Failure, List<CafeBookingSummaryEntity>>> getBookingsForCafe(
    String cafeId,
  );
}
