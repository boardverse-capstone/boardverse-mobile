import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/tournament_entity.dart';
import '../entities/tournament_participant_entity.dart';
import '../entities/tournament_match_entity.dart';
import '../entities/my_elo_history_entity.dart';
import '../entities/my_registration_entity.dart';
import '../entities/tournament_waitlist_entity.dart';
import '../entities/tournament_spectator_entity.dart';

/// Abstract repository interface for tournament operations.
abstract class TournamentRepository {
  /// Lấy giải theo status.
  ///
  /// Gọi `GET /tournaments?status=X`. Dùng để fetch từng nhóm giải
  /// (RegistrationClosed, OnGoing, Completed, Cancelled) thay thế cho
  /// `/my-registrations?status=`. Endpoint này trả về đầy đủ thông tin
  /// giải (`TournamentEntity`) thay vì flat shape.
  ///
  /// Để trống `status` hoặc truyền `"all"` → tất cả giải.
  Future<Either<Failure, List<TournamentEntity>>> getTournamentsByStatus({
    String? status,
  });

  /// Lấy danh sách giải Splendor đang mở đăng ký.
  /// Backend filter theo `Status = RegistrationOpen`, deadline chưa qua,
  /// còn slot. Theo docs chỉ có endpoint `/open` (không có `/upcoming`).
  Future<Either<Failure, List<TournamentEntity>>> getOpenTournaments({
    String? gameTemplateId,
  });

  /// Chi tiết giải đấu.
  Future<Either<Failure, TournamentEntity>> getTournamentDetail(String id);

  /// Danh sách participants.
  Future<Either<Failure, List<TournamentParticipantEntity>>> getParticipants(
    String id, {
    String? currentUserId,
  });

  /// Chi tiết 1 participant trong giải.
  Future<Either<Failure, TournamentParticipantEntity>> getParticipant(
    String tournamentId,
    String participantId, {
    String? currentUserId,
  });

  /// Danh sách tất cả matches của tournament.
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatches(String id);

  /// Matches theo round.
  Future<Either<Failure, List<TournamentMatchEntity>>> getMatchesByRound(
    String id,
    int round,
  );

  /// Chi tiết 1 match.
  ///
  /// Backend hiện không expose `GET /tournaments/matches/{id}` (trả 404),
  /// nên repo fetch toàn bộ matches rồi filter client-side.
  /// Cần truyền [tournamentId] vì backend không cho lookup match ngược.
  Future<Either<Failure, TournamentMatchEntity>> getMatchById(
    String tournamentId,
    String matchId,
  );

  /// Đăng ký tham gia giải.
  Future<Either<Failure, void>> register(String id);

  /// Rút lui khỏi giải.
  Future<Either<Failure, void>> unregister(String id);

  /// Giải của tôi (đã đăng ký).
  ///
  /// Endpoint trả về flat shape (xem [MyRegistrationEntry]) chứ không
  /// phải `TournamentEntity` đầy đủ — vì vậy repo trả về entity riêng.
  Future<Either<Failure, List<MyRegistrationEntry>>> getMyRegistrations({
    String? status,
  });

  /// Lịch sử Elo của tôi.
  ///
  /// Endpoint trả về wrapper object chứa `currentElo`, `username` và
  /// `history: []`. Entity [MyEloHistoryResponse] đại diện cho wrapper này.
  Future<Either<Failure, MyEloHistoryResponse>> getMyEloHistory();

  // ─── T-03: Tournament Waitlist ──────────────────────────────────────────

  /// Tham gia waitlist của tournament đầy. Trả về entry mới kèm `position`
  /// hiện tại.
  ///
  /// Lỗi:
  /// - 404: tournament không tồn tại
  /// - 409: đã đăng ký participant / đã trong waitlist
  Future<Either<Failure, JoinWaitlistResult>> joinWaitlist(
      String tournamentId);

  /// Danh sách user đang chờ trong waitlist (phân trang).
  Future<Either<Failure, List<TournamentWaitlistEntry>>> getWaitlist(
    String tournamentId, {
    int? page,
    int? pageSize,
  });

  /// Trạng thái waitlist của tôi — dùng để biết user đã trong waitlist,
  /// vị trí, có offer cần confirm không.
  ///
  /// Khi chưa join: [MyWaitlistStatus.isInWaitlist] = false.
  Future<Either<Failure, MyWaitlistStatus>> getMyWaitlistStatus(
      String tournamentId);

  /// Rời khỏi waitlist.
  Future<Either<Failure, void>> leaveWaitlist(String tournamentId);

  /// Xác nhận offer từ waitlist (khi có slot trống).
  ///
  /// Lỗi:
  /// - 404: không có trong waitlist
  /// - 409: offer đã hết hạn hoặc không còn slot
  Future<Either<Failure, WaitlistActionResult>> confirmWaitlistOffer(
      String tournamentId);

  /// Từ chối offer từ waitlist.
  ///
  /// Sau khi decline, slot sẽ được offer cho user tiếp theo.
  Future<Either<Failure, WaitlistActionResult>> declineWaitlistOffer(
      String tournamentId);

  // ─── T-04: Tournament Spectator ────────────────────────────────────────

  /// Danh sách spectators của tournament (public — không cần auth).
  Future<Either<Failure, List<TournamentSpectatorEntry>>> getSpectators(
      String tournamentId);

  /// Trạng thái spectate của tôi — khi chưa spectate trả
  /// [MySpectatorStatus.isSpectating] = false.
  Future<Either<Failure, MySpectatorStatus>> getMySpectatorStatus(
      String tournamentId);

  /// Bắt đầu spectate một tournament.
  ///
  /// Lỗi:
  /// - 404: tournament không tồn tại
  /// - 409: user là participant của tournament này (không được cùng
  ///   vừa chơi vừa spectate)
  Future<Either<Failure, TournamentSpectatorEntry>> startSpectating(
      String tournamentId);

  /// Rời khỏi spectate.
  Future<Either<Failure, void>> stopSpectating(String tournamentId);

  /// **Leaderboard đã tách ra feature riêng** — xem
  /// `lib/features/leaderboard/`. Không còn method `getLeaderboard` ở
  /// TournamentRepository vì backend đã chuyển sang các endpoint public
  /// `/api/v1/leaderboard/{karma,elo,level}` (xem
  /// `.agents/docs/apis_docs/leaderboard.md`).
}
