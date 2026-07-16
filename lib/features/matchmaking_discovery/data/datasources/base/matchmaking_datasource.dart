import '../../models/board_game_model.dart';
import '../../models/cafe_model.dart';
import '../../models/seat_availability_model.dart';
import '../../models/game_category_model.dart';
import '../../models/board_game_detail_model.dart';
import '../../models/nearby_cafes_search_result_model.dart';
import '../../models/game_play_configuration_model.dart';
import '../../models/game_play_navigation_model.dart';
import '../../../domain/entities/search_filter_entity.dart';
import '../../../domain/entities/game_play_configuration_entity.dart';

/// Abstract interface cho Matchmaking DataSource.
/// Khi backend sẵn sàng, chỉ cần tạo RemoteDataSource implement interface này.
abstract class MatchmakingDatasource {
  // ─── Board Games ────────────────────────────────────────────────────

  /// Lấy tất cả games
  Future<List<BoardGameModel>> getAllGames();

  /// Lấy game theo ID
  Future<BoardGameModel?> getGameById(String id);

  /// Tìm kiếm games với filter (legacy)
  Future<List<BoardGameModel>> searchGames(SearchFilterEntity filter);

  /// Tìm kiếm + lọc + phân trang — gọi `/api/v1/board-games?...`
  Future<List<BoardGameModel>> getBoardGamesPaged({
    String? search,
    List<String>? categoryIds,
    int? playerCount,
    List<DurationRange>? durationRanges,
    int pageNumber = 1,
    int pageSize = 10,
  });

  /// Lấy chi tiết game + components — `GET /api/v1/board-games/{id}`
  Future<BoardGameDetailModel?> getBoardGameDetails(String id);

  /// Lấy games tương tự (legacy, dùng cho Mock)
  Future<List<BoardGameModel>> getSimilarGames(String gameId);

  /// Lấy danh mục game categories — `GET /api/v1/board-games/categories`
  Future<List<GameCategoryModel>> getGameCategories();

  /// `GET /api/v1/board-games/{id}/play-configuration`
  Future<GamePlayConfigurationModel?> getGamePlayConfiguration(String gameId);

  /// `POST /api/v1/board-games/{id}/play-navigation`
  Future<GamePlayNavigationModel> resolvePlayNavigation({
    required String gameId,
    required PlayMode mode,
  });

  // ─── Cafes ─────────────────────────────────────────────────────────

  /// Lấy danh sách quán gần đây với game (legacy, dùng cho Mock)
  Future<List<CafeModel>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// Lấy tất cả quán gần đây (legacy, dùng cho Mock)
  Future<List<CafeModel>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// `GET /api/cafes/nearby?gameTemplateId=...&latitude=...&longitude=...`
  Future<NearbyCafesSearchResultModel> getNearbyCafesSearch({
    required String gameTemplateId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// `GET /api/cafes/nearby/me?gameTemplateId=...` (cần Bearer token)
  Future<NearbyCafesSearchResultModel> getNearbyCafesForCurrentUser({
    required String gameTemplateId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Lấy thông tin quán theo ID — `GET /api/cafes/{id}`
  Future<CafeModel?> getCafeById(String id);

  /// Lấy games có sẵn tại quán (legacy, dùng cho Mock)
  Future<List<BoardGameModel>> getCafeGames(String cafeId);

  // ─── Seat Availability (Real-time) ──────────────────────────────────

  /// Lấy thông tin ghế trống của quán tại một khung giờ
  Future<SeatAvailabilityModel> getSeatAvailability({
    required String cafeId,
    required DateTime timeSlot,
  });

  /// Kiểm tra xem quán có đủ ghế cho số lượng yêu cầu không (BR-05)
  Future<bool> checkSeatsAvailable({
    required String cafeId,
    required int requiredSeats,
    required DateTime timeSlot,
  });
}
