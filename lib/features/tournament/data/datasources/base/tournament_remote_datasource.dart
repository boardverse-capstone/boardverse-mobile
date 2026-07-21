import '../../models/tournament_model.dart';
import '../../models/participant_model.dart';
import '../../models/match_model.dart';
import '../../models/elo_history_model.dart';
import '../../models/leaderboard_model.dart';

/// Abstract interface for tournament remote data source.
/// Defines all API calls for tournament module.
abstract class TournamentRemoteDatasource {
  /// GET /tournaments/open?gameTemplateId=
  Future<List<TournamentModel>> getOpenTournaments({
    String? gameTemplateId,
  });

  /// GET /tournaments/upcoming?gameTemplateId=
  Future<List<TournamentModel>> getUpcomingTournaments({
    String? gameTemplateId,
  });

  /// GET /tournaments/{id}
  Future<TournamentModel> getTournamentDetail(String tournamentId);

  /// GET /tournaments/{id}/participants
  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);

  /// GET /tournaments/{id}/participants/{participantId}
  Future<TournamentParticipantModel> getParticipant(
    String tournamentId,
    String participantId,
  );

  /// GET /tournaments/{id}/matches
  Future<List<TournamentMatchModel>> getMatches(String tournamentId);

  /// GET /tournaments/{id}/matches/round/{round}
  Future<List<TournamentMatchModel>> getMatchesByRound(
    String tournamentId,
    int roundNumber,
  );

  /// GET /matches/{matchId}
  Future<TournamentMatchModel> getMatchById(String matchId);

  /// POST /tournaments/{id}/register
  Future<void> register(String tournamentId);

  /// POST /tournaments/{id}/unregister
  Future<void> unregister(String tournamentId);

  /// GET /tournaments/my-registrations?status=
  Future<List<TournamentModel>> getMyRegistrations({
    String? status,
  });

  /// GET /tournaments/my-elo-history
  Future<List<EloHistoryModel>> getMyEloHistory();

  /// GET /tournaments/leaderboard?topCount=
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    int topCount = 100,
  });
}
