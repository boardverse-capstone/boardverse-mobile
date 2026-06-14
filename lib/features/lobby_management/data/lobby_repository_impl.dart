import 'dart:async';

import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/lobby_entity.dart';
import '../domain/entities/friend_entity.dart';
import '../domain/repositories/lobby_repository.dart';
import 'datasources/mock_lobby_datasource.dart';
import 'models/lobby_model.dart';

class LobbyRepositoryImpl implements LobbyRepository {
  final _lobbyStreamController = StreamController<LobbyModel>.broadcast();

  LobbyRepositoryImpl();

  @override
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(MockLobbyDatasource.mockLobbyRealtimeUsers.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tạo phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Right(MockLobbyDatasource.mockLobbyRealtimeUsers.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy thông tin phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> joinLobby(String lobbyId, String inviteCode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi tham gia phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> leaveLobby(String lobbyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi rời phòng: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi mời bạn bè: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends() async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right(
          MockLobbyDatasource.mockOnlineFriendsList.map((f) => f.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi lấy danh sách bạn bè: ${e.toString()}'));
    }
  }

  @override
  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId) {
    final lobby = MockLobbyDatasource.mockLobbyRealtimeUsers;
    _lobbyStreamController.add(lobby);
    return _lobbyStreamController.stream.map((model) => model.toEntity());
  }

  @override
  Future<Either<Failure, void>> cancelLobby(String lobbyId, String reasonCode) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi hủy phòng: ${e.toString()}'));
    }
  }

  void dispose() {
    _lobbyStreamController.close();
  }
}
