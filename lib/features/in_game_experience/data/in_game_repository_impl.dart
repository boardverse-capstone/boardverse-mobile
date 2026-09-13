import 'dart:async';
import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/in_game_session_entity.dart';
import '../domain/entities/player_session_entity.dart';
import '../domain/entities/session_payment_entity.dart';
import '../domain/entities/session_history_entity.dart';
import '../domain/repositories/in_game_repository.dart';
import 'datasources/player_session_remote_datasource.dart';
import 'models/in_game_session_model.dart';

class InGameRepositoryImpl implements InGameRepository {
  final PlayerSessionRemoteDatasource _playerSessionDatasource;
  final _sessionStreamController =
      StreamController<InGameSessionModel>.broadcast();

  InGameRepositoryImpl({required this._playerSessionDatasource});

  @override
  Future<Either<Failure, PlayerSessionEntity>> getCurrentSession() async {
    try {
      final result = await _playerSessionDatasource.getCurrentSession();
      return Right(result.toEntity());
    } on PlayerSessionNotFoundException {
      return Left(ServerFailure(message: 'Không có phiên chơi nào đang hoạt động.'));
    } on PlayerSessionConflictException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExtensionRequestEntity>> requestExtension(int minutes) async {
    try {
      final result = await _playerSessionDatasource.extendSession(minutes);
      return Right(ExtensionRequestEntity(
        requestId: result.requestId,
        sessionId: result.sessionId,
        requestedMinutes: result.requestedMinutes,
        estimatedAdditionalCostVnd: result.estimatedAdditionalCostVnd,
        status: result.status,
        success: result.success,
        message: result.message,
        newEndTime: result.newEndTime,
        totalMinutesBooked: result.totalMinutesBooked,
      ));
    } on PlayerSessionConflictException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, SessionPaymentResultEntity>> payWithBvc(String sessionId) async {
    try {
      final result = await _playerSessionDatasource.paySession(sessionId);
      return Right(result.toEntity());
    } on InsufficientBvcException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionConflictException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<SessionHistoryEntity>>> getSessionHistory({
    int limit = 20,
    DateTime? beforePaidAt,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final result = await _playerSessionDatasource.getSessionHistory(
        limit: limit,
        beforePaidAt: beforePaidAt,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Right(result.items.map((e) => e.toEntity()).toList());
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<MemberPaymentInfo>>> getSplitBillMembers() async {
    try {
      final result = await _playerSessionDatasource.getSplitBillSession();
      return Right(result.members.map((e) => e.toEntity()).toList());
    } on PlayerSessionNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, MemberPaymentInfo>> getMyMemberPaymentInfo() async {
    try {
      final result = await _playerSessionDatasource.getMyMemberPaymentInfo();
      return Right(result.toEntity());
    } on PlayerSessionNotFoundException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on PlayerSessionApiException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi kết nối: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, InGameSessionEntity>> checkIn({
    required String bookingId,
  }) async {
    try {
      // Ưu tiên dùng API mới để lấy phiên hiện tại
      final currentSession = await _playerSessionDatasource.getCurrentSession();
      // Convert sang InGameSessionEntity cho tương thích
      final session = InGameSessionModel(
        sessionId: currentSession.sessionId,
        bookingId: bookingId,
        cafeId: currentSession.cafeId,
        cafeName: currentSession.cafeName,
        gameId: '',
        gameName: currentSession.gameName,
        tableNumber: 1, // API mới không trả tableNumber
        players: const [],
        startTime: currentSession.joinedAt,
        status: InGameSessionStatusModel.active,
        playDuration: Duration(minutes: currentSession.elapsedMinutes),
        isCheckingInventory: false,
      );
      return Right(session.toEntity());
    } on PlayerSessionNotFoundException {
      // Fallback: tạo session từ bookingId (legacy behavior)
      await Future.delayed(const Duration(milliseconds: 500));
      final mockSession = _createMockSession(bookingId);
      return Right(mockSession.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi check-in: ${e.toString()}'));
    }
  }

  @override
  Stream<InGameSessionEntity> watchSession(String sessionId) {
    // Ưu tiên dùng API mới
    _fetchAndEmitSession();
    return _sessionStreamController.stream.map((m) => m.toEntity());
  }

  Future<void> _fetchAndEmitSession() async {
    try {
      final currentSession = await _playerSessionDatasource.getCurrentSession();
      final session = InGameSessionModel(
        sessionId: currentSession.sessionId,
        bookingId: '',
        cafeId: currentSession.cafeId,
        cafeName: currentSession.cafeName,
        gameId: '',
        gameName: currentSession.gameName,
        tableNumber: 1,
        players: const [],
        startTime: currentSession.joinedAt,
        status: InGameSessionStatusModel.active,
        playDuration: Duration(minutes: currentSession.elapsedMinutes),
        isCheckingInventory: false,
      );
      _sessionStreamController.add(session);
    } catch (_) {
      // Ignore errors in watch mode
    }
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

  InGameSessionModel _createMockSession(String bookingId) {
    return InGameSessionModel(
      sessionId: 'session_001',
      bookingId: bookingId,
      cafeId: 'cafe_001',
      cafeName: 'Board Game Hub District 1',
      gameId: 'bg_001',
      gameName: 'Avalon: The Resistance Game',
      tableNumber: 5,
      players: const [],
      startTime: DateTime.now().subtract(const Duration(hours: 1)),
      status: InGameSessionStatusModel.active,
      playDuration: const Duration(hours: 1),
      isCheckingInventory: false,
    );
  }

  void dispose() {
    _sessionStreamController.close();
  }
}
