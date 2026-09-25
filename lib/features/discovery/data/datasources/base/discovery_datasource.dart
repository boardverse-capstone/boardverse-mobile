import '../../models/board_game_save_result_model.dart';
import '../../models/discovery_category_model.dart';
import '../../models/group_discovery_response_model.dart';
import '../../models/saved_games_response_model.dart';
import '../../models/solo_personalized_response_model.dart';
import '../../models/survey_response_model.dart';

/// Abstract interface cho Discovery DataSource.
///
/// Layer giao tiếp trực tiếp với Discovery API endpoints.
/// Tầng Repository gọi qua interface này (có thể mock trong test).
abstract class DiscoveryDatasource {
  /// GET /api/v1/discovery/categories — Danh mục thể loại (public).
  Future<List<DiscoveryCategoryModel>> getCategories();

  /// POST /api/v1/discovery/survey — Khảo sát solo (filter-based).
  /// Auth: Optional.
  Future<SurveyResponseModel> runSurvey({
    int? playerCount,
    List<String>? categoryIds,
    List<String>? preferredDurations,
    List<int>? weightRanges,
    int? experienceLevel,
    String? searchKeyword,
  });

  /// POST /api/v1/discovery/solo-personalized — Gợi ý cá nhân hóa.
  /// Auth: Required (tự động qua AuthInterceptor).
  Future<SoloPersonalizedResponseModel> getSoloPersonalized({
    int? playerCount,
    List<String>? categoryIds,
    List<String>? preferredDurations,
    List<int>? weightRanges,
    String? searchKeyword,
    int pageSize = 20,
    bool excludeSavedGames = false,
    double? latitude,
    double? longitude,
  });

  /// POST /api/v1/discovery/group — Khảo sát cho nhóm.
  /// Auth: Required.
  Future<GroupDiscoveryResponseModel> discoverForGroup({
    required List<Map<String, dynamic>> members,
    double? latitude,
    double? longitude,
  });

  /// GET /api/v1/discovery/saved — Danh sách game đã lưu.
  Future<SavedGamesResponseModel> getSavedGames();

  /// POST /api/v1/discovery/saved/{gameTemplateId} — Toggle save/unsave.
  Future<BoardGameSaveResultModel> toggleSave(String gameTemplateId);

  /// DELETE /api/v1/discovery/saved/{gameTemplateId} — Xóa khỏi lưu.
  Future<bool> unsaveGame(String gameTemplateId);
}
