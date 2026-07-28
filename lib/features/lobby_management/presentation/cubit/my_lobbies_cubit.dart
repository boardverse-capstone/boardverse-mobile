import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/profile_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'my_lobbies_state.dart';

/// Cubit cho section "Phòng chờ của tôi" trong Discovery → tab "Phòng chờ".
///
/// Sử dụng real API endpoints:
/// - `GET /api/v1/lobbies/hosted` — danh sách lobby do user host
/// - `GET /api/v1/lobbies/joined` — danh sách lobby user đã tham gia
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;

  MyLobbiesCubit({
    required this.repository,
  }) : super(const MyLobbiesInitial());

  /// Load danh sách lobby user hosting + lobby đã tham gia.
  ///
  /// Gọi real API:
  /// - `GET /api/v1/lobbies/hosted` cho lobby đã tạo
  /// - `GET /api/v1/lobbies/joined` cho lobby đã tham gia
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
      emit(MyLobbiesLoaded(hosted: hosted, joined: joined));
    } catch (e) {
      if (isClosed) return;
      emit(MyLobbiesFailure(message: 'Không tải được phòng chờ: $e'));
    }
  }

  /// Refresh chỉ phần hosted (dùng sau khi user tạo lobby mới, v.v.).
  Future<void> refresh(ProfileEntity? currentUser) => load(currentUser);
}
