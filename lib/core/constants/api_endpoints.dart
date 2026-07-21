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
  static const String userProfile = '/api/userprofile';
  static const String userProfileProgress = '/api/userprofile/progress';
  static const String userProfileAvatar = '/api/userprofile/me/avatar';
  static const String userProfileLocation = '/api/userprofile/me/location';
  static const String userProfileKarmaHistory = '/api/userprofile/me/karma-history';

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

  // ──────────────────────────────────────────────
  //  Health
  // ──────────────────────────────────────────────
  static const String healthStatus = '/api/health/status';
  static const String healthPing = '/api/health/ping';
  static const String healthDbInfo = '/api/health/db-info';

  // ──────────────────────────────────────────────
  //  Bookings & Payments (Task 2)
  // ──────────────────────────────────────────────
  static const String createBooking = '/api/Bookings';
  static const String bookingDetail = '/api/Bookings/{id}';
  static const String confirmBooking = '/api/Bookings/{id}/confirm';
  static const String cancelBooking = '/api/Bookings/{id}/cancel';
  static const String bookingStatus = '/api/Bookings/{id}/status';
  static const String bookingHistory = '/api/Bookings/history';

  // ─── Deposit Config ───
  static const String depositConfig = '/api/Cafes/{cafeId}/deposit-config';

  // ─── Payments ───
  static const String paymentCreate = '/api/Payments/create-url';

  // ─── Lobbies (Task 3) ────────────────────────────────────────────
  // Theo spec tại `.agents/docs/apis_docs/lobby.md` (v1, lowercase).
  static const String lobbiesSearch = '/api/v1/lobbies/search';
  static const String lobbiesList = '/api/v1/lobbies';
  static const String lobbyDetail = '/api/v1/lobbies/{id}';
  static const String lobbyJoin = '/api/v1/lobbies/{id}/join';
  static const String lobbyLeave = '/api/v1/lobbies/{id}/leave';
  static const String lobbyClose = '/api/v1/lobbies/{id}/close';
  static const String lobbyLock = '/api/v1/lobbies/{id}/lock';
  static const String lobbyOpenKarmaWindow =
      '/api/v1/lobbies/{id}/open-karma-window';

  // ─── Lobbies: Auto-booking (Luồng A — backend-generated) ────────
  // Endpoint này không thuộc spec lobby.md nhưng được dùng nội bộ
  // để bridge sang flow booking (Task 4). Tạm thời giữ cũ.
  static const String lobbyAutoBooking = '/api/v1/lobbies/{id}/auto-booking';

  // ─── SignalR Hub (realtime) ─────────────────────────────────────
  // Negotiate endpoint trên cùng host với REST API. Token được truyền
  // qua query `?access_token=<jwt>` bởi `RealLobbyRealtimeService`.
  static const String lobbyHubNegotiate = '/hubs/lobby/negotiate';
  static const String lobbyHubBasePath = '/hubs/lobby';

  // ──────────────────────────────────────────────
  //  Matches (Elo & consensus) — Task 4
  // ──────────────────────────────────────────────
  // Theo spec `.agents/docs/apis_docs/matches.md`. Mọi endpoint xoay
  // quanh `lobbyId` — MatchHistory neo vào đúng phòng chờ đã chơi.
  // Chỉ game cạnh tranh (`doi-khang`, `chien-thuat`) mới eligible;
  // BR-04 backend kiểm tra qua gameTemplateId trên lobby.
  static const String matchResultByLobby = '/api/v1/matches/results/lobbies/{lobbyId}';
  static const String matchResultSubmit = '/api/v1/matches/results';
}
