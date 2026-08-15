import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/leaderboard_kind.dart';
import '../../domain/repositories/leaderboard_repository.dart';
import 'leaderboard_state.dart';

/// Cubit quản lý leaderboard theo [LeaderboardKind] (elo/level/karma).
///
/// Flow:
/// - `load(kind)` — gọi khi mở page / đổi tab. Phát Loading rồi Loaded/Error.
/// - `refresh()` — gọi khi pull-to-refresh. Phát Loaded(isRefresh:true) để
///   UI hint không reset list.
/// - `switchKind(kind)` — đổi tab nếu kind hiện tại trống; nếu đã có data
///   thì chỉ emit lại (UI tự render từ cache).
class LeaderboardCubit extends Cubit<LeaderboardState> {
  final LeaderboardRepository repository;

  /// Cache kết quả theo kind để chuyển tab không cần gọi lại API.
  final Map<LeaderboardKind, dynamic> _cache = {};

  /// Kind hiện tại — mặc định ELO khi mở page.
  LeaderboardKind _currentKind = LeaderboardKind.elo;

  LeaderboardCubit({required this.repository})
      : super(const LeaderboardInitial());
  LeaderboardKind get currentKind => _currentKind;

  /// Load leaderboard cho [kind]. Nếu đã có cache thì emit Loaded từ cache
  /// (không gọi API). Khi force = true, bỏ qua cache.
  Future<void> load(LeaderboardKind kind, {bool force = false}) async {
    _currentKind = kind;

    if (!force && _cache.containsKey(kind)) {
      emit(LeaderboardLoaded(
        result: _cache[kind],
        kind: kind,
      ));
      return;
    }

    emit(LeaderboardLoading(kind));
    final result = await repository.fetchLeaderboard(kind: kind);
    result.fold(
      (failure) => emit(LeaderboardError(message: failure.message, kind: kind)),
      (data) {
        _cache[kind] = data;
        emit(LeaderboardLoaded(result: data, kind: kind));
      },
    );
  }

  /// Pull-to-refresh — gọi lại API, giữ nguyên list cũ trên UI cho đến khi
  /// emit Loaded(isRefresh:true).
  Future<void> refresh() async {
    emit(LeaderboardLoading(_currentKind));
    final result = await repository.fetchLeaderboard(kind: _currentKind);
    result.fold(
      (failure) => emit(
        LeaderboardError(message: failure.message, kind: _currentKind),
      ),
      (data) {
        _cache[_currentKind] = data;
        emit(LeaderboardLoaded(
          result: data,
          kind: _currentKind,
          isRefresh: true,
        ));
      },
    );
  }

  /// Đổi tab — chỉ gọi API khi cache trống.
  Future<void> switchKind(LeaderboardKind kind) {
    if (kind == _currentKind && state is LeaderboardLoaded) {
      return Future.value();
    }
    return load(kind);
  }
}
