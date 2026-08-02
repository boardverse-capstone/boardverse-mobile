import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/cafe_availability_entity.dart';

/// API lấy capacity tổng quát + slot thay thế khi hết chỗ
/// (xem `.agents/docs/apis_docs/cafe-booking.md` §74-122 — gap #2).
///
/// Mobile `BoardGameDetailPage` gọi trước khi navigate sang BookingSummary
/// để cảnh báo "quán hết chỗ" và gợi ý `alternativeSlots` nếu cần.
abstract class CafeAvailabilityRemoteDatasource {
  /// GET /api/cafes/{cafeId}/availability
  ///
  /// Trả về thông tin capacity + alternative slots trong khung giờ.
  /// Cache ngắn hạn 30s ở client là khuyến nghị (xem doc §139).
  Future<Either<Failure, CafeAvailabilityEntity>> getAvailability({
    required String cafeId,
    required DateTime startTime,
    required DateTime endTime,
    int? seatCount,
    String? gameTemplateId,
  });
}
