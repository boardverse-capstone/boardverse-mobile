import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mock_rating_datasource.dart';
import '../../domain/entities/rating_entity.dart';
import '../../domain/entities/voting_session.dart';
import '../../domain/repositories/rating_repository.dart';
import 'rating_state.dart';
import 'voting_state.dart';

class RatingCubit extends Cubit<RatingState> {
  final RatingRepository _repository;
  String _currentSessionId = 'session_001';

  // Voting state
  VotingState _votingState = const VotingInitial();
  Timer? _votingTimer;

  // Current user - mock
  static const String _currentUserId = 'user_001';

  // Mock checked-in members
  final List<VotingCandidate> _mockCandidates = [
    const VotingCandidate(
      id: 'user_001',
      name: 'Bạn',
      isHost: true,
    ),
    const VotingCandidate(
      id: 'user_002',
      name: 'Minh',
      isHost: false,
    ),
    const VotingCandidate(
      id: 'user_003',
      name: 'Lan',
      isHost: false,
    ),
    const VotingCandidate(
      id: 'user_004',
      name: 'Huy',
      isHost: false,
    ),
  ];

  // Mock no-show candidates
  final List<String> _mockNoShowCandidates = ['user_003'];

  RatingCubit({required this._repository})
      : super(const RatingInitial());

  VotingState get votingState => _votingState;
  List<VotingCandidate> get candidates => _mockCandidates;
  List<VotingCandidate> get noShowCandidates =>
      _mockCandidates.where((c) => _mockNoShowCandidates.contains(c.id)).toList();

  // ─── Start Rating Flow ─────────────────────────────────────────────────

  Future<void> startRatingFlow(String sessionId) async {
    emit(const RatingLoading());
    _currentSessionId = sessionId;

    final result = await _repository.getAvailableKarmaTags();

    result.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (tags) {
        final players = MockRatingDatasource.mockPlayersToRate
            .map((p) => RatingPlayer(
                  id: p.id,
                  name: p.name,
                  avatarUrl: p.avatarUrl,
                ))
            .toList();

        emit(KarmaRating(
          playersToRate: players,
          availableTags: tags,
          playerRatings: {},
        ));
      },
    );
  }

  // ─── Toggle Karma Tag ──────────────────────────────────────────────────

  void toggleKarmaTag(String playerId, String tagId) {
    final currentState = state;
    if (currentState is! KarmaRating) return;

    final updatedPlayers = currentState.playersToRate.map((player) {
      if (player.id == playerId) {
        final selectedTags = List<String>.from(player.selectedTagIds);
        if (selectedTags.contains(tagId)) {
          selectedTags.remove(tagId);
        } else {
          selectedTags.add(tagId);
        }
        return player.copyWith(selectedTagIds: selectedTags);
      }
      return player;
    }).toList();

    final updatedRatings = <String, List<String>>{};
    for (final player in updatedPlayers) {
      updatedRatings[player.id] = player.selectedTagIds;
    }

    emit(KarmaRating(
      playersToRate: updatedPlayers,
      availableTags: currentState.availableTags,
      playerRatings: updatedRatings,
    ));
  }

  // ─── Submit Karma Ratings ──────────────────────────────────────────────

  Future<void> submitKarmaRatings() async {
    final currentState = state;
    if (currentState is! KarmaRating) return;

    emit(const RatingLoading());

    final result = await _repository.submitKarmaRating(
      _currentSessionId,
      currentState.playerRatings,
    );

    result.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (_) => emit(const MatchResultEntry()),
    );
  }

  // ─── Submit Match Result ──────────────────────────────────────────────

  Future<void> submitMatchResult(MatchResult result) async {
    emit(const MatchResultEntry(isWaitingConsensus: true));

    final eloResult = await _repository.submitMatchResult(
      _currentSessionId,
      result,
    );

    await Future.delayed(const Duration(seconds: 1));

    eloResult.fold(
      (failure) => emit(RatingFailure(message: failure.message)),
      (elo) => emit(EloResultDisplay(eloResult: elo)),
    );
  }

  // ─── Skip Match Result (for non-competitive games) ─────────────────────

  void skipMatchResult() {
    emit(const RatingComplete());
  }

  // ─── Complete Rating ──────────────────────────────────────────────────

  void completeRating() {
    emit(const RatingComplete());
  }

  // ═══════════════════════════════════════════════════════════════════
  // VOTING LOGIC (Task 5.2)
  // ═══════════════════════════════════════════════════════════════════

  /// Kiểm tra xem có no-show candidate nào cần vote không.
  void checkPendingVotes() {
    if (noShowCandidates.isEmpty) {
      _votingState = const VotingComplete();
      return;
    }

    final threshold = VotingSession.calculateThreshold(_mockCandidates.length);
    _votingState = VotingPending(
      candidates: noShowCandidates,
      checkedInCount: _mockCandidates.length,
      threshold: threshold,
    );
  }

  /// Bắt đầu voting cho một target.
  void startVoting(VotingCandidate target) {
    final now = DateTime.now();
    final deadline = now.add(const Duration(seconds: 60));

    final eligibleVoters = _mockCandidates
        .where((c) => c.id != target.id)
        .map((c) => c.id)
        .toList();

    final threshold = VotingSession.calculateThreshold(eligibleVoters.length);

    final session = VotingSession(
      id: 'voting_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: _currentSessionId,
      targetPlayerId: target.id,
      targetPlayerName: target.name,
      targetPlayerAvatar: target.avatarUrl,
      eligibleVoters: eligibleVoters,
      threshold: threshold,
      startedAt: now,
      deadline: deadline,
    );

    _votingState = VotingActive(
      session: session,
      currentUserId: _currentUserId,
      hasVoted: false,
    );

    _startVotingTimer();
  }

  /// Submit một vote.
  void submitVote(VoteType vote) {
    final currentState = _votingState;
    if (currentState is! VotingActive) return;

    final updatedSession = currentState.session.addVote(_currentUserId, vote);
    _votingState = VotingActive(
      session: updatedSession,
      currentUserId: _currentUserId,
      hasVoted: true,
    );

    // Check if all voted or deadline reached
    if (updatedSession.allVoted || updatedSession.isExpired) {
      _calculateVotingResult();
    }
  }

  /// Tính kết quả voting khi deadline.
  void _calculateVotingResult() {
    _votingTimer?.cancel();

    final currentState = _votingState;
    if (currentState is! VotingActive) return;

    final session = currentState.session;
    final isNoShow = session.noShowVotes >= session.threshold;

    final target = _mockCandidates.firstWhere(
      (c) => c.id == session.targetPlayerId,
    );

    List<VotingCandidate> noShowPlayers = [];
    List<VotingCandidate> attendedPlayers = _mockCandidates.toList();

    if (isNoShow) {
      noShowPlayers = [target];
      attendedPlayers.removeWhere((c) => c.id == target.id);
    } else {
      attendedPlayers = _mockCandidates.toList();
    }

    _votingState = VotingResult(
      noShowPlayers: noShowPlayers,
      attendedPlayers: attendedPlayers,
    );
  }

  /// Hoàn thành voting và quay lại rating flow.
  void completeVoting() {
    _votingTimer?.cancel();
    _votingState = const VotingComplete();
  }

  void _startVotingTimer() {
    _votingTimer?.cancel();
    _votingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = _votingState;
      if (currentState is VotingActive) {
        if (currentState.session.isExpired) {
          _calculateVotingResult();
          timer.cancel();
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Future<void> close() {
    _votingTimer?.cancel();
    return super.close();
  }
}
