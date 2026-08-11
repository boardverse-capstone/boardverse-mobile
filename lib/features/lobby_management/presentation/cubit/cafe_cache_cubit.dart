import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import '../../../matchmaking_discovery/domain/repositories/matchmaking_repository.dart';

/// Cubit đơn giản để cache cafe details theo ID.
/// Dùng chung cho toàn app để tránh gọi API nhiều lần cho cùng 1 cafe.
class CafeCacheCubit extends Cubit<CafeCacheState> {
  final MatchmakingRepository repository;

  CafeCacheCubit({required this.repository})
      : super(const CafeCacheState());

  /// Lấy cafe details, cache lại nếu chưa có.
  Future<CafeDetailEntity?> getCafe(String cafeId) async {
    // Check cache trước
    final cached = state.cache[cafeId];
    if (cached != null) return cached;

    // Fetch từ API
    final result = await repository.getCafeDetail(cafeId);

    return result.fold(
      (failure) {
        return null;
      },
      (cafe) {
        if (cafe != null) {
          // Cache lại
          emit(state.copyWithCache({...state.cache, cafeId: cafe}));
        }
        return cafe;
      },
    );
  }
}

class CafeCacheState {
  final Map<String, CafeDetailEntity> cache;

  const CafeCacheState({this.cache = const {}});

  CafeCacheState copyWithCache(Map<String, CafeDetailEntity> newCache) {
    return CafeCacheState(cache: newCache);
  }
}
