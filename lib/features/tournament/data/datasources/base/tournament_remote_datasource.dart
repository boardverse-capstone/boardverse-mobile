import '../../models/tournament_model.dart';
import '../../models/participant_model.dart';
import '../../models/match_model.dart';
import '../../models/elo_history_model.dart';
import '../../models/my_registration_model.dart';
import '../../models/tournament_waitlist_model.dart';
import '../../models/tournament_spectator_model.dart';

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
  /// `GET /tournaments?status=RegistrationOpen` (hoặc status khác).
  ///
  /// Backend trả về `TournamentResponseDto` — cùng shape với `/tournaments/open`.
  /// Dùng thay thế cho `/my-registrations?status=` vì trả về đầy đủ thông
  /// tin giải đấu (không phải flat shape thiếu `gameName`, `maxParticipants`...).
  ///
  /// Query param `status` case-insensitive. Để trống hoặc `"all"` → tất cả.
  Future<List<TournamentModel>> getTournamentsByStatus(String? status);

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
  ///
  /// Trả về flat shape trộn tournament + participant (xem
  /// `MyRegistrationModel` để biết các field). KHÔNG phải
  /// `TournamentResponseDto` — endpoint này thiếu `registrationDeadline`,
  /// `maxParticipants`, `gameName`, ... vì vậy dùng entity riêng.
  Future<List<MyRegistrationModel>> getMyRegistrations({String? status});

  /// `GET /tournaments/my-elo-history`
  ///
  /// Response được wrap trong object `{ userId, username, currentElo,
  /// history: [...] }` — không phải array.
  Future<MyEloHistoryResponseModel> getMyEloHistory();

  // ─── T-03: Tournament Waitlist ──────────────────────────────────────────
  // Docs: `.agents/docs/apis_docs/tournament-waitlist.md`

  /// `POST /tournaments/{id}/waitlist` — tham gia waitlist của tournament
  /// đầy. Trả về entry mới (kèm `position` hiện tại).
  Future<TournamentWaitlistModel> joinWaitlist(String tournamentId);

  /// `GET /tournaments/{id}/waitlist?page=...&pageSize=...` — danh sách
  /// toàn bộ user trong waitlist (phân trang).
  Future<List<TournamentWaitlistModel>> getWaitlist(
    String tournamentId, {
    int? page,
    int? pageSize,
  });

  /// `GET /tournaments/{id}/waitlist/me` — trạng thái waitlist của tôi.
  /// Khi chưa join, backend trả `data.isInWaitlist = false`.
  Future<MyWaitlistStatusModel> getMyWaitlistStatus(String tournamentId);

  /// `DELETE /tournaments/{id}/waitlist` — rời khỏi waitlist.
  Future<void> leaveWaitlist(String tournamentId);

  /// `POST /tournaments/{id}/waitlist/confirm` — xác nhận offer từ waitlist.
  Future<WaitlistActionResultModel> confirmWaitlistOffer(String tournamentId);

  /// `POST /tournaments/{id}/waitlist/decline` — từ chối offer.
  Future<WaitlistActionResultModel> declineWaitlistOffer(String tournamentId);

  // ─── T-04: Tournament Spectator ────────────────────────────────────────
  // Docs: `.agents/docs/apis_docs/tournament.md` (Spectator Endpoints)

  /// `GET /tournaments/{id}/spectators` — danh sách spectators (public).
  Future<List<TournamentSpectatorModel>> getSpectators(String tournamentId);

  /// `GET /tournaments/{id}/spectators/me` — spectate entry của tôi.
  /// Khi chưa spectate, backend trả `data: null`.
  Future<MySpectatorStatusModel> getMySpectatorStatus(String tournamentId);

  /// `POST /tournaments/{id}/spectators` — bắt đầu spectate.
  Future<TournamentSpectatorModel> startSpectating(String tournamentId);

  /// `DELETE /tournaments/{id}/spectators` — rời khỏi spectate.
  Future<void> stopSpectating(String tournamentId);

  /// **Leaderboard đã tách ra feature riêng** — xem
  /// `lib/features/leaderboard/`. Endpoint mới:
  /// - `GET /api/v1/leaderboard/{karma,elo,level}`
  /// Endpoint cũ `/api/v1/tournaments/leaderboard` (BR-10) đã deprecated.
}
