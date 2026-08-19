import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import '../../../matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import '../../../profile/domain/entities/profile_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'my_lobbies_state.dart';

/// Cubit cho section "Phòng chờ của tôi" trong Discovery → tab "Phòng chờ".
///
/// Sử dụng real API endpoints:
/// - `GET /api/v1/lobbies/my` — hợp nhất hosted + joined trong 1 response.
/// - Backend tự filter theo BR-MEMBER-CLEANUP-01 (chỉ trả lobby còn active).
/// - `GET /api/cafes/{id}` — chi tiết cafe cho từng lobby.
///
/// Endpoint cũ `/hosted` + `/joined` chỉ dùng làm fallback nếu backend
/// chưa deploy `/my` (xem `_remote.getMyLobbies()`).
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;
  final MatchmakingRepository? matchmakingRepository;

  MyLobbiesCubit({
    required this.repository,
    this.matchmakingRepository,
  }) : super(const MyLobbiesInitial());

  /// Load danh sách lobby user hosting + lobby đã tham gia.
  /// Ưu tiên endpoint `/my` (đã tự filter BR-MEMBER-CLEANUP-01).
  /// Đồng thời fetch cafe details cho mỗi lobby.
  Future<void> load(ProfileEntity? currentUser) async {
    if (isClosed) return;
    emit(const MyLobbiesLoading());

    try {
      // 1. Ưu tiên gọi `/my` (BVC v2) — server đã filter terminal lobbies.
      // Nếu backend fallback 404 về hosted/joined, vẫn pass qua được
      // (vì remote DS đã merge + filter lại).
      final myResult = await repository.getMyLobbies();

      final merged = myResult.fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );

      if (isClosed) return;

      // 2. Phân loại hosted vs joined cho UI — sử dụng flag `isHost`
      // của currentUser ở mỗi lobby entity (server-trả).
      final hostedIds = <String>{};
      final joinedIds = <String>{};
      for (final l in merged) {
        if (l.hostId == currentUser?.userId) {
          hostedIds.add(l.id);
        } else {
          joinedIds.add(l.id);
        }
      }
      final hosted = merged.where((l) => hostedIds.contains(l.id)).toList();
      final joined = merged.where((l) => joinedIds.contains(l.id)).toList();

      // 3. Defensive filter: BR-MEMBER-CLEANUP-01 — backend tự filter,
      // nhưng nếu backend trả cả lobby đã terminal (vd trong window
      // giữa hub broadcast và server-side cleanup), vẫn lọc thêm
      // client-side để UX nhất quán.
      final hostedFiltered =
          hosted.where((l) => l.status.isActive).toList(growable: false);
      final joinedFiltered =
          joined.where((l) => l.status.isActive).toList(growable: false);

      // 4. Fetch cafe details nếu có matchmakingRepository
      final cafes = <String, CafeDetailEntity>{};
      final repo = matchmakingRepository;
      if (repo != null) {
        final allLobbies = [...hostedFiltered, ...joinedFiltered];
        final uniqueCafeIds = allLobbies
            .map((l) => l.cafeId)
            .where((id) => id.isNotEmpty)
            .toSet();

        for (final cafeId in uniqueCafeIds) {
          final cafeResult = await repo.getCafeDetail(cafeId);
          cafeResult.fold(
            (_) {},
            (cafe) {
              if (cafe != null) {
                cafes[cafeId] = cafe;
              }
            },
          );
        }
      }

      emit(MyLobbiesLoaded(
        hosted: hostedFiltered,
        joined: joinedFiltered,
        cafes: cafes,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(MyLobbiesFailure(message: 'Không tải được phòng chờ: $e'));
    }
  }

  /// Refresh chỉ phần hosted (dùng sau khi user tạo lobby mới, v.v.).
  Future<void> refresh(ProfileEntity? currentUser) => load(currentUser);
}
