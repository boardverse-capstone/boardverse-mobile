import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';
import 'tournament_detail_state.dart';

/// Cubit for managing tournament detail state.
class TournamentDetailCubit extends Cubit<TournamentDetailState> {
  final TournamentRepository _repository;
  String? _currentTournamentId;
  String? _currentUserId;
  int _loadVersion = 0;
  Timer? _autoRefreshTimer;
  static const _autoRefreshInterval = Duration(minutes: 2);

  TournamentDetailCubit({required this._repository})
    : super(const TournamentDetailInitial());

  /// Current tournament ID.
  String? get currentTournamentId => _currentTournamentId;

  /// Start auto-refresh timer for ongoing tournaments.
  void startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      if (_currentTournamentId != null && !isClosed) {
        loadDetail(_currentTournamentId!, currentUserId: _currentUserId);
      }
    });
  }

  /// Stop auto-refresh timer.
  void stopAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = null;
  }

  /// Loads tournament detail, participants, and matches.
  Future<void> loadDetail(String tournamentId, {String? currentUserId}) async {
    final loadVersion = ++_loadVersion;
    _currentTournamentId = tournamentId;
    _currentUserId = currentUserId;
    if (isClosed) return;
    emit(const TournamentDetailLoading());

    final tournamentFuture = _repository.getTournamentDetail(tournamentId);
    final participantsFuture = _repository.getParticipants(
      tournamentId,
      currentUserId: currentUserId,
    );
    final matchesFuture = _repository.getMatches(tournamentId);

    final tournamentResult = await tournamentFuture;
    final participantsResult = await participantsFuture;
    final matchesResult = await matchesFuture;
    if (isClosed || loadVersion != _loadVersion) return;

    TournamentEntity? tournament;
    String? errorMessage;
    final participants = participantsResult.fold((failure) {
      errorMessage = failure.message;
      return <TournamentParticipantEntity>[];
    }, (items) => items);
    final matches = matchesResult.fold((failure) {
      errorMessage ??= failure.message;
      return <TournamentMatchEntity>[];
    }, (items) => items);

    tournamentResult.fold(
      (failure) => errorMessage = failure.message,
      (item) => tournament = item,
    );

    if (tournament != null && currentUserId != null) {
      tournament = _mergeUserState(tournament!, participants);
    }

    if (errorMessage != null) {
      emit(
        TournamentDetailError(
          message: errorMessage!,
          tournament: tournament,
          participants: participants,
          matches: matches,
        ),
      );
      return;
    }

    emit(
      TournamentDetailLoaded(
        tournament: tournament!,
        participants: participants,
        matches: matches,
        selectedRound: 0,
      ),
    );

    // Auto-refresh only for ongoing tournaments
    if (tournament!.status.isOngoing) {
      startAutoRefresh();
    } else {
      stopAutoRefresh();
    }
  }

  /// Registers the user for the tournament.
  Future<void> register(String tournamentId) async {
    final snapshot = _snapshotFrom(state);
    if (snapshot == null || isClosed) return;

    emit(
      TournamentDetailRegistering(
        tournament: snapshot.tournament,
        participants: snapshot.participants,
        matches: snapshot.matches,
        isRegistering: true,
      ),
    );

    final result = await _repository.register(tournamentId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(
          TournamentDetailError(
            message: failure.message,
            tournament: snapshot.tournament,
            participants: snapshot.participants,
            matches: snapshot.matches,
          ),
        );
      },
      (_) async {
        emit(
          const TournamentDetailActionSuccess(
            message: 'Đăng ký tham gia thành công!',
            wasRegistered: true,
          ),
        );
        await loadDetail(tournamentId, currentUserId: _currentUserId);
      },
    );
  }

  /// Unregisters the user from the tournament.
  Future<void> unregister(String tournamentId) async {
    final snapshot = _snapshotFrom(state);
    if (snapshot == null || isClosed) return;

    emit(
      TournamentDetailRegistering(
        tournament: snapshot.tournament,
        participants: snapshot.participants,
        matches: snapshot.matches,
        isRegistering: false,
      ),
    );

    final result = await _repository.unregister(tournamentId);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(
          TournamentDetailError(
            message: failure.message,
            tournament: snapshot.tournament,
            participants: snapshot.participants,
            matches: snapshot.matches,
          ),
        );
      },
      (_) async {
        emit(
          const TournamentDetailActionSuccess(
            message: 'Đã rút lui khỏi giải đấu.',
            wasRegistered: false,
          ),
        );
        await loadDetail(tournamentId, currentUserId: _currentUserId);
      },
    );
  }

  /// Refreshes the detail data.
  Future<void> refresh() async {
    if (_currentTournamentId != null) {
      await loadDetail(_currentTournamentId!, currentUserId: _currentUserId);
    }
  }

  /// Changes the selected round filter.
  void selectRound(int round) {
    final currentState = state;
    if (currentState is TournamentDetailLoaded) {
      emit(currentState.copyWith(selectedRound: round));
    }
  }

  @override
  Future<void> close() {
    _autoRefreshTimer?.cancel();
    _loadVersion++;
    return super.close();
  }

  TournamentEntity _mergeUserState(
    TournamentEntity tournament,
    List<TournamentParticipantEntity> participants,
  ) {
    TournamentParticipantEntity? currentUser;
    for (final participant in participants) {
      if (participant.isCurrentUser) {
        currentUser = participant;
        break;
      }
    }
    if (currentUser == null) return tournament;

    final isRegistered =
        currentUser.status != ParticipantStatus.withdrawn &&
        currentUser.status != ParticipantStatus.noShow;
    final isCheckedIn =
        currentUser.status == ParticipantStatus.checkedIn ||
        currentUser.status == ParticipantStatus.active ||
        currentUser.status == ParticipantStatus.finished;
    return tournament.copyWith(
      isUserRegistered: isRegistered,
      isUserCheckedIn: isCheckedIn,
    );
  }

  _TournamentSnapshot? _snapshotFrom(TournamentDetailState currentState) {
    if (currentState is TournamentDetailLoaded) {
      return _TournamentSnapshot(
        tournament: currentState.tournament,
        participants: currentState.participants,
        matches: currentState.matches,
      );
    }
    if (currentState is TournamentDetailError &&
        currentState.tournament != null) {
      return _TournamentSnapshot(
        tournament: currentState.tournament!,
        participants: currentState.participants ?? const [],
        matches: currentState.matches ?? const [],
      );
    }
    return null;
  }
}

class _TournamentSnapshot {
  final TournamentEntity tournament;
  final List<TournamentParticipantEntity> participants;
  final List<TournamentMatchEntity> matches;

  const _TournamentSnapshot({
    required this.tournament,
    required this.participants,
    required this.matches,
  });
}
