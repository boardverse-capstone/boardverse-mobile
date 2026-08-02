import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/cafe_table_entity.dart';

/// Nguồn dữ liệu bàn trống dành cho Player booking flow.
abstract class CafeTableRemoteDatasource {
  Future<Either<Failure, List<CafeTableEntity>>> getAvailableTables({
    required String cafeId,
    required DateTime scheduledStartTime,
    required DateTime scheduleEndTime,
    required int seatCount,
  });
}
