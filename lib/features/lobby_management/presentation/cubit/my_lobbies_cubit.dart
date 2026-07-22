import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/profile_entity.dart';
import '../../data/lobby_persistence_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'my_lobbies_state.dart';

/// Cubit cho section "Phòng chờ của tôi" trong Discovery → tab "Phòng chờ".
///
/// Hiện tại backend KHÔNG có endpoint `GET /api/v1/lobbies/mine`. Tạm thời
/// dùng chiến lược:
/// 1. Gọi `/api/v1/lobbies/discoverable?limit=50` rồi filter client-side
///    theo `hostId == currentUser.id` để có danh sách lobby user TẠO.
/// 2. Đọc `LobbyPersistenceService` (đã lưu khi user tạo/join) để biết
///    lobby user ĐANG THAM GIA (host hoặc member). Limit: chỉ 1 lobby
///    active do service chỉ persist 1 ID tại 1 thời điểm.
///
/// Khi backend bổ sung endpoint `/lobbies/mine` thì chỉ cần thay thân
/// hàm `load()` — state + UI không phải đổi.
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;
  final LobbyPersistenceService _persistence;

  MyLobbiesCubit({
    required this.repository,
    LobbyPersistenceService? persistence,
  }) : _persistence = persistence ?? LobbyPersistenceService(),
       super(const MyLobbiesInitial());

  /// Load danh sách lobby user hosting + lobby active (nếu có).
  ///
  /// [currentUser]: profile hiện tại. Phải có `userId` để filter
  /// `hostId == currentUser.userId`. Nếu null → chỉ trả lobby active từ
  /// persistence (không filter được hosted).
  Future<void> load(ProfileEntity? currentUser) async {
    if (isClosed) return;
    emit(const MyLobbiesLoading());

    try {
      // 1. Lấy lobby active từ persistence (nếu có).
      LobbyEntity? active;
      final hasActive = await _persistence.hasActiveLobby();
      if (hasActive) {
        final activeId = await _persistence.getActiveLobbyId();
        if (activeId != null) {
          final res = await repository.getLobbyById(activeId);
          active = res.fold((_) => null, (l) => l);
        }
      }

      // 2. Lấy tất cả lobby discoverable rồi filter theo hostId.
      final myUserId = currentUser?.userId;
      final hosted = <LobbyEntity>[];

      if (myUserId != null && myUserId.isNotEmpty) {
        final res = await repository.discoverableLobbies(limit: 100);
        res.fold(
          (_) {
            // Lỗi API → hosted = rỗng, vẫn trả active nếu có để UI không trắng.
          },
          (all) {
            for (final l in all) {
              if (l.hostId == myUserId) hosted.add(l);
            }
          },
        );
      }

      if (isClosed) return;
      emit(MyLobbiesLoaded(hosted: hosted, active: active));
    } catch (e) {
      if (isClosed) return;
      emit(MyLobbiesFailure(message: 'Không tải được phòng chờ: $e'));
    }
  }

  /// Refresh chỉ phần hosted (dùng sau khi user tạo lobby mới, v.v.).
  Future<void> refresh(ProfileEntity? currentUser) => load(currentUser);
}
