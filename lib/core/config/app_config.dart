/// Centralized configuration for the application.
///
/// **Single source of truth for all app configuration.**
///
/// ### Base URL
/// The actual API base URL comes from `.env` → `DioClient` reads it at runtime.
/// `AppConfig` does NOT hold the base URL (no hardcoding).
///
/// ### Mock Mode
/// When switching between mock and real backend, modify [useMockData].
/// Note: Currently Discovery (board-games, cafes) is wired to real API.
/// Other features (booking, lobbies) may still use mock data.
class AppConfig {
  AppConfig._(); // Prevent instantiation

  // ─── Data Source Mode ───────────────────────────────────────────────

  /// Switch between mock data and real backend
  /// - `true`: Use Mock datasources (for development)
  /// - `false`: Use Remote datasources → real backend API (for production)
  /// NOTE: Discovery features (board-games, cafes) always hit real API
  ///       regardless of this flag, as their remote impl is complete.
  static const bool useMockData = true;

  /// Per-feature switch for the Lobby module.
  /// Tách độc lập với [useMockData] vì Lobby cần mock realtime (SignalR
  /// chưa có backend) trong khi các feature khác có thể đã chuyển remote.
  /// Khi backend sẵn sàng + SignalR hub được verify → đổi sang `false`.
  static const bool useMockLobbyData = true;

  /// Per-feature switch cho module Match (Elo consensus).
  /// Mock hiện tại trong module `match_summary_rating` dùng local — không
  /// phụ thuộc backend. Khi backend `/api/v1/matches/*` sẵn sàng, đổi sang
  /// `false` để delegate sang `RealMatchResultRemoteDatasource`.
  static const bool useMockMatchData = true;

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
