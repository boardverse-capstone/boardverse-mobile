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
  static const String userProfile = '/api/UserProfile';
  static const String userProfileProgress = '/api/userprofile/progress';

  // ──────────────────────────────────────────────
  //  Board Games
  // ──────────────────────────────────────────────
  static const String boardGames = '/api/BoardGames';
  static const String boardGameDetail = '/api/BoardGames/{id}';
  static const String boardGameSearch = '/api/BoardGames/search';
  static const String boardGameCategories = '/api/BoardGames/categories';
  static const String similarGames = '/api/BoardGames/{id}/similar';

  // ──────────────────────────────────────────────
  //  Cafes
  // ──────────────────────────────────────────────
  static const String nearbyCafes = '/api/Cafes/nearby';
  static const String cafeDetail = '/api/Cafes/{id}';
  static const String cafeGames = '/api/Cafes/{id}/games';

  // ──────────────────────────────────────────────
  //  Seat Availability (Real-time)
  // ──────────────────────────────────────────────
  static const String seatAvailability = '/api/Cafes/{cafeId}/seats';
  static const String checkSeatsAvailable = '/api/Cafes/{cafeId}/seats/check';

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
  static const String lobbiesSearch = '/api/Lobbies/search';
  static const String lobbiesList = '/api/Lobbies';
  static const String lobbyDetail = '/api/Lobbies/{id}';
  static const String lobbyJoin = '/api/Lobbies/{id}/join';
  static const String lobbyLeave = '/api/Lobbies/{id}/leave';
  static const String lobbyCancel = '/api/Lobbies/{id}/cancel';
  static const String lobbyStatus = '/api/Lobbies/{id}/status';
  static const String lobbyAutoBooking = '/api/Lobbies/{id}/auto-booking';
}
