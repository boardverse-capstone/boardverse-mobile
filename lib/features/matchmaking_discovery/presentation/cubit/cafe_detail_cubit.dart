import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/matchmaking_repository.dart';
import 'cafe_detail_state.dart';

class CafeDetailCubit extends Cubit<CafeDetailState> {
  final MatchmakingRepository _repository;

  CafeDetailCubit({required MatchmakingRepository repository})
      : _repository = repository,
        super(CafeDetailInitial());

  Future<void> loadCafeDetail(String cafeId) async {
    emit(CafeDetailLoading());

    final result = await _repository.getCafeDetail(cafeId);

    result.fold(
      (failure) => emit(CafeDetailError(failure.message)),
      (cafe) {
        if (cafe == null) {
          emit(const CafeDetailError('Không tìm thấy quán cafe'));
        } else {
          emit(CafeDetailLoaded(cafe));
        }
      },
    );
  }
}
