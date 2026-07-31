import '../../models/tournament_model.dart';
import '../../models/participant_model.dart';
import '../../models/match_model.dart';
import '../../models/elo_history_model.dart';
import '../../models/leaderboard_model.dart';

/// Abstract interface for tournament remote data source.
/// Defines all API calls for tournament module.
///
/// Lưu ý về endpoint:
/// - `GET /tournaments/open?gameTemplateId=...` — bắt buộc `gameTemplateId`.
/// - `GET /tournaments/my-registrations?status=...` — lấy giải của tôi.
/// - `GET /tournaments/my-elo-history` — lịch sử Elo cá nhân.
/// - `GET /tournaments/leaderboard?topCount=...` — bảng xếp hạng.
/// - KHÔNG có `/tournaments/upcoming` và `/tournaments/matches/{id}` (404).
abstract class TournamentRemoteDatasource {
  /// `GET /tournaments/open?gameTemplateId=...`
  ///
  /// Backend yêu cầu `gameTemplateId` bắt buộc (Splendor = UUID
  /// `44444444-4444-4444-4444-444444444444`), nếu thiếu sẽ trả 400.
  Future<List<TournamentModel>> getOpenTournaments({String? gameTemplateId});

  /// `GET /tournaments/{id}`
  Future<TournamentModel> getTournamentDetail(String tournamentId);

  /// `GET /tournaments/{id}/participants`
  Future<List<TournamentParticipantModel>> getParticipants(String tournamentId);

  /// `GET /tournaments/{id}/participants/{participantId}`
  Future<TournamentParticipantModel> getParticipant(
    String tournamentId,
    String participantId,
  );

  /// `GET /tournaments/{id}/matches`
  Future<List<TournamentMatchModel>> getMatches(String tournamentId);

  /// `GET /tournaments/{id}/matches/round/{round}`
  Future<List<TournamentMatchModel>> getMatchesByRound(
    String tournamentId,
    int roundNumber,
  );

  /// Tra cứu 1 match theo id.
  ///
  /// Backend KHÔNG có endpoint `GET /tournaments/matches/{id}` (404).
  /// Impl sẽ fetch toàn bộ matches rồi filter client-side, nên bắt
  /// buộc truyền [tournamentId].
  Future<TournamentMatchModel> getMatchById(
    String tournamentId,
    String matchId,
  );

  /// `POST /tournaments/{id}/register`
  Future<void> register(String tournamentId);

  /// `POST /tournaments/{id}/unregister`
  Future<void> unregister(String tournamentId);

  /// `GET /tournaments/my-registrations?status=...`
  Future<List<TournamentModel>> getMyRegistrations({String? status});

  /// `GET /tournaments/my-elo-history`
  Future<List<EloHistoryModel>> getMyEloHistory();

  /// `GET /tournaments/leaderboard?topCount=...&gameTemplateId=...`
  Future<List<LeaderboardEntryModel>> getLeaderboard({
    int topCount = 100,
    String? gameTemplateId,
  });
}
