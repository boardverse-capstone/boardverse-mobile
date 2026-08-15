/// Centralized API endpoint paths.
///
/// **This is the single source of truth for all API routes.**
/// When the backend changes an endpoint, update it here — nowhere else.
///
/// Usage:
/// ```dart
/// dio.post(ApiEndpoints.login, data: body);
/// ```
class ApiEndpoints {
  ApiEndpoints._(); // prevent instantiation

  // ──────────────────────────────────────────────
  //  Auth
  // ──────────────────────────────────────────────
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String refreshToken = '/api/Auth/refresh-token';
  static const String logout = '/api/Auth/logout';
  static const String sendEmailVerification =
      '/api/Auth/send-email-verification';
  static const String verifyEmail = '/api/Auth/verify-email';
  static const String googleLogin = '/api/Auth/google-login';
  static const String requestPasswordReset = '/api/Auth/request-password-reset';
  static const String resetPassword = '/api/Auth/reset-password';
  static const String changePassword = '/api/Auth/change-password';
  static const String linkGoogle = '/api/Auth/link-google';

  // ──────────────────────────────────────────────
  //  User Profile
  // ──────────────────────────────────────────────
  // Base: /api/userprofile — Player profile management.
  // Docs: .agents/docs/apis_docs/user-profile.md
  static const String userProfile = '/api/Userprofile';
  static const String userProfileProgress = '/api/Userprofile/progress';
  static const String userProfileAvatar = '/api/Userprofile/me/avatar';
  static const String userProfileLocation = '/api/Userprofile/me/location';
  static const String userProfileKarmaHistory =
      '/api/Userprofile/me/karma-history';

  // ──────────────────────────────────────────────
  //  Board Games (Public Catalog)
  // ──────────────────────────────────────────────
  // Base: /api/v1/board-games — phục vụ luồng Player tìm kiếm, lọc,
  // xem chi tiết & điều hướng chế độ chơi (Solo/Group).
  // Xem chi tiết: .agents/docs/apis_docs/board-games.md
  static const String boardGames = '/api/v1/board-games';
  static const String boardGameCategories = '/api/v1/board-games/categories';
  static const String boardGameDetail = '/api/v1/board-games/{id}';
  static const String boardGamePlayConfiguration =
      '/api/v1/board-games/{id}/play-configuration';
  static const String boardGamePlayNavigation =
      '/api/v1/board-games/{id}/play-navigation';

  // ──────────────────────────────────────────────
  //  Cafes (Discovery)
  // ──────────────────────────────────────────────
  // Base: /api/cafes — phục vụ luồng Khám phá Quán cho Player.
  // Xem chi tiết: .agents/docs/apis_docs/cafe.md
  static const String cafesNearby = '/api/cafes/nearby';
  static const String cafesNearbyMe = '/api/cafes/nearby/me';
  static const String cafeDetail = '/api/cafes/{id}';
  static const String cafeSearch = '/api/cafes/search';
  static const String cafeAvailableTables =
      '/api/cafes/{cafeId}/available-tables';
  static const String cafeAvailability = '/api/cafes/{cafeId}/availability';

  // ──────────────────────────────────────────────
  //  Health
  // ──────────────────────────────────────────────
  static const String healthStatus = '/api/health/status';
  static const String healthPing = '/api/health/ping';
  static const String healthDbInfo = '/api/health/db-info';

  // ──────────────────────────────────────────────
  //  Bookings & Payments (DEPRECATED - Use /api/v1/reservations)
  // ──────────────────────────────────────────────
  // DEPRECATED: These endpoints are no longer in use.
  // Use /api/v1/reservations/* for new reservation flow.
  // Keeping for reference only - will be removed in future.
  // @deprecated Use ApiEndpointsV2 for new flows
  static const String bookingCreate = '/api/bookings';
  static const String bookingDetail = '/api/bookings/{id}';
  static const String bookingByLobby = '/api/bookings/lobby/{lobbyId}';
  static const String bookingCancel = '/api/bookings/{id}';
  static const String bookingUpdate = '/api/bookings/{id}';
  static const String bookingCheckIn = '/api/bookings/{id}/check-in';
  static const String bookingCheckOut = '/api/bookings/{id}/check-out';
  static const String bookingSessionStatus =
      '/api/bookings/{bookingId}/session-status';
  static const String bookingsByCafe = '/api/bookings/cafe/{cafeId}';

  // ─── BookingRatingController (DEPRECATED) ───
  // @deprecated Use /api/v1/ratings for new rating flow
  static const String bookingNoShowVotes =
      '/api/bookings/{bookingId}/no-show-votes';
  static const String bookingRatings = '/api/bookings/{bookingId}/ratings';
  static const String bookingRatingsStatus =
      '/api/bookings/{bookingId}/ratings/status';

  // ─── Deposit Config (lấy cấu hình cọc theo quán) ───
  static const String depositConfig = '/api/Cafes/{cafeId}/deposit-config';

  // ─── Payments (SePay) ───
  static const String bookingDeposit = '/api/payments/booking-deposit';
  static const String bookingDepositDetail =
      '/api/payments/booking-deposit/{id}';
  static const String bookingDepositByOrder =
      '/api/payments/booking-deposit/by-order/{orderId}';
  static const String bookingDepositRegenerateQr =
      '/api/payments/booking-deposit/{id}/regenerate-qr';
  static const String bookingDepositRefund =
      '/api/payments/booking-deposit/refund';

  // ─── Payments: Session & Manual Confirm (POS-side, reference only) ───
  // Theo đặc tả `.agents/docs/apis_docs/payment.md`:
  // - `session-payment`: Manager/CafeStaff tạo QR cho hóa đơn phiên chơi
  //   tại POS (sau khi kiểm kê linh kiện xong).
  // - `manual-confirm`: Staff xác nhận thanh toán thủ công khi SePay + VietQR
  //   đều không khả dụng (BR-18). Mobile Player hiện không gọi trực tiếp,
  //   nhưng khai báo để abstract layer không phải patch lại sau.
  static const String sessionPayment = '/api/payments/session-payment';
  static const String sessionPaymentRegenerateQr =
      '/api/payments/session-payment/{sessionId}/regenerate-qr';
  static const String manualConfirm = '/api/payments/manual-confirm';

  // ─── SePay Webhook (server-to-server, no JWT) ────────────────────
  // Theo `.agents/docs/apis_docs/sepay-webhook.md`. Mobile không gọi trực
  // tiếp nhưng endpoint `/mock` có thể dùng trong dev/test để giả lập
  // SePay xác nhận thanh toán (gated bằng flag `EnableMockPayments`).
  static const String sepayWebhook = '/api/payments/sepay/webhook';
  static const String sepayWebhookReturn = '/api/payments/sepay/webhook/return';
  static const String sepayWebhookMock = '/api/payments/sepay/webhook/mock';

  // ─── Notifications (FCM device tokens) ───
  // Theo `.agents/docs/apis_docs/notifications.md`.
  static const String notificationDeviceTokens =
      '/api/notifications/device-tokens';
  static String notificationDeviceTokenDelete(String id) =>
      '/api/notifications/device-tokens/$id';

  // ──────────────────────────────────────────────
  //  Friends
  // ──────────────────────────────────────────────
  // Theo spec `.agents/docs/lobby_docs/friend.md`
  static const String friends = '/api/v1/friends';
  static const String friendsActivity = '/api/v1/friends/activity';
  static const String friendRequests = '/api/v1/friends/requests';
  static const String friendRequestsReceived =
      '/api/v1/friends/requests/received';
  static const String friendRequestsSent = '/api/v1/friends/requests/sent';
  static const String friendSearch = '/api/v1/friends/search';
  static const String friendSuggestions = '/api/v1/friends/suggestions';
  static const String friendPrivacy = '/api/v1/friends/privacy';
  static const String friendNotes = '/api/v1/friends/notes';
  static const String friendReports = '/api/v1/friends/reports';

  /// GET /api/v1/friends/requests/{id}/accept
  static String friendRequestAccept(String id) =>
      '/api/v1/friends/requests/$id/accept';

  /// POST /api/v1/friends/requests/{id}/decline
  static String friendRequestDecline(String id) =>
      '/api/v1/friends/requests/$id/decline';

  /// POST /api/v1/friends/requests/{id}/read
  static String friendRequestRead(String id) =>
      '/api/v1/friends/requests/$id/read';

  /// DELETE /api/v1/friends/{id} - unfriend
  static String friendUnfriend(String id) => '/api/v1/friends/$id';

  /// POST /api/v1/friends/block/{userId}
  static String friendBlock(String userId) => '/api/v1/friends/block/$userId';

  /// DELETE /api/v1/friends/block/{userId} - unblock
  static String friendUnblock(String userId) => '/api/v1/friends/block/$userId';

  /// GET /api/v1/friends/{otherUserId}/mutual - mutual friends
  static String friendMutual(String otherUserId) =>
      '/api/v1/friends/$otherUserId/mutual';

  /// GET /api/v1/friends/{otherUserId}/list - friend's friend list
  static String friendList(String otherUserId) =>
      '/api/v1/friends/$otherUserId/list';

  /// PUT /api/v1/friends/notes/{friendUserId}
  static String friendNoteUpdate(String friendUserId) =>
      '/api/v1/friends/notes/$friendUserId';

  /// DELETE /api/v1/friends/notes/{noteId}
  static String friendNoteDelete(String noteId) =>
      '/api/v1/friends/notes/$noteId';

  /// GET /api/v1/friends/{userId}/profile - Xem chi tiết public profile của 1
  /// player: thông tin cơ bản, gamer stats, số bạn chung, quan hệ hiện tại
  /// và các permission flags (canSendFriendRequest, canReport).
  /// Docs: `.agents/docs/lobby_docs/friend.md` + swagger `PlayerProfileDto`.
  static String friendPlayerProfile(String userId) =>
      '/api/v1/friends/$userId/profile';

  // ─── Lobbies────────────────────────────────────────────
  // Theo spec tại `.agents/docs/apis_docs/lobby.md` (v1, lowercase).
  static const String lobbiesSearch = '/api/v1/lobbies/search';

  /// GET /api/v1/lobbies/discoverable?limit=N — endpoint browse lobbies
  /// cho Player. Trả về danh sách lobby đang hoạt động (status = open/full),
  /// đã được server lọc theo vị trí + quyền riêng tư. **Không yêu cầu
  /// `gameTemplateId`** như `/search`, nên phù hợp cho flow "Browse all
  /// lobbies" ở Discovery tab.
  static const String lobbiesDiscoverable = '/api/v1/lobbies/discoverable';
  static const String lobbiesList = '/api/v1/lobbies';
  static const String lobbyDetail = '/api/v1/lobbies/{id}';
  static const String lobbyJoin = '/api/v1/lobbies/{id}/join';
  static const String lobbyLeave = '/api/v1/lobbies/{id}/leave';
  static const String lobbyClose = '/api/v1/lobbies/{id}/close';
  static const String lobbyLock = '/api/v1/lobbies/{id}/lock';
  static const String lobbyOpenKarmaWindow =
      '/api/v1/lobbies/{id}/open-karma-window';

  /// POST /api/v1/lobbies/{id}/transfer-host — Host chuyển quyền host cho thành viên khác.
  static String lobbyTransferHost(String id) =>
      '/api/v1/lobbies/$id/transfer-host';

  /// POST /api/v1/lobbies/{id}/kick — Host kick thành viên khỏi lobby.
  static String lobbyKick(String id) => '/api/v1/lobbies/$id/kick';

  /// POST /api/v1/lobbies/{id}/ready — Member bấm Ready/Unready khi lobby FULL.
  static String lobbyReady(String id) => '/api/v1/lobbies/$id/ready';

  /// POST /api/v1/lobbies/{id}/report — Báo cáo phòng chờ vi phạm.
  static String lobbyReport(String id) => '/api/v1/lobbies/$id/report';

  /// POST /api/v1/lobbies/{id}/messages — Gửi tin nhắn chat trong lobby.
  static String lobbyMessages(String id) => '/api/v1/lobbies/$id/messages';

  /// DELETE /api/v1/lobbies/{lobbyId} — Host giải tán lobby (hard delete).
  /// Xoá vĩnh viễn Lobby + Members + Messages + Invites + Reports.
  /// Chỉ host mới gọi. Không áp dụng khi lobby đã check-in hoặc đã đóng/rating.
  /// Backend trả 409 nếu lobby đã booking thành công.
  static String lobbyDissolve(String id) => '/api/v1/lobbies/$id';

  /// GET /api/v1/lobbies/hosted — Lấy danh sách lobby do user này host.
  static const String lobbyHosted = '/api/v1/lobbies/hosted';

  /// GET /api/v1/lobbies/joined — Lấy danh sách lobby mà user đang tham gia.
  static const String lobbyJoined = '/api/v1/lobbies/joined';

  // ─── Lobbies: Auto-booking (Luồng A — backend-generated) ────────
  // Endpoint này không thuộc spec lobby.md nhưng được dùng nội bộ
  // để bridge sang flow booking (Task 4). Tạm thời giữ cũ.
  static const String lobbyAutoBooking = '/api/v1/lobbies/{id}/auto-booking';

  // ─── Lobbies: Share Code & Invites ─────────────────────────────────────
  // Theo spec `.agents/docs/apis_docs/lobby-invite.md`
  static const String lobbyShareInfo = '/api/v1/lobbies/{lobbyId}/share-info';
  static const String lobbyJoinByCode = '/api/v1/lobbies/join-by-code';
  static const String lobbyInvitesPending =
      '/api/v1/lobbies/invites/me/pending';
  static const String lobbyInvitesMe = '/api/v1/lobbies/invites/me';
  static const String lobbyInvites = '/api/v1/lobbies/{lobbyId}/invites';
  static const String lobbyInvitesResend =
      '/api/v1/lobbies/invites/{inviteId}/resend';
  static const String lobbyInvitableFriends =
      '/api/v1/lobbies/{lobbyId}/invitable-friends';
  static const String lobbyInviteAccept =
      '/api/v1/lobbies/invites/{inviteId}/accept';
  static const String lobbyInviteDecline =
      '/api/v1/lobbies/invites/{inviteId}/decline';
  static const String lobbyInviteDetail = '/api/v1/lobbies/invites/{inviteId}';

  // ─── SignalR Hub (realtime) ─────────────────────────────────────
  // Negotiate endpoint trên cùng host với REST API. Token được truyền
  // qua query `?access_token=<jwt>` bởi `RealLobbyRealtimeService`.
  static const String lobbyHubNegotiate = '/hubs/lobby/negotiate';
  static const String lobbyHubBasePath = '/hubs/lobby';

  // ──────────────────────────────────────────────
  //  Matches (Elo & consensus)
  // ──────────────────────────────────────────────
  // Theo spec `.agents/docs/apis_docs/matches.md`. Mọi endpoint xoay
  // quanh `lobbyId` — MatchHistory neo vào đúng phòng chờ đã chơi.
  // Chỉ game cạnh tranh (`doi-khang`, `chien-thuat`) mới eligible;
  // BR-04 backend kiểm tra qua gameTemplateId trên lobby.
  static const String matchResultByLobby =
      '/api/v1/matches/results/lobbies/{lobbyId}';
  static const String matchResults = '/api/v1/matches/results';
  static const String matchResultsSubmit = '/api/v1/matches/results';

  // ──────────────────────────────────────────────
  //  Leaderboard (Global — BR §K-06)
  // ──────────────────────────────────────────────
  // Base: /api/v1/leaderboard — Karma / Elo / Level rankings.
  // Theo `.agents/docs/apis_docs/leaderboard.md`:
  // - Public — ai cũng xem được (auth optional).
  // - Nếu request có JWT, response kèm `userRank` (top 1000).
  // - `top` (1-100, default 50) + `offset` (≥ 0, default 0) cho phân trang.
  // Backend cache 5 phút. **Endpoint cũ** `/api/v1/tournaments/leaderboard`
  // (BR-10) đã deprecated — không dùng.
  static const String leaderboard = '/api/v1/leaderboard';

  /// GET /api/v1/leaderboard/karma?top=50&offset=0
  static const String leaderboardKarma = '/api/v1/leaderboard/karma';

  /// GET /api/v1/leaderboard/elo?top=50&offset=0
  static const String leaderboardElo = '/api/v1/leaderboard/elo';

  /// GET /api/v1/leaderboard/level?top=50&offset=0
  static const String leaderboardLevel = '/api/v1/leaderboard/level';

  // ──────────────────────────────────────────────
  //  Tournaments (Player Mobile)
  // ──────────────────────────────────────────────
  // Base: /api/v1/tournaments — Player xem giải, đăng ký, xem kết quả.
  // Docs: .agents/docs/tournament_docs/tournament.md
  //
  // Lưu ý:
  // - `/tournaments/open?gameTemplateId=...` bắt buộc `gameTemplateId`.
  // - KHÔNG tồn tại `/tournaments/upcoming` (404) — bỏ qua.
  // - KHÔNG tồn tại `/tournaments/matches/{id}` (404) — chỉ fetch all rồi
  //   filter client-side.
  // - `/tournaments/leaderboard` (BR-10) **DEPRECATED** — dùng
  //   `/api/v1/leaderboard/{karma,elo,level}` ở section "Leaderboard" trên.
  static const String tournamentsOpen = '/api/v1/tournaments/open';
  static const String tournamentsMyRegistrations =
      '/api/v1/tournaments/my-registrations';
  static const String tournamentsMyEloHistory =
      '/api/v1/tournaments/my-elo-history';

  /// `@Deprecated` — dùng [ApiEndpoints.leaderboardKarma] / [leaderboardElo]
  /// / [leaderboardLevel]. Endpoint cũ chỉ match tournament Elo, không có
  /// phân trang, không có `userRank`.
  @Deprecated('Use /api/v1/leaderboard/{karma,elo,level} instead')
  static const String tournamentsLeaderboard =
      '/api/v1/tournaments/leaderboard';

  /// GET /tournaments/{id}
  static String tournamentDetail(String id) => '/api/v1/tournaments/$id';

  /// GET /tournaments/{id}/participants
  static String tournamentParticipants(String id) =>
      '/api/v1/tournaments/$id/participants';

  /// GET /tournaments/{id}/participants/{participantId}
  static String tournamentParticipant(
    String tournamentId,
    String participantId,
  ) => '/api/v1/tournaments/$tournamentId/participants/$participantId';

  /// GET /tournaments/{id}/matches
  static String tournamentMatches(String id) =>
      '/api/v1/tournaments/$id/matches';

  /// GET /tournaments/{id}/matches/round/{round}
  static String tournamentMatchesRound(String id, int round) =>
      '/api/v1/tournaments/$id/matches/round/$round';

  /// POST /tournaments/{id}/register
  static String tournamentRegister(String id) =>
      '/api/v1/tournaments/$id/register';

  /// POST /tournaments/{id}/unregister
  static String tournamentUnregister(String id) =>
      '/api/v1/tournaments/$id/unregister';

  // ─── T-03: Tournament Waitlist ──────────────────────────────────────────
  // Docs: `.agents/docs/apis_docs/tournament-waitlist.md`
  // Khi tournament đầy, player có thể join waitlist để được promote khi
  // có slot trống. Backend lifecycle: Waiting → Promoted → (Confirm|Decline)
  // → Cancelled|Expired.

  /// GET /api/v1/tournaments/{id}/waitlist — Danh sách waitlist.
  static String tournamentWaitlist(String id) =>
      '/api/v1/tournaments/$id/waitlist';

  /// POST /api/v1/tournaments/{id}/waitlist — Tham gia waitlist.
  static String tournamentWaitlistJoin(String id) =>
      '/api/v1/tournaments/$id/waitlist';

  /// DELETE /api/v1/tournaments/{id}/waitlist — Rời khỏi waitlist.
  static String tournamentWaitlistLeave(String id) =>
      '/api/v1/tournaments/$id/waitlist';

  /// GET /api/v1/tournaments/{id}/waitlist/me — Trạng thái waitlist của tôi.
  static String tournamentWaitlistMe(String id) =>
      '/api/v1/tournaments/$id/waitlist/me';

  /// POST /api/v1/tournaments/{id}/waitlist/confirm — Xác nhận offer từ waitlist.
  static String tournamentWaitlistConfirm(String id) =>
      '/api/v1/tournaments/$id/waitlist/confirm';

  /// POST /api/v1/tournaments/{id}/waitlist/decline — Từ chối offer.
  static String tournamentWaitlistDecline(String id) =>
      '/api/v1/tournaments/$id/waitlist/decline';

  // ─── T-04: Tournament Spectator ─────────────────────────────────────────
  // Docs: `.agents/docs/apis_docs/tournament.md` (Spectator Endpoints)
  // Cho phép user theo dõi tournament mà không cần đăng ký làm participant.
  // GET `/spectators` là public; các endpoint khác yêu cầu JWT.

  /// GET /api/v1/tournaments/{id}/spectators — Danh sách spectators (public).
  static String tournamentSpectators(String id) =>
      '/api/v1/tournaments/$id/spectators';

  /// GET /api/v1/tournaments/{id}/spectators/me — Spectate entry của tôi.
  static String tournamentSpectatorMe(String id) =>
      '/api/v1/tournaments/$id/spectators/me';

  /// POST /api/v1/tournaments/{id}/spectators — Bắt đầu spectate.
  static String tournamentSpectatorJoin(String id) =>
      '/api/v1/tournaments/$id/spectators';

  /// DELETE /api/v1/tournaments/{id}/spectators — Rời khỏi spectate.
  static String tournamentSpectatorLeave(String id) =>
      '/api/v1/tournaments/$id/spectators';

  // ─── Reservations (Lobby creation + BVC deposit) ───────────────────
  // Lobby creation is atomic through quote → confirm. Direct POST /lobbies
  // is deprecated and must not be used by the mobile client.
  static const String reservations = '/api/v1/reservations';
  static const String reservationQuote = '/api/v1/reservations/quote';
  static const String reservationConfirm = '/api/v1/reservations/confirm';
  static const String reservationsPendingCafeApproval =
      '/api/v1/reservations/pending-cafe-approval';

  static String reservationDetail(String id) => '/api/v1/reservations/$id';
  static String reservationCancel(String id) =>
      '/api/v1/reservations/$id/cancel';
  static String reservationCafeApproval(String id) =>
      '/api/v1/reservations/$id/cafe-approval';

  // ─── Wallet (Player BVC) ────────────────────────────────────────────
  // Base: /api/v1/wallet — ví BVC + sổ cái ledger.
  // Docs: .agents/docs/apis_docs/wallet.md
  static const String wallet = '/api/v1/wallet';

  /// POST /api/v1/wallet/topup — tạo đơn top-up BVC qua SePay.
  static const String walletTopup = '/api/v1/wallet/topup';

  /// GET /api/v1/wallet/transactions — lịch sử ledger phân trang.
  static const String walletTransactions = '/api/v1/wallet/transactions';

  /// DELETE /api/v1/wallet/topup/{topUpId} — hủy đơn top-up Pending.
  static String walletTopupCancel(String topUpId) =>
      '/api/v1/wallet/topup/$topUpId';

  /// PATCH /api/v1/wallet/topup/{topUpId} — đổi số tiền đơn top-up Pending.
  static String walletTopupUpdate(String topUpId) =>
      '/api/v1/wallet/topup/$topUpId';

  /// GET /api/v1/wallet/topup/{orderId}/qr-image — fallback endpoint
  /// trả về ảnh QR PNG (image/png) khi backend không embed `qrImageBase64`
  /// trong response của POST/PATCH /topup.
  ///
  /// Backend proxy từ vietqr.app server-side → bypass CORS trên Flutter Web.
  /// Cache 10 phút (khớp với expiresAt của QR).
  static String walletTopupQrImage(String orderId) =>
      '/api/v1/wallet/topup/$orderId/qr-image';
}
