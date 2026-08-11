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
/// - `GET /api/v1/lobbies/hosted` — danh sách lobby do user host
/// - `GET /api/v1/lobbies/joined` — danh sách lobby user đã tham gia
/// - `GET /api/cafes/{id}` — chi tiết cafe cho từng lobby
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;
  final MatchmakingRepository? matchmakingRepository;

  MyLobbiesCubit({
    required this.repository,
    this.matchmakingRepository,
  }) : super(const MyLobbiesInitial());

  /// Load danh sách lobby user hosting + lobby đã tham gia.
  /// Đồng thời fetch cafe details cho mỗi lobby.
  Future<void> load(ProfileEntity? currentUser) async {
    if (isClosed) return;
    emit(const MyLobbiesLoading());

    try {
      // 1. Gọi real API endpoints
      final hostedResult = await repository.getHostedLobbies();
      final joinedResult = await repository.getJoinedLobbies();

      final hosted = hostedResult.fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );

      final joined = joinedResult.fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );

      if (isClosed) return;

      // 2. Dedup: lobby nào đã có trong `hosted` thì loại khỏi `joined`.
      final hostedIds = hosted.map((l) => l.id).toSet();
      final joinedFiltered = joined
          .where((l) => !hostedIds.contains(l.id))
          .toList(growable: false);

      // 3. Fetch cafe details nếu có matchmakingRepository
      final cafes = <String, CafeDetailEntity>{};
      final repo = matchmakingRepository;
      if (repo != null) {
        final allLobbies = [...hosted, ...joinedFiltered];
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
        hosted: hosted,
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
