import 'package:equatable/equatable.dart';

import '../../domain/entities/discovery_request_entity.dart';
import '../../domain/entities/game_category_discovery_entity.dart';
import '../../domain/entities/group_board_game_entity.dart';
import '../../domain/entities/recommended_board_game_entity.dart';
import '../../domain/entities/solo_personalized_response_entity.dart';

/// Chế độ trong tab Solo.
enum SoloMode {
  /// Gợi ý cá nhân hóa — dùng saved games + play history (cần ≥3 saved games).
  personalized,

  /// Khảo sát thường — filter-based, không personalization.
  survey,
}

/// Sealed states cho [SurveyCubit].
sealed class SurveyState extends Equatable {
  const SurveyState();

  @override
  List<Object?> get props => [];
}

class SurveyInitial extends SurveyState {
  const SurveyInitial();
}

/// Đang load categories hoặc results.
class SurveyLoading extends SurveyState {
  const SurveyLoading();
}

/// Categories đã load — hiển thị trang survey.
class SurveyCategoriesLoaded extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  final SoloMode soloMode;
  final bool hasPersonalizationEligible;

  const SurveyCategoriesLoaded({
    required this.categories,
    required this.currentRequest,
    required this.soloMode,
    required this.hasPersonalizationEligible,
  });

  SurveyCategoriesLoaded copyWith({
    List<GameCategoryDiscoveryEntity>? categories,
    DiscoveryRequestEntity? currentRequest,
    SoloMode? soloMode,
    bool? hasPersonalizationEligible,
  }) {
    return SurveyCategoriesLoaded(
      categories: categories ?? this.categories,
      currentRequest: currentRequest ?? this.currentRequest,
      soloMode: soloMode ?? this.soloMode,
      hasPersonalizationEligible:
          hasPersonalizationEligible ?? this.hasPersonalizationEligible,
    );
  }

  @override
  List<Object?> get props => [
        categories, currentRequest, soloMode, hasPersonalizationEligible,
      ];
}

/// Đang load results (sau khi đã có categories).
class SurveySearching extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  final SoloMode soloMode;
  final bool hasPersonalizationEligible;

  const SurveySearching({
    required this.categories,
    required this.currentRequest,
    required this.soloMode,
    required this.hasPersonalizationEligible,
  });

  @override
  List<Object?> get props => [
        categories, currentRequest, soloMode, hasPersonalizationEligible,
      ];
}

/// Kết quả Solo Survey (filter-based).
class SurveySoloResults extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  final SoloMode soloMode;
  final bool hasPersonalizationEligible;
  final List<RecommendedBoardGameEntity> games;
  final int totalCount;
  final String? emptyMessage;

  const SurveySoloResults({
    required this.categories,
    required this.currentRequest,
    required this.soloMode,
    required this.hasPersonalizationEligible,
    required this.games,
    required this.totalCount,
    this.emptyMessage,
  });

  @override
  List<Object?> get props => [
        categories, currentRequest, soloMode, hasPersonalizationEligible,
        games, totalCount, emptyMessage,
      ];
}

/// Kết quả Solo Personalized.
class SurveyPersonalizedResults extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  final bool hasPersonalizationEligible;
  final SoloPersonalizedResponseEntity response;
  final String? emptyMessage;

  const SurveyPersonalizedResults({
    required this.categories,
    required this.currentRequest,
    required this.hasPersonalizationEligible,
    required this.response,
    this.emptyMessage,
  });

  @override
  List<Object?> get props => [
        categories, currentRequest, hasPersonalizationEligible,
        response, emptyMessage,
      ];
}

/// Kết quả Group Discovery.
class SurveyGroupResults extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final List<GroupBoardGameEntity> games;
  final int totalCount;
  final String? emptyMessage;

  const SurveyGroupResults({
    required this.categories,
    required this.games,
    required this.totalCount,
    this.emptyMessage,
  });

  @override
  List<Object?> get props => [categories, games, totalCount, emptyMessage];
}

/// Không có kết quả.
class SurveyEmpty extends SurveyState {
  final List<GameCategoryDiscoveryEntity> categories;
  final DiscoveryRequestEntity currentRequest;
  final SoloMode soloMode;
  final bool hasPersonalizationEligible;
  final String message;

  const SurveyEmpty({
    required this.categories,
    required this.currentRequest,
    required this.soloMode,
    required this.hasPersonalizationEligible,
    required this.message,
  });

  @override
  List<Object?> get props => [
        categories, currentRequest, soloMode,
        hasPersonalizationEligible, message,
      ];
}

/// Lỗi.
class SurveyError extends SurveyState {
  final String message;
  final List<GameCategoryDiscoveryEntity>? categories;
  final DiscoveryRequestEntity? currentRequest;
  final SoloMode? soloMode;
  final bool? hasPersonalizationEligible;

  const SurveyError({
    required this.message,
    this.categories,
    this.currentRequest,
    this.soloMode,
    this.hasPersonalizationEligible,
  });

  @override
  List<Object?> get props => [
        message, categories, currentRequest, soloMode, hasPersonalizationEligible,
      ];
}
