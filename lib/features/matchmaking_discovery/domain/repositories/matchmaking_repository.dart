import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/board_game_detail_entity.dart';
import '../entities/board_game_entity.dart';
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
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesWithGameSearch({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Tìm quán gần dùng vị trí đã lưu — map vào `GET /api/cafes/nearby/me`
  /// (cần auth token).
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getNearbyCafesForCurrentUser({
    required String gameId,
    double radiusKm = 15.0,
    int pageNumber = 1,
    int pageSize = 20,
  });

  /// Lấy thông tin quán theo ID.
  Future<Either<Failure, CafeEntity?>> getCafeById(String id);

  /// Lấy games có sẵn tại quán (legacy, dùng cho Mock).
  Future<Either<Failure, List<BoardGameEntity>>> getCafeGames(String cafeId);

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
}
