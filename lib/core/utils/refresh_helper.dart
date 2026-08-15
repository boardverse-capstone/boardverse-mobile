/// Helper class to track data freshness and determine when refresh is needed.
class RefreshHelper {
  static const Duration _activityRefreshThreshold = Duration(minutes: 5);
  static const Duration _leaderboardRefreshThreshold = Duration(minutes: 10);

  DateTime? _lastRefreshTime;

  DateTime? get lastRefreshTime => _lastRefreshTime;

  /// Returns true if data should be refreshed based on time elapsed.
  bool shouldRefreshActivity() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > _activityRefreshThreshold;
  }

  /// Returns true if leaderboard data should be refreshed based on time elapsed.
  bool shouldRefreshLeaderboard() {
    if (_lastRefreshTime == null) return true;
    return DateTime.now().difference(_lastRefreshTime!) > _leaderboardRefreshThreshold;
  }

  /// Mark data as refreshed (update timestamp).
  void markRefreshed() {
    _lastRefreshTime = DateTime.now();
  }
}
