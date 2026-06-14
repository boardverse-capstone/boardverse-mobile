import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/in_game_session_entity.dart';

abstract class InGameRepository {
  Future<Either<Failure, InGameSessionEntity>> checkIn({
    required String bookingId,
  });

  Stream<InGameSessionEntity> watchSession(String sessionId);

  Future<Either<Failure, void>> reportMissingComponent(String sessionId, String componentName, int quantity);

  Future<Either<Failure, void>> completeSession(String sessionId);
}
