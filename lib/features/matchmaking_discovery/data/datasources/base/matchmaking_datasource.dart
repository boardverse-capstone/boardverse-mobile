import '../../models/board_game_model.dart';
import '../../models/cafe_model.dart';
import '../../models/seat_availability_model.dart';
import '../../models/game_category_model.dart';
import '../../../domain/entities/search_filter_entity.dart';

/// Abstract interface cho Matchmaking DataSource
/// Khi backend sẵn sàng, chỉ cần tạo RemoteDataSource implement interface này
abstract class MatchmakingDatasource {
  // ─── Board Games ────────────────────────────────────────────────────
  
  /// Lấy tất cả games
  Future<List<BoardGameModel>> getAllGames();
  
  /// Lấy game theo ID
  Future<BoardGameModel?> getGameById(String id);
  
  /// Tìm kiếm games với filter
  Future<List<BoardGameModel>> searchGames(SearchFilterEntity filter);
  
  /// Lấy games tương tự
  Future<List<BoardGameModel>> getSimilarGames(String gameId);
  
  /// Lấy danh mục game categories
  Future<List<GameCategoryModel>> getGameCategories();

  // ─── Cafes ─────────────────────────────────────────────────────────
  
  /// Lấy danh sách quán gần đây với game
  Future<List<CafeModel>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });
  
  /// Lấy tất cả quán gần đây (không filter theo game)
  Future<List<CafeModel>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  });
  
  /// Lấy thông tin quán theo ID
  Future<CafeModel?> getCafeById(String id);
  
  /// Lấy games có sẵn tại quán
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
