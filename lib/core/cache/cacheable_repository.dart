/// In-memory TTL cache for repository GET endpoints.
///
/// This is a simple, synchronous read-through cache intended for **read-only
/// endpoints that are called from multiple unrelated screens** (for example
/// `GET /cafes/nearby/me` or `GET /v1/lobbies/hosted`). Its goal is **dedupe
/// cross-screen GETs**, not to be a general-purpose cache. Mutable / write
/// endpoints should never be wrapped with this.
///
/// Usage (in a repository implementation):
///
/// ```dart
/// class MatchmakingRepositoryImpl extends CacheableRepository
///     implements MatchmakingRepository {
///   MatchmakingRepositoryImpl({required this.datasource})
///       : super(defaultTtl: const Duration(seconds: 30));
///
///   Future<Either<Failure, List<CafeEntity>>> getNearbyCafesForCurrentUser(
///       {required String gameId}) {
///     return cache('cafes-nearby-me-$gameId', () =>
///         datasource.getNearbyCafesForCurrentUser(gameTemplateId: gameId)
///             .then((m) => m.map((e) => e.toEntity()).toList().toRight()));
///   }
/// }
/// ```
///
/// `invalidate()` and `invalidateKey(key)` should be called after any
/// mutation that would change the cached payload (e.g. user creates a
/// lobby → invalidate the `hosted` + `discoverable` keys).
class CacheableRepository {
  CacheableRepository({this.defaultTtl = const Duration(seconds: 30)});

  /// Default TTL applied to [cache] calls that don't supply their own.
  final Duration defaultTtl;

  final Map<String, _CacheEntry> _entries = <String, _CacheEntry>{};

  /// Returns the cached value for [key] if present and fresh, otherwise
  /// runs [fetcher], caches the result and returns it.
  ///
  /// Errors from [fetcher] are not cached. Failures propagate to the caller.
  Future<T> cache<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl,
  }) async {
    final now = DateTime.now();
    final existing = _entries[key];
    final effectiveTtl = ttl ?? defaultTtl;
    if (existing != null && now.difference(existing.cachedAt) < effectiveTtl) {
      return existing.value as T;
    }
    final dynamic raw = await fetcher();
    final Object fresh = raw as Object;
    _entries[key] = _CacheEntry(fresh, now);
    return raw as T;
  }

  /// Drop all cached values. Cheap; safe to call after logout, etc.
  void invalidate() {
    _entries.clear();
  }

  /// Drop a single key. Useful when one mutation only affects one slot.
  void invalidateKey(String key) {
    _entries.remove(key);
  }
}

class _CacheEntry {
  _CacheEntry(this.value, this.cachedAt);
  final Object value;
  final DateTime cachedAt;
}
