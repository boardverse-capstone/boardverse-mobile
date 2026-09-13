import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/board_game_detail_entity.dart';
import '../entities/board_game_entity.dart';
import '../entities/cafe_detail_entity.dart';
import '../entities/cafe_entity.dart';
import '../entities/game_play_configuration_entity.dart';
import '../entities/game_play_navigation_entity.dart';
import '../entities/nearby_cafes_search_result_entity.dart';
import '../entities/seat_availability_entity.dart';
import '../entities/search_filter_entity.dart';
import '../entities/game_category_entity.dart';

abstract class MatchmakingRepository {
  // ─── Board Games ────────────────────────────────────────────────────

  /// Tìm kiếm games với filter (legacy — dùng cho Mock).
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  });

  /// Tìm kiếm games với SearchFilterEntity (mở rộng — dùng cho Mock).
  Future<Either<Failure, List<BoardGameEntity>>> searchGames(
      SearchFilterEntity filter);

  /// Tìm kiếm + lọc + phân trang — map thẳng vào
  /// `GET /api/v1/board-games?...`. Trả về list kết quả (không kèm meta).
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGamesPaged({
    String? query,
    List<String>? categoryIds,
    int? playerCount,
    List<DurationRange>? durationRanges,
    int pageNumber = 1,
    int pageSize = 10,
  });

  /// Lấy thông tin game theo ID.
  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id);

  /// Lấy chi tiết game + components (dùng cho màn detail mới).
  Future<Either<Failure, BoardGameDetailEntity?>> getBoardGameDetails(
    String id,
  );

  /// Lấy games tương tự
  Future<Either<Failure, List<BoardGameEntity>>> getSimilarGames({
    required String gameId,
    required double latitude,
    required double longitude,
  });

  /// Lấy danh mục game categories
  Future<Either<Failure, List<GameCategoryEntity>>> getGameCategories();

  /// Lấy tất cả games
  Future<Either<Failure, List<BoardGameEntity>>> getAllGames();

  // ─── Cafes ─────────────────────────────────────────────────────────

  /// Tìm quán gần theo toạ độ GPS — dùng cho Mock (legacy).
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// Lấy tất cả quán gần đây (legacy, dùng cho Mock).
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// Tìm quán gần có game — map thẳng vào `GET /api/cafes/nearby?...`
  /// Response bao gồm `emptyResultMessage` + `alternativeSuggestions`.
  ///
  /// Backend **không còn bắt buộc** `gameId` — để null sẽ trả tất cả quán
  /// trong bán kính (không filter theo game). Thường chỉ host
  /// BoardGameDetail mới cần truyền `gameId`.
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesWithGameSearch({
    String? gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Tìm quán gần dùng vị trí đã lưu — map vào `GET /api/cafes/nearby/me`
  /// (cần auth token).
  ///
  /// Backend đã **bỏ yêu cầu bắt buộc** `gameId`. Cafe tab trên SearchPage
  /// giờ gọi thẳng không cần gameId — đơn giản hoá flow và loại bỏ việc
  /// pre-fetch popular game.
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesForCurrentUser({
    String? gameId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Tìm kiếm quán cafe theo tên — `GET /api/cafes/search?name=...`
  /// (không cần gameTemplateId, public endpoint).
  Future<Either<Failure, NearbyCafesSearchResultEntity>> searchCafes({
    required String name,
    double? latitude,
    double? longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Lấy thông tin quán theo ID — `GET /api/cafes/{id}`.
  /// Trả về [CafeDetailEntity] với đầy đủ fields (operationalStatus,
  /// refund policy, cafe config, …) phục vụ trang chi tiết.
  Future<Either<Failure, CafeDetailEntity?>> getCafeById(String id);

  /// Lấy chi tiết quán theo ID — `GET /api/cafes/{id}`
  /// (alias của [getCafeById] — giữ để tương thích với code cũ).
  Future<Either<Failure, CafeDetailEntity?>> getCafeDetail(String id);

  /// Lấy games có sẵn tại quán (legacy, dùng cho Mock).
  Future<Either<Failure, List<BoardGameEntity>>> getCafeGames(String cafeId);

  /// Lấy danh sách board game đang hoạt động tại quán cafe —
  /// `GET /api/cafes/{cafeId}/active-games` (public, không cần token).
  ///
  /// Dùng khi player đặt chỗ từ trang chi tiết quán để hiển thị
  /// chỉ game có sẵn tại quán, thay vì toàn bộ game hệ thống.
  ///
  /// Query params:
  /// - `categoryId`: lọc theo thể loại.
  /// - `groupSize`: chỉ trả game có `minPlayers <= groupSize`.
  /// - `availableOnly`: `true` → chỉ trả game có `availableBoxCount > 0`.
  /// - `searchTerm`: tìm theo tên game.
  /// - `sortBy`: Name | AvailableBoxesDesc | PlayTimeAsc | PlayerCountAsc.
  /// - `pageNumber`, `pageSize`: phân trang (mặc định pageSize=100 để
  ///   lấy tất cả game của quán).
  ///
  /// Docs: `.agents/docs/apis_docs/cafe.md` §GET /api/cafes/{cafeId}/active-games
  Future<Either<Failure, List<BoardGameEntity>>> getCafeActiveGames(
    String cafeId, {
    String? categoryId,
    int? groupSize,
    bool availableOnly = false,
    String? searchTerm,
    String? sortBy,
    int pageNumber = 1,
    int pageSize = 100,
  });

  // ─── Seat Availability (Real-time) ──────────────────────────────────

  /// Lấy thông tin ghế trống của quán tại một khung giờ
  Future<Either<Failure, SeatAvailabilityEntity>> getSeatAvailability({
    required String cafeId,
    required DateTime timeSlot,
  });

  /// Kiểm tra xem quán có đủ ghế cho số lượng yêu cầu không (BR-05)
  Future<Either<Failure, bool>> checkSeatsAvailable({
    required String cafeId,
    required int requiredSeats,
    required DateTime timeSlot,
  });

  // ─── Play Configuration & Navigation (API mới) ─────────────────────

  /// `GET /api/v1/board-games/{id}/play-configuration`
  Future<Either<Failure, GamePlayConfigurationEntity>>
      getGamePlayConfiguration(String gameId);

  /// `POST /api/v1/board-games/{id}/play-navigation` body `{"playMode":0|1}`
  Future<Either<Failure, GamePlayNavigationEntity>> resolvePlayNavigation({
    required String gameId,
    required PlayMode mode,
  });

  // BR-NEW (2026-08-27): `getDefaultTimeSlots()` đã bị xoá — backend không
  // còn xử lý `timeSlot` enum cho reservation/lobby creation. Player tự
  // do chọn giờ bắt đầu / kết thúc trong cùng 1 ngày.
}
