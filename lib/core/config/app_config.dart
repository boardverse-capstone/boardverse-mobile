/// Centralized configuration for the application.
///
/// **Single source of truth for all app configuration.**
/// When switching between mock and real backend, only modify [useMockData].
class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ─── Data Source Mode ───────────────────────────────────────────────

  /// Switch between mock data and real backend
  /// - `true`: Use MockMatchmakingDatasource (for development)
  /// - `false`: Use MatchmakingRemoteDatasource (for production)
  static const bool useMockData = true;

  // ─── API Configuration ───────────────────────────────────────────────

  /// Base URL for backend API
  static const String apiBaseUrl = 'https://api.boardverse.com';

  /// API version prefix
  static const String apiVersion = 'v1';

  /// Full API base URL
  static String get fullApiBaseUrl => '$apiBaseUrl/api/$apiVersion';

  // ─── Cache Configuration ────────────────────────────────────────────

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

  // ─── UI Configuration ───────────────────────────────────────────────

  /// Debounce duration for search input
  static const Duration searchDebounceMs = Duration(milliseconds: 500);

  /// Number of similar games to show
  static const int similarGamesLimit = 5;
}
