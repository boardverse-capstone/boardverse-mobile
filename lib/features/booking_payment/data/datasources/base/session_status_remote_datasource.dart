import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/session_status_entity.dart';

/// GET /api/bookings/{bookingId}/session-status (xem `.agents/docs/apis_docs/booking.md`
/// §191-227 — gap #8).
///
/// Mobile gọi khi `BookingDetailPage` ở status `CheckedIn` để hiển thị
/// realtime ai về sớm + bill ước tính cuối cùng.
abstract class SessionStatusRemoteDatasource {
  Future<Either<Failure, SessionStatusEntity>> getSessionStatus(
    String bookingId,
  );
}
