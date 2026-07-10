import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/board_game_entity.dart';
import '../entities/cafe_entity.dart';
import '../entities/seat_availability_entity.dart';
import '../entities/search_filter_entity.dart';
import '../entities/game_category_entity.dart';

abstract class MatchmakingRepository {
  // ─── Board Games ────────────────────────────────────────────────────

  /// Tìm kiếm games với filter
  Future<Either<Failure, List<BoardGameEntity>>> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  });

  /// Tìm kiếm games với SearchFilterEntity (mở rộng)
  Future<Either<Failure, List<BoardGameEntity>>> searchGames(SearchFilterEntity filter);

  /// Lấy thông tin game theo ID
  Future<Either<Failure, BoardGameEntity?>> getBoardGameById(String id);

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

  /// Lấy danh sách quán có game cụ thể
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// Lấy tất cả quán gần đây
  Future<Either<Failure, List<CafeEntity>>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });

  /// Lấy thông tin quán theo ID
  Future<Either<Failure, CafeEntity?>> getCafeById(String id);

  /// Lấy games có sẵn tại quán
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
}
