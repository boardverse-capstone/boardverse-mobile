import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mock_lobby_datasource.dart';
import '../../data/lobby_persistence_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'lobby_state.dart';

class LobbyCubit extends Cubit<LobbyState> {
  final LobbyRepository _repository;
  final LobbyPersistenceService _persistenceService;
  StreamSubscription? _lobbySubscription;
  Timer? _countdownTimer;
  Duration _remainingTime = const Duration(minutes: 20);

  LobbyCubit({
    required this._repository,
    LobbyPersistenceService? persistenceService,
  })  : _persistenceService = persistenceService ?? LobbyPersistenceService(),
        super(const LobbyInitial());

  // ─── Create Lobby ─────────────────────────────────────────────────────

  Future<void> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
  }) async {
    emit(const LobbyLoading());

    final result = await _repository.createLobby(
      gameId: gameId,
      cafeId: cafeId,
      scheduledTime: scheduledTime,
      additionalSlots: additionalSlots,
      isPublic: isPublic,
    );

    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      lobby,
    ) {
      _startCountdown(lobby.expiresAt);
      _watchLobbyRealtime(lobby.id);
      _persistLobby(lobby);
      emit(LobbyCreated(lobby: lobby));
    });
  }

  Future<void> _persistLobby(LobbyEntity lobby) async {
    await _persistenceService.saveActiveLobbyId(lobby.id);
    await _persistenceService.saveLobbyDetails({
      'id': lobby.id,
      'gameId': lobby.gameId,
      'gameName': lobby.gameName,
      'cafeId': lobby.cafeId,
      'cafeName': lobby.cafeName,
      'expiresAt': lobby.expiresAt.toIso8601String(),
      'currentPlayers': lobby.currentPlayers,
      'maxPlayers': lobby.maxPlayers,
      'isPublic': lobby.isPublic,
      'inviteCode': lobby.inviteCode,
    });
  }

  // ─── Join Lobby ───────────────────────────────────────────────────────

  Future<void> joinLobby(String lobbyId, String? inviteCode) async {
    emit(const LobbyLoading());

    final result = await _repository.joinLobby(lobbyId, inviteCode ?? '');
    final lobbyResult = await _repository.getLobbyById(lobbyId);

    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (_) {
      lobbyResult.fold(
        (failure) => emit(LobbyFailure(message: failure.message)),
        (lobby) {
          if (lobby != null) {
            _startCountdown(lobby.expiresAt);
            _watchLobbyRealtime(lobby.id);
            emit(LobbyCreated(lobby: lobby));
          } else {
            emit(const LobbyFailure(message: 'Không tìm thấy phòng'));
          }
        },
      );
    });
  }

  // ─── Leave Lobby ──────────────────────────────────────────────────────

  Future<void> leaveLobby(String lobbyId) async {
    _stopCountdown();
    _lobbySubscription?.cancel();

    final result = await _repository.leaveLobby(lobbyId);
    await _persistenceService.clearAll();
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) => emit(const LobbyInitial()),
    );
  }

  // ─── Invite Friend ─────────────────────────────────────────────────────

  Future<void> inviteFriend(String lobbyId, String friendId) async {
    final result = await _repository.inviteFriend(lobbyId, friendId);
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) {},
    );
  }

  // ─── Load Online Friends ───────────────────────────────────────────────

  Future<void> loadOnlineFriends() async {
    final currentState = state;
    if (currentState is! LobbyCreated &&
        currentState is! LobbyUpdatedRealtime) {
      return;
    }

    final lobby = currentState is LobbyCreated
        ? currentState.lobby
        : (currentState as LobbyUpdatedRealtime).lobby;

    final result = await _repository.getOnlineFriends();
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (friends) => emit(LobbyFriendsLoaded(friends: friends, lobby: lobby)),
    );
  }

  // ─── Watch Lobby Realtime ─────────────────────────────────────────────

  void _watchLobbyRealtime(String lobbyId) {
    _lobbySubscription?.cancel();
    _lobbySubscription = _repository
        .watchLobbyRealtime(lobbyId)
        .listen(
          (lobby) {
            emit(LobbyUpdatedRealtime(lobby: lobby));
          },
          onError: (error) {
            emit(LobbyFailure(message: error.toString()));
          },
        );
  }

  // ─── Countdown Timer ──────────────────────────────────────────────────

  void _startCountdown(DateTime expiresAt) {
    _countdownTimer?.cancel();
    _remainingTime = expiresAt.difference(DateTime.now());

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingTime = expiresAt.difference(DateTime.now());

      if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
        _stopCountdown();
        _handleLobbyTimeout();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  void _handleLobbyTimeout() {
    final reasons = MockLobbyDatasource.mockLobbyDismissReasons;
    final timeoutReason = reasons.firstWhere(
      (r) => r.code == 'TIMEOUT',
      orElse: () => const LobbyDismissReasonModel(
        code: 'TIMEOUT',
        title: 'Hết giờ chờ',
        message:
            'Phòng đã bị giải tán do không đủ người trong thời gian quy định.',
      ),
    );

    emit(
      LobbyDismissed(
        title: timeoutReason.title,
        message: timeoutReason.message,
        reasonCode: timeoutReason.code,
      ),
    );
  }

  Duration get remainingTime => _remainingTime;

  // ─── Cancel Lobby ─────────────────────────────────────────────────────

  Future<void> cancelLobby(String lobbyId, String reasonCode) async {
    _stopCountdown();
    _lobbySubscription?.cancel();
    await _persistenceService.clearAll();

    final result = await _repository.cancelLobby(lobbyId, reasonCode);
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) => emit(const LobbyInitial()),
    );
  }

  // ─── Restore Lobby (Check for active lobby on app start) ───────────────

  Future<void> restoreActiveLobby() async {
    final hasActiveLobby = await _persistenceService.hasActiveLobby();
    if (!hasActiveLobby) return;

    final lobbyId = await _persistenceService.getActiveLobbyId();
    if (lobbyId == null) return;

    // Try to rejoin the lobby
    await joinLobby(lobbyId, null);
  }

  // ─── Load Mock Lobby (for development) ───────────────────────────────

  void loadMockLobby() {
    final mockLobby = MockLobbyDatasource.mockLobbyRealtimeUsers;
    _startCountdown(mockLobby.expiresAt);
    emit(LobbyCreated(lobby: mockLobby.toEntity()));
  }

  @override
  Future<void> close() {
    _stopCountdown();
    _lobbySubscription?.cancel();
    return super.close();
  }
}
