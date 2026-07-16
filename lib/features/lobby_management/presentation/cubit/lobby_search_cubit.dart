import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/lobby_summary.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'lobby_state.dart';

/// Cubit cho trang tìm lobby khả dụng quanh user (Phase 6.b).
class LobbySearchCubit extends Cubit<LobbyState> {
  final LobbyRepository _repository;

  static const double _defaultLat = 10.7769;
  static const double _defaultLng = 106.7009;

  static const double currentUserKarma = 70;

  LobbySearchCubit({required this._repository})
      : super(const LobbyInitial());

  /// Tìm lobby, trả về `LobbyListLoaded` / `LobbyListEmpty` / `LobbyListLoading`.
  Future<void> searchNearbyLobbies({
    required LobbySearchFilter filter,
    double? latitude,
    double? longitude,
  }) async {
    emit(const LobbyListLoading());
    final result = await _repository.searchNearbyLobbies(
      latitude: latitude ?? _defaultLat,
      longitude: longitude ?? _defaultLng,
      filter: filter,
      currentUserKarma: currentUserKarma,
    );
    // Bỏ qua emit nếu cubit đã bị close (user navigate away trước khi
    // Future hoàn thành). Nếu không check, sẽ gây:
    //   Bad state: Cannot emit new states after calling close
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (list) {
        if (list.isEmpty) {
          emit(const LobbyListEmpty(
            message:
                'Không có phòng nào phù hợp. Hãy thử nới rộng bán kính hoặc giảm ngưỡng Karma.',
          ));
        } else {
          emit(LobbyListLoaded(lobbies: list));
        }
      },
    );
  }

  void clear() => emit(const LobbyInitial());
}
