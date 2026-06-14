import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/in_game_session_entity.dart';
import '../domain/repositories/in_game_repository.dart';
import 'datasources/mock_in_game_datasource.dart';
import 'models/in_game_session_model.dart';

class InGameRepositoryImpl implements InGameRepository {
  final _sessionStreamController =
      StreamController<InGameSessionModel>.broadcast();

  InGameRepositoryImpl();

  @override
  Future<Either<Failure, InGameSessionEntity>> checkIn({
    required String bookingId,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final session = MockInGameDatasource.mockActiveSessionDetails;
      return Right(session.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi check-in: ${e.toString()}'));
    }
  }

  @override
  Stream<InGameSessionEntity> watchSession(String sessionId) {
    _sessionStreamController.add(MockInGameDatasource.mockActiveSessionDetails);
    return _sessionStreamController.stream.map((m) => m.toEntity());
  }

  @override
  Future<Either<Failure, void>> reportMissingComponent(
    String sessionId,
    String componentName,
    int quantity,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi báo cáo: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> completeSession(String sessionId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi hoàn tất: ${e.toString()}'));
    }
  }

  void dispose() {
    _sessionStreamController.close();
  }
}
