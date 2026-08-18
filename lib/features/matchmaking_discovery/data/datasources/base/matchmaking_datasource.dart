import '../../models/board_game_model.dart';
import '../../models/cafe_model.dart';
import '../../models/cafe_detail_model.dart';
import '../../models/default_time_slot_model.dart';
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

  /// `GET /api/v1/manager/time-slots/defaults`
  ///
  /// Trả về 4 khung giờ cố định của hệ thống (Morning/Afternoon/Evening/
  /// LateNight). Tài liệu gắn tag "Manager" nhưng dữ liệu là metadata
  /// chung — Player mobile cũng dùng để hiển thị khung giờ ở LobbyConfig.
  /// Nếu backend reject với 403 thì chỉ cần nâng cấp role của player token
  /// hoặc đổi endpoint; abstraction này giữ cho UI không phụ thuộc.
  Future<List<DefaultTimeSlotModel>> getDefaultTimeSlots();

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
  ///
  /// Lưu ý: backend **không còn bắt buộc** `gameTemplateId` — nếu vắng,
  /// endpoint trả về tất cả quán trong bán kính (không filter theo game).
  /// Vẫn giữ optional để host BoardGameDetail có thể filter theo game cụ
  /// thể khi cần.
  Future<NearbyCafesSearchResultModel> getNearbyCafesSearch({
    String? gameTemplateId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// `GET /api/cafes/nearby/me?gameTemplateId=...` (cần Bearer token)
  ///
  /// Backend đã **bỏ yêu cầu bắt buộc** `gameTemplateId`. Khi vắng, trả
  /// về tất cả quán trong bán kính (mặc định 15 km) quanh vị trí đã lưu
  /// trên profile — dùng cho Cafe tab trên SearchPage.
  Future<NearbyCafesSearchResultModel> getNearbyCafesForCurrentUser({
    String? gameTemplateId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// `GET /api/cafes/search?name=...&latitude=...&longitude=...` (không cần gameTemplateId)
  /// Dùng khi player đã biết tên quán, muốn tìm nhanh để đặt chỗ.
  Future<NearbyCafesSearchResultModel> searchCafes({
    required String name,
    double? latitude,
    double? longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Lấy thông tin quán theo ID — `GET /api/cafes/{id}`
  Future<CafeDetailModel?> getCafeById(String id);

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
