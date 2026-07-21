import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_participant_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_match_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'tournament_detail_state.dart';

/// Cubit for managing tournament detail state.
class TournamentDetailCubit extends Cubit<TournamentDetailState> {
  final TournamentRepository _repository;
  String? _currentTournamentId;

  TournamentDetailCubit({required this._repository})
      : super(const TournamentDetailInitial());

  /// Current tournament ID.
  String? get currentTournamentId => _currentTournamentId;

  /// Loads tournament detail, participants, and matches.
  Future<void> loadDetail(
    String tournamentId, {
    String? currentUserId,
  }) async {
    _currentTournamentId = tournamentId;
    emit(const TournamentDetailLoading());

    // Load tournament detail
    final tournamentResult = await _repository.getTournamentDetail(tournamentId);
    final participantsResult = await _repository.getParticipants(
      tournamentId,
      currentUserId: currentUserId,
    );
    final matchesResult = await _repository.getMatches(tournamentId);

    TournamentEntity? tournament;
    String? errorMessage;

    tournamentResult.fold(
      (failure) {
        errorMessage = failure.message;
      },
      (t) {
        tournament = t;
      },
    );

    if (errorMessage != null) {
      emit(TournamentDetailError(
        message: errorMessage!,
        tournament: tournament,
        participants: participantsResult.fold(
          (f) => <TournamentParticipantEntity>[],
          (p) => p,
        ),
        matches: matchesResult.fold(
          (f) => <TournamentMatchEntity>[],
          (m) => m,
        ),
      ));
      return;
    }

    emit(TournamentDetailLoaded(
      tournament: tournament!,
      participants: participantsResult.fold(
        (f) => <TournamentParticipantEntity>[],
        (p) => p,
      ),
      matches: matchesResult.fold(
        (f) => <TournamentMatchEntity>[],
        (m) => m,
      ),
      selectedRound: 0,
    ));
  }

  /// registers the user for the tournament.
  Future<void> register(String tournamentId) async {
    final currentState = state;
    if (currentState is! TournamentDetailLoaded) return;

    emit(TournamentDetailRegistering(
      tournament: currentState.tournament,
      participants: currentState.participants,
      matches: currentState.matches,
      isRegistering: true,
    ));

    final result = await _repository.register(tournamentId);

    await result.fold(
      (failure) async {
        emit(TournamentDetailError(
          message: failure.message,
          tournament: currentState.tournament,
          participants: currentState.participants,
          matches: currentState.matches,
        ));
      },
      (_) async {
        emit(const TournamentDetailActionSuccess(
          message: 'Đăng ký tham gia thành công!',
          wasRegistered: true,
        ));
        // Reload detail to get updated registration status
        await loadDetail(tournamentId);
      },
    );
  }

  /// Unregisters the user from the tournament.
  Future<void> unregister(String tournamentId) async {
    final currentState = state;
    if (currentState is! TournamentDetailLoaded) return;

    emit(TournamentDetailRegistering(
      tournament: currentState.tournament,
      participants: currentState.participants,
      matches: currentState.matches,
      isRegistering: false,
    ));

    final result = await _repository.unregister(tournamentId);

    await result.fold(
      (failure) async {
        emit(TournamentDetailError(
          message: failure.message,
          tournament: currentState.tournament,
          participants: currentState.participants,
          matches: currentState.matches,
        ));
      },
      (_) async {
        emit(const TournamentDetailActionSuccess(
          message: 'Đã rút lui khỏi giải đấu.',
          wasRegistered: false,
        ));
        // Reload detail to get updated registration status
        await loadDetail(tournamentId);
      },
    );
  }

  /// Changes the selected round filter.
  void selectRound(int round) {
    final currentState = state;
    if (currentState is TournamentDetailLoaded) {
      emit(currentState.copyWith(selectedRound: round));
    }
  }

  /// Refreshes the detail data.
  Future<void> refresh() async {
    if (_currentTournamentId != null) {
      await loadDetail(_currentTournamentId!);
    }
  }
}
