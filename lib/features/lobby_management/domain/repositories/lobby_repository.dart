import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/lobby_entity.dart';
import '../entities/friend_entity.dart';

abstract class LobbyRepository {
  Future<Either<Failure, LobbyEntity>> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
  });

  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId);

  Future<Either<Failure, void>> joinLobby(String lobbyId, String inviteCode);

  Future<Either<Failure, void>> leaveLobby(String lobbyId);

  Future<Either<Failure, void>> inviteFriend(String lobbyId, String friendId);

  Future<Either<Failure, List<FriendEntity>>> getOnlineFriends();

  Stream<LobbyEntity> watchLobbyRealtime(String lobbyId);

  Future<Either<Failure, void>> cancelLobby(String lobbyId, String reasonCode);
}
