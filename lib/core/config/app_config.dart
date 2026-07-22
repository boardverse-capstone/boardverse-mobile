/// Centralized configuration for the application.
///
/// **Single source of truth for all app configuration.**
///
/// ### Base URL
/// The actual API base URL comes from `.env` → `DioClient` reads it at runtime.
/// `AppConfig` does NOT hold the base URL (no hardcoding).
///
/// ### Mock Mode
/// Booking feature still uses mock data because backend APIs are not ready yet.
/// All other features (lobby, friend, match, discovery, auth, profile) use real APIs.
class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ─── Data Source Mode ───────────────────────────────────────────────

  /// Switch for Booking & Payment feature only.
  /// - `true`: Use Mock datasources (for development)
  /// - `false`: Use Remote datasources → real backend API (for production)
  /// NOTE: Booking APIs pending backend implementation.
  static const bool useMockData = true;

  // ─── Cache Configuration ───────────────────────────────────────────

  /// Default cache expiry duration
  static const Duration cacheExpiry = Duration(hours: 24);

  /// Seat availability refresh interval (for real-time updates)
  static const Duration seatRefreshInterval = Duration(seconds: 30);

  // ─── Search Configuration ───────────────────────────────────────────

  /// Default search radius in kilometers
  static const double defaultSearchRadiusKm = 15.0;

  /// Minimum karma points required for matchmaking (BR-10)
  static const int defaultMinKarma = 0;

  // ─── Business Rules Configuration ──────────────────────────────────

  /// Maximum deposit hold time in minutes (BR-06)
  static const int maxDepositMinutesLimit = 30;

  /// Maximum deposit percentage of first hour price (BR-03)
  static const double maxDepositPercentage = 50.0;

  /// Default seat hold duration in minutes (pending payment)
  static const int defaultSeatHoldMinutes = 5;

  // ─── UI Configuration ─────────────────────────────────────────────

  /// Debounce duration for search input
  static const Duration searchDebounceMs = Duration(milliseconds: 500);

  /// Number of similar games to show
  static const int similarGamesLimit = 5;

  // ─── Tournament Configuration ────────────────────────────────────

  /// Default `gameTemplateId` cho Tournament — hiện chỉ hỗ trợ Splendor
  /// (hardcode theo yêu cầu nghiệp vụ).
  ///
  /// Tra cứu từ `GET /api/v1/board-games?search=Splendor` → trả về
  /// `id = 44444444-4444-4444-4444-444444444444`. Khi backend mở rộng
  /// sang game khác, đổi giá trị này hoặc cho phép truyền qua UI.
  static const String defaultSplendorGameTemplateId =
      '44444444-4444-4444-4444-444444444444';
}
