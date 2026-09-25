import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/saved_games_cache.dart';
import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/entities/game_category_discovery_entity.dart';
import '../../domain/repositories/discovery_repository.dart';
import 'survey_state.dart';

/// Cubit quản lý survey flow (Solo Survey, Solo Personalized, Group Discovery).
class SurveyCubit extends Cubit<SurveyState> {
  final DiscoveryRepository _repository;

  /// Cache dùng để debug/log — không gọi trực tiếp từ cubit.
  // ignore: unused_field
  final SavedGamesCache _cache;

  SurveyCubit({
    required DiscoveryRepository repository,
    required SavedGamesCache cache,
  })  : _repository = repository,
        _cache = cache,
        super(const SurveyInitial());

  /// Load categories và check eligibility cho personalization.
  Future<void> loadCategories() async {
    emit(const SurveyLoading());

    try {
      final savedCount = await _repository.getSavedGamesCount();
      final hasEligible = savedCount >= 3;

      final categoriesResult = await _repository.getCategories();

      if (isClosed) return;

      categoriesResult.fold(
        (failure) => emit(SurveyError(message: failure.message)),
        (categories) => emit(SurveyCategoriesLoaded(
          categories: categories,
          currentRequest: const DiscoveryRequestEntity(),
          soloMode: SoloMode.personalized, // default
          hasPersonalizationEligible: hasEligible,
        )),
      );
    } catch (e) {
      if (isClosed) return;
      emit(SurveyError(message: e.toString()));
    }
  }

  /// Chạy Solo Survey (filter-based, không personalization).
  Future<void> runSurvey(DiscoveryRequestEntity request) async {
    final baseData = _extractBaseData();
    if (baseData == null) return;

    emit(SurveySearching(
      categories: baseData.categories,
      currentRequest: request,
      soloMode: SoloMode.survey,
      hasPersonalizationEligible: baseData.hasPersonalizationEligible,
    ));

    final result = await _repository.runSurvey(request);

    if (isClosed) return;

    result.fold(
      (failure) => emit(SurveyError(
        message: failure.message,
        categories: baseData.categories,
        currentRequest: request,
        soloMode: SoloMode.survey,
        hasPersonalizationEligible: baseData.hasPersonalizationEligible,
      )),
      (games) {
        if (games.isEmpty) {
          emit(SurveyEmpty(
            categories: baseData.categories,
            currentRequest: request,
            soloMode: SoloMode.survey,
            hasPersonalizationEligible: baseData.hasPersonalizationEligible,
            message:
                'Không tìm thấy game phù hợp. Thử bỏ bớt filter hoặc điều chỉnh weight range.',
          ));
        } else {
          emit(SurveySoloResults(
            categories: baseData.categories,
            currentRequest: request,
            soloMode: SoloMode.survey,
            hasPersonalizationEligible: baseData.hasPersonalizationEligible,
            games: games,
            totalCount: games.length,
          ));
        }
      },
    );
  }

  /// Chạy Solo Personalized (cá nhân hóa từ saved games).
  Future<void> runPersonalized({
    required DiscoveryRequestEntity request,
    double? latitude,
    double? longitude,
  }) async {
    final baseData = _extractBaseData();
    if (baseData == null) return;

    emit(SurveySearching(
      categories: baseData.categories,
      currentRequest: request,
      soloMode: SoloMode.personalized,
      hasPersonalizationEligible: baseData.hasPersonalizationEligible,
    ));

    final result = await _repository.getSoloPersonalized(
      request: request,
      latitude: latitude,
      longitude: longitude,
    );

    if (isClosed) return;

    result.fold(
      (failure) => emit(SurveyError(
        message: failure.message,
        categories: baseData.categories,
        currentRequest: request,
        soloMode: SoloMode.personalized,
        hasPersonalizationEligible: baseData.hasPersonalizationEligible,
      )),
      (response) {
        if (response.games.isEmpty) {
          emit(SurveyEmpty(
            categories: baseData.categories,
            currentRequest: request,
            soloMode: SoloMode.personalized,
            hasPersonalizationEligible: baseData.hasPersonalizationEligible,
            message: 'Không tìm thấy game phù hợp. Thử bỏ bớt filter.',
          ));
        } else {
          emit(SurveyPersonalizedResults(
            categories: baseData.categories,
            currentRequest: request,
            hasPersonalizationEligible: baseData.hasPersonalizationEligible,
            response: response,
          ));
        }
      },
    );
  }

  /// Chạy Group Discovery.
  Future<void> discoverForGroup(List<MemberPreferenceRequest> members) async {
    final baseData = _extractBaseData();
    if (baseData == null) return;

    emit(SurveySearching(
      categories: baseData.categories,
      currentRequest: const DiscoveryRequestEntity(),
      soloMode: SoloMode.personalized, // placeholder
      hasPersonalizationEligible: baseData.hasPersonalizationEligible,
    ));

    final result = await _repository.discoverForGroup(members: members);

    if (isClosed) return;

    result.fold(
      (failure) => emit(SurveyError(
        message: failure.message,
        categories: baseData.categories,
      )),
      (games) {
        if (games.isEmpty) {
          emit(SurveyEmpty(
            categories: baseData.categories,
            currentRequest: const DiscoveryRequestEntity(),
            soloMode: SoloMode.survey,
            hasPersonalizationEligible: false,
            message:
                'Không tìm thấy game phù hợp cho nhóm. Thử điều chỉnh số người hoặc preferences.',
          ));
        } else {
          emit(SurveyGroupResults(
            categories: baseData.categories,
            games: games,
            totalCount: games.length,
          ));
        }
      },
    );
  }

  /// Chuyển đổi giữa các Solo modes.
  Future<void> switchSoloMode(SoloMode mode) async {
    final s = state;

    if (s is SurveyCategoriesLoaded) {
      emit(s.copyWith(soloMode: mode));
      return;
    }

    if (s is SurveySoloResults) {
      // Reconstruct state with new mode + same data
      emit(SurveyCategoriesLoaded(
        categories: s.categories,
        currentRequest: s.currentRequest,
        soloMode: mode,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      ));
      return;
    }

    if (s is SurveyEmpty) {
      emit(SurveyCategoriesLoaded(
        categories: s.categories,
        currentRequest: s.currentRequest,
        soloMode: mode,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      ));
      return;
    }

    if (s is SurveyPersonalizedResults) {
      // Personalized results can't switch to survey mode without re-running.
      // Just update categories view if user wants to switch back.
      emit(SurveyCategoriesLoaded(
        categories: s.categories,
        currentRequest: s.currentRequest,
        soloMode: mode,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      ));
      return;
    }
  }

  /// Cập nhật request hiện tại và trigger search.
  Future<void> searchWithRequest(DiscoveryRequestEntity request) async {
    final baseData = _extractBaseData();
    if (baseData == null) return;

    // Auto-select mode based on current state
    final s = state;
    final SoloMode mode;
    if (s is SurveyCategoriesLoaded) {
      mode = s.soloMode;
    } else if (s is SurveySoloResults) {
      mode = s.soloMode;
    } else if (s is SurveyPersonalizedResults) {
      mode = SoloMode.personalized;
    } else if (s is SurveyEmpty) {
      mode = s.soloMode;
    } else {
      mode = SoloMode.personalized;
    }

    final hasEligible = await _repository.getSavedGamesCount() >= 3;

    // Nếu user muốn personalized nhưng chưa eligible → fallback
    final effectiveMode =
        (mode == SoloMode.personalized && !hasEligible) ? SoloMode.survey : mode;

    if (effectiveMode == SoloMode.survey) {
      await runSurvey(request);
    } else {
      await runPersonalized(request: request);
    }
  }

  /// Trích xuất categories + personalizationEligible từ state hiện tại
  /// (dùng làm dữ liệu nền cho các state kế tiếp).
  _BaseData? _extractBaseData() {
    final s = state;
    if (s is SurveyCategoriesLoaded) {
      return _BaseData(
        categories: s.categories,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      );
    }
    if (s is SurveySearching) {
      return _BaseData(
        categories: s.categories,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      );
    }
    if (s is SurveySoloResults) {
      return _BaseData(
        categories: s.categories,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      );
    }
    if (s is SurveyPersonalizedResults) {
      return _BaseData(
        categories: s.categories,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      );
    }
    if (s is SurveyEmpty) {
      return _BaseData(
        categories: s.categories,
        hasPersonalizationEligible: s.hasPersonalizationEligible,
      );
    }
    if (s is SurveyError && s.categories != null) {
      return _BaseData(
        categories: s.categories!,
        hasPersonalizationEligible: s.hasPersonalizationEligible ?? false,
      );
    }
    return null;
  }
}

/// Helper data class để truyền categories + personalization flag giữa các state.
class _BaseData {
  final List<GameCategoryDiscoveryEntity> categories;
  final bool hasPersonalizationEligible;

  const _BaseData({
    required this.categories,
    required this.hasPersonalizationEligible,
  });
}
