import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_summary.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'lobby_state.dart';

/// Cubit cho trang tìm lobby khả dụng quanh user (Phase 6.b).
///
/// Karma filter dùng cho BR-10: server sẽ tự động lọc theo currentUserKarma
/// của user đang login (qua JWT claim). `currentUserKarma` được truyền từ
/// page-level (ProfileCubit) — nếu không truyền, server vẫn lọc được qua
/// JWT nhưng client dùng giá trị mặc định 0 để tránh trả về rỗng giả.
class LobbySearchCubit extends Cubit<LobbyState> {
  /// Realtime service cho browse refresh — optional để tránh phá DI nếu
  /// caller không truyền (ví dụ: unit test). Khi null, cubit hoạt động
  /// như bình thường không có realtime.
  final LobbyRealtimeService? realtime;
  final LobbyRepository repository;

  static const double _defaultLat = 10.7769;
  static const double _defaultLng = 106.7009;

  /// Default karma khi caller không truyền — 0 cho phép server trả về tất
  /// cả phòng, sau đó page có thể filter client-side dựa trên karma thật.
  static const double defaultKarma = 0;

  /// Debounce window cho realtime refresh — gộp các event đến gần nhau
  /// thành 1 lần reload để tránh spam API khi có nhiều member join/leave.
  static const Duration _realtimeDebounce = Duration(milliseconds: 800);

  StreamSubscription<LobbyRealtimeEvent>? _realtimeSub;
  Timer? _debounceTimer;

  /// Cache last limit để dùng lại khi realtime event tới.
  int _lastLimit = 50;

  LobbySearchCubit({required this.repository, this.realtime})
    : super(const LobbyInitial());

  // ════════════════════════════════════════════════════════════════════════════
  // Search APIs (existing)
  // ════════════════════════════════════════════════════════════════════════════

  /// Tìm lobby, trả về `LobbyListLoaded` / `LobbyListEmpty` / `LobbyListLoading`.
  ///
  /// [currentUserKarma]: điểm Karma của user hiện tại (BR-10). Caller nên
  /// lấy từ `ProfileCubit.state.profile.karmaPoints ?? 0`. Mặc định 0 để
  /// không filter khi chưa load profile.
  Future<void> searchNearbyLobbies({
    required LobbySearchFilter filter,
    double? latitude,
    double? longitude,
    double? currentUserKarma,
  }) async {
    emit(const LobbyListLoading());
    final result = await repository.searchNearbyLobbies(
      latitude: latitude ?? _defaultLat,
      longitude: longitude ?? _defaultLng,
      filter: filter,
      currentUserKarma: currentUserKarma ?? defaultKarma,
    );
    // Bỏ qua emit nếu cubit đã bị close (user navigate away trước khi
    // Future hoàn thành). Nếu không check, sẽ gây:
    //   Bad state: Cannot emit new states after calling close
    if (isClosed) return;
    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      list,
    ) {
      if (list.isEmpty) {
        emit(
          const LobbyListEmpty(
            message:
                'Không có phòng nào phù hợp. Hãy thử nới rộng bán kính hoặc giảm ngưỡng Karma.',
          ),
        );
      } else {
        emit(LobbyListLoaded(lobbies: list));
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Browse (/discoverable) + Realtime Refresh
  // ════════════════════════════════════════════════════════════════════════════

  /// Browse lobbies qua `/api/v1/lobbies/discoverable` — flow chính của
  /// tab "Phòng chờ". Server đã filter theo vị trí + visibility + status,
  /// trả về [LobbyEntity] đầy đủ thông tin (không phải summary).
  ///
  /// Đồng thời subscribe realtime stream (nếu service được inject) để tự
  /// reload khi server broadcast `NearbyLobbyCreated` / `NearbyLobbyRemoved`
  /// / `NearbyLobbyUpdated` / `LobbyCancelled` / `LobbyFull`.
  Future<void> loadDiscoverable({int limit = 50}) async {
    _lastLimit = limit;

    // Đảm bảo subscribe realtime chỉ 1 lần cho cả vòng đời cubit.
    _ensureRealtimeSubscribed();

    emit(const LobbyListLoading());
    final result = await repository.discoverableLobbies(limit: limit);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (list) {
        if (list.isEmpty) {
          emit(
            const LobbyListEmpty(
              message:
                  'Hiện không có phòng chờ đang hoạt động. Hãy quay lại sau hoặc tạo phòng mới.',
            ),
          );
        } else {
          // Lưu ý: truyền vào [entities] thay vì [lobbies] (summary) để
          // page có full data mở thẳng `LobbyPreviewPage` mà không cần
          // gọi thêm `getLobbyById`.
          emit(LobbyListLoaded(lobbies: const [], entities: list));
        }
      },
    );
  }

  /// Subscribe realtime stream — idempotent. Gọi an toàn nhiều lần, chỉ
  /// tạo subscription thực sự nếu chưa có.
  void _ensureRealtimeSubscribed() {
    final r = realtime;
    if (r == null) return;
    if (_realtimeSub != null) return;

    _realtimeSub = r.events.listen(_onRealtimeEvent);
  }

  /// Handler realtime — chỉ trigger reload khi state hiện tại đang ở
  /// `LobbyListLoaded` (không spam reload khi user đang ở trang khác hoặc
  /// list đang loading). Debounce để gộp nhiều event gần nhau.
  void _onRealtimeEvent(LobbyRealtimeEvent event) {
    // Chỉ react với các event thuộc nhóm browse / discoverable.
    final shouldReload = switch (event) {
      NearbyLobbyCreatedEvent() ||
      NearbyLobbyRemovedEvent() ||
      NearbyLobbyUpdatedEvent() ||
      LobbyCancelledEvent() ||
      LobbyFullEvent() ||
      LobbyTimeoutEvent() => true,
      _ => false,
    };
    if (!shouldReload) return;
    if (isClosed) return;

    // Chỉ refresh khi đã có list hiện — tránh emit `LobbyListLoading`
    // liên tục làm nháy UI khi user chưa load lần đầu. Bao gồm cả
    // `LobbyListEmpty` để user quay lại tab sau khi list trống có thể
    // nhận được lobby mới từ broadcast realtime.
    final current = state;
    if (current is! LobbyListLoaded && current is! LobbyListEmpty) return;

    // Debounce — reset timer nếu event mới tới trong window.
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_realtimeDebounce, () {
      if (isClosed) return;
      // Reload thầm — không emit `LobbyListLoading` để tránh flicker.
      _refreshSilently();
    });
  }

  Future<void> _refreshSilently() async {
    final result = await repository.discoverableLobbies(limit: _lastLimit);
    if (isClosed) return;
    result.fold(
      (failure) {
        // Realtime refresh fail → giữ state cũ, không spam error.
      },
      (list) {
        if (list.isEmpty) {
          emit(
            const LobbyListEmpty(
              message:
                  'Hiện không có phòng chờ đang hoạt động. Hãy quay lại sau hoặc tạo phòng mới.',
            ),
          );
        } else {
          emit(LobbyListLoaded(lobbies: const [], entities: list));
        }
      },
    );
  }

  void clear() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    emit(const LobbyInitial());
  }

  @override
  Future<void> close() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    await _realtimeSub?.cancel();
    _realtimeSub = null;
    return super.close();
  }
}
