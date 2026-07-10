import '../models/board_game_model.dart';
import '../models/cafe_model.dart';
import '../models/seat_availability_model.dart';
import '../models/game_category_model.dart';
import '../../domain/entities/search_filter_entity.dart';
import '../../domain/entities/cafe_entity.dart';
import '../../domain/entities/seat_availability_entity.dart';
import 'base/matchmaking_datasource.dart';

/// Mock data source for matchmaking discovery feature.
/// Implements MatchmakingDatasource interface for DataSource Abstraction.
/// When backend is ready, create MatchmakingRemoteDatasource implementing same interface.
class MockMatchmakingDatasource implements MatchmakingDatasource {
  // ─── Board Game Mock Data ───────────────────────────────────────────────

  /// Chi tiết một tựa game cụ thể
  static final BoardGameModel mockBoardGameDetail = BoardGameModel(
        id: 'bg_001',
        name: 'Avalon: The Resistance Game',
        description:
            'Avalon là game đối kháng giữa lực lượng Good và Evil. Người chơi sẽ được phân vai trò bí mật và tham gia các nhiệm vụ. Ai là kẻ phản bội ẩn mình trong đội quân của Arthur? Hãy phát hiện và loại bỏ chúng trước khi quá muộn!',
        imageUrl: 'https://picsum.photos/seed/avalon/800/600',
        minPlayers: 5,
        maxPlayers: 10,
        estimatedMinutes: 45,
        category: 'Social Deduction',
        components: const [
          '10 thẻ nhân vật',
          '25 thẻ nhiệm vụ',
          '5 thẻ Approve',
          '5 thẻ Reject',
          '7 marker nhiệm vụ',
          '1 marker lãnh đạo',
          'Sổ hướng dẫn',
        ],
        mechanics: const [
          'Secret Identity',
          'Deduction',
          'Voting',
          'Team Building',
          'Memory',
        ],
        rating: 4.8,
      );

  /// Danh sách các tựa game có phong cách chơi tương đồng
  static final List<BoardGameModel> mockSimilarGamesCarousel = [
        BoardGameModel(
          id: 'bg_002',
          name: 'Ma Sói (Werewolf)',
          description:
              'Game đối đầu giữa dân làng và người hóa sói. Mỗi đêm, bầy sói thức dậy giết người. Ban ngày, dân làng thảo luận và treo cổ kẻ tình nghi.',
          imageUrl: 'https://picsum.photos/seed/werewolf/800/600',
          minPlayers: 7,
          maxPlayers: 15,
          estimatedMinutes: 60,
          category: 'Social Deduction',
          components: const ['30 thẻ vai trò', 'Biểu quyết treo cổ'],
          mechanics: const ['Secret Identity', 'Deduction', 'Voting'],
          rating: 4.7,
        ),
        BoardGameModel(
          id: 'bg_003',
          name: 'One Night Ultimate Werewolf',
          description:
              'Phiên bản rút gọn của Ma Sói, chỉ 1 đêm duy nhất. Nhanh hơn, kịch tính hơn!',
          imageUrl: 'https://picsum.photos/seed/onu/800/600',
          minPlayers: 3,
          maxPlayers: 10,
          estimatedMinutes: 15,
          category: 'Social Deduction',
          components: const ['22 thẻ vai trò', 'Timer'],
          mechanics: const ['Secret Identity', 'Deduction', 'Voting'],
          rating: 4.5,
        ),
        BoardGameModel(
          id: 'bg_004',
          name: 'Secret Hitler',
          description:
              'Tìm kiếm kẻ phản bội ngụy trang trong số những người tự do. Fascist hay Liberal - ai sẽ thắng?',
          imageUrl: 'https://picsum.photos/seed/hitler/800/600',
          minPlayers: 5,
          maxPlayers: 10,
          estimatedMinutes: 30,
          category: 'Social Deduction',
          components: const ['17 thẻ chính trị', 'Đĩa quyền lực'],
          mechanics: const ['Secret Identity', 'Deduction', 'Voting', 'Bluffing'],
          rating: 4.6,
        ),
        BoardGameModel(
          id: 'bg_005',
          name: 'The Resistance: Spy',
          description:
              'Phiên bản CIA của Avalon. Tìm ra điệp viên trong tổ chức Resistance.',
          imageUrl: 'https://picsum.photos/seed/resistance/800/600',
          minPlayers: 5,
          maxPlayers: 10,
          estimatedMinutes: 30,
          category: 'Social Deduction',
          components: const ['10 thẻ nhân vật', 'Mission cards'],
          mechanics: const ['Secret Identity', 'Deduction', 'Voting', 'Team Building'],
          rating: 4.4,
        ),
        BoardGameModel(
          id: 'bg_006',
          name: 'Catan - Đảo Giấu Vàng',
          description:
              'Game chiến lược kinh điển. Xây dựng thị trấn, thu thập tài nguyên và thương mại để trở thành người chiến thắng!',
          imageUrl: 'https://picsum.photos/seed/catan/800/600',
          minPlayers: 3,
          maxPlayers: 4,
          estimatedMinutes: 90,
          category: 'Strategy',
          components: const ['19 Terrain hexes', '6 Sea frames', '95 Resource cards'],
          mechanics: const ['Area Control', 'Modular Board', 'Trading'],
          rating: 4.9,
        ),
        BoardGameModel(
          id: 'bg_007',
          name: 'Ticket to Ride',
          description:
              'Cuộc đua xuyên quốc gia bằng tàu hỏa. Thu thập thẻ wagon và hoàn thành tuyến đường để chiến thắng.',
          imageUrl: 'https://picsum.photos/seed/ticket/800/600',
          minPlayers: 2,
          maxPlayers: 5,
          estimatedMinutes: 60,
          category: 'Family',
          components: const ['225 Train cars', '144 Cards', '30 Tickets'],
          mechanics: const ['Hand Management', 'Route Building', 'Set Collection'],
          rating: 4.7,
        ),
        BoardGameModel(
          id: 'bg_008',
          name: 'Coup',
          description:
              'Game bluffing nhanh gọn trong thế giới chính trị tương lai. Ai là người duy trì quyền kiểm soát?',
          imageUrl: 'https://picsum.photos/seed/coup/800/600',
          minPlayers: 2,
          maxPlayers: 6,
          estimatedMinutes: 15,
          category: 'Social Deduction',
          components: const ['50 Coins', '15 Character cards', '5 Influence tiles'],
          mechanics: const ['Bluffing', 'Card Game', 'Deduction'],
          rating: 4.3,
        ),
      ];

  /// Tất cả games
  List<BoardGameModel> get _allGames => [
        mockBoardGameDetail,
        ...mockSimilarGamesCarousel,
      ];

  // ─── Cafe Mock Data với Seat Info ───────────────────────────────────

  /// Danh sách quán cafe đối tác có sẵn game, xếp từ gần đến xa
  static final List<CafeModel> mockCafeListWithSeats = [
        CafeModel(
          id: 'cafe_001',
          name: 'Board Game Hub District 1',
          address: '123 Nguyễn Trãi, Quận 1, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe1/400/300',
          distanceKm: 0.5,
          availableTables: 8,
          hasGameInStock: true,
          rating: 4.6,
          availableGameIds: const ['bg_001', 'bg_002', 'bg_003', 'bg_008'],
          // Seat-based fields (BR-01)
          totalSeats: 20,
          availableSeats: 12,
          seatStatus: CafeSeatStatus.available,
          depositAmount: 30000,
          depositMinutesLimit: 15,
          openingHours: '09:00 - 23:00',
          phoneNumber: '028 1234 5678',
        ),
        CafeModel(
          id: 'cafe_002',
          name: 'Meeple Station',
          address: '45 Lê Thánh Tôn, Quận 1, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe2/400/300',
          distanceKm: 1.2,
          availableTables: 5,
          hasGameInStock: true,
          rating: 4.8,
          availableGameIds: const ['bg_001', 'bg_004', 'bg_005', 'bg_006'],
          // Seat-based fields
          totalSeats: 16,
          availableSeats: 4,
          seatStatus: CafeSeatStatus.limited,
          depositAmount: 50000,
          depositMinutesLimit: 20,
          openingHours: '10:00 - 22:00',
          phoneNumber: '028 2345 6789',
        ),
        CafeModel(
          id: 'cafe_003',
          name: 'Dice & Drink Cafe',
          address: '78 Pasteur, Quận 1, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe3/400/300',
          distanceKm: 2.8,
          availableTables: 12,
          hasGameInStock: true,
          rating: 4.3,
          availableGameIds: const ['bg_001', 'bg_002', 'bg_003', 'bg_004', 'bg_007'],
          // Seat-based fields
          totalSeats: 30,
          availableSeats: 18,
          seatStatus: CafeSeatStatus.available,
          depositAmount: 25000,
          depositMinutesLimit: 15,
          openingHours: '08:00 - 00:00',
          phoneNumber: '028 3456 7890',
        ),
        CafeModel(
          id: 'cafe_004',
          name: 'Tabletop Garden',
          address: '201 Điện Biên Phủ, Quận 3, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe4/400/300',
          distanceKm: 4.5,
          availableTables: 6,
          hasGameInStock: true,
          rating: 4.7,
          availableGameIds: const ['bg_001', 'bg_005', 'bg_006', 'bg_007'],
          // Seat-based fields
          totalSeats: 12,
          availableSeats: 0,
          seatStatus: CafeSeatStatus.full,
          depositAmount: 40000,
          depositMinutesLimit: 30,
          openingHours: '11:00 - 21:00',
          phoneNumber: '028 4567 8901',
        ),
        CafeModel(
          id: 'cafe_005',
          name: 'Roll & Play House',
          address: '88 Võ Văn Tần, Quận 3, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe5/400/300',
          distanceKm: 6.2,
          availableTables: 10,
          hasGameInStock: true,
          rating: 4.5,
          availableGameIds: const ['bg_001', 'bg_002', 'bg_004', 'bg_005', 'bg_006'],
          // Seat-based fields
          totalSeats: 24,
          availableSeats: 10,
          seatStatus: CafeSeatStatus.available,
          depositAmount: 35000,
          depositMinutesLimit: 20,
          openingHours: '10:00 - 23:00',
          phoneNumber: '028 5678 9012',
        ),
      ];

  // ─── Game Categories ─────────────────────────────────────────────────

  static final List<GameCategoryModel> mockCategories = [
        GameCategoryModel(
          id: 'cat_001',
          name: 'Social Deduction',
          iconName: 'psychology',
          gameCount: 5,
          description: 'Game đối kháng, phát hiện kẻ phản bội',
        ),
        GameCategoryModel(
          id: 'cat_002',
          name: 'Strategy',
          iconName: 'account_tree',
          gameCount: 3,
          description: 'Game chiến lược, lập kế hoạch dài hạn',
        ),
        GameCategoryModel(
          id: 'cat_003',
          name: 'Family',
          iconName: 'family_restroom',
          gameCount: 2,
          description: 'Game phù hợp cho gia đình, mọi lứa tuổi',
        ),
        GameCategoryModel(
          id: 'cat_004',
          name: 'Party',
          iconName: 'celebration',
          gameCount: 2,
          description: 'Game tiệc tùng, nhiều người chơi',
        ),
        GameCategoryModel(
          id: 'cat_005',
          name: 'Cooperative',
          iconName: 'groups',
          gameCount: 1,
          description: 'Game hợp tác, cùng nhau chiến thắng',
        ),
      ];

  // ─── Simulated Seat Data ─────────────────────────────────────────────

  /// Map cafeId -> seat availability
  static final Map<String, SeatAvailabilityModel> _seatAvailabilityCache = {
    'cafe_001': SeatAvailabilityModel(
      cafeId: 'cafe_001',
      cafeName: 'Board Game Hub District 1',
      totalSeats: 20,
      availableSeats: 12,
      holdingSeats: 2,
      reservedSeats: 4,
      inUseSeats: 2,
      overallStatus: SeatOverallStatus.plenty,
      lastUpdated: DateTime.now(),
    ),
    'cafe_002': SeatAvailabilityModel(
      cafeId: 'cafe_002',
      cafeName: 'Meeple Station',
      totalSeats: 16,
      availableSeats: 4,
      holdingSeats: 2,
      reservedSeats: 6,
      inUseSeats: 4,
      overallStatus: SeatOverallStatus.limited,
      lastUpdated: DateTime.now(),
    ),
    'cafe_003': SeatAvailabilityModel(
      cafeId: 'cafe_003',
      cafeName: 'Dice & Drink Cafe',
      totalSeats: 30,
      availableSeats: 18,
      holdingSeats: 4,
      reservedSeats: 6,
      inUseSeats: 2,
      overallStatus: SeatOverallStatus.plenty,
      lastUpdated: DateTime.now(),
    ),
    'cafe_004': SeatAvailabilityModel(
      cafeId: 'cafe_004',
      cafeName: 'Tabletop Garden',
      totalSeats: 12,
      availableSeats: 0,
      holdingSeats: 0,
      reservedSeats: 8,
      inUseSeats: 4,
      overallStatus: SeatOverallStatus.unavailable,
      lastUpdated: DateTime.now(),
      nextAvailableAt: DateTime.now().add(const Duration(hours: 2)),
    ),
    'cafe_005': SeatAvailabilityModel(
      cafeId: 'cafe_005',
      cafeName: 'Roll & Play House',
      totalSeats: 24,
      availableSeats: 10,
      holdingSeats: 2,
      reservedSeats: 8,
      inUseSeats: 4,
      overallStatus: SeatOverallStatus.moderate,
      lastUpdated: DateTime.now(),
    ),
  };

  // ─── MatchmakingDatasource Implementation ──────────────────────────────────

  @override
  Future<List<BoardGameModel>> getAllGames() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _allGames;
  }

  @override
  Future<BoardGameModel?> getGameById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return _allGames.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BoardGameModel>> searchGames(SearchFilterEntity filter) async {
    await Future.delayed(const Duration(milliseconds: 400));
    var results = _allGames;

    // Filter by query
    if (filter.query != null && filter.query!.isNotEmpty) {
      final query = filter.query!.toLowerCase();
      results = results
          .where((g) =>
              g.name.toLowerCase().contains(query) ||
              g.description.toLowerCase().contains(query) ||
              g.category.toLowerCase().contains(query))
          .toList();
    }

    // Filter by category
    if (filter.category != null && filter.category!.isNotEmpty) {
      results = results.where((g) => g.category == filter.category).toList();
    }

    // Filter by min players
    if (filter.minPlayers != null) {
      results = results.where((g) => g.maxPlayers >= filter.minPlayers!).toList();
    }

    // Filter by max players
    if (filter.maxPlayers != null) {
      results = results.where((g) => g.minPlayers <= filter.maxPlayers!).toList();
    }

    // Filter by estimated time
    if (filter.estimatedMinutesMax != null) {
      results =
          results.where((g) => g.estimatedMinutes <= filter.estimatedMinutesMax!).toList();
    }

    return results;
  }

  @override
  Future<List<BoardGameModel>> getSimilarGames(String gameId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final game = await getGameById(gameId);
    if (game == null) return [];

    // Return games in same category (excluding current game)
    return _allGames
        .where((g) => g.category == game.category && g.id != gameId)
        .toList();
  }

  @override
  Future<List<GameCategoryModel>> getGameCategories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return mockCategories;
  }

  @override
  Future<List<CafeModel>> getNearbyCafesWithGame({
    required String gameId,
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return mockCafeListWithSeats
        .where((cafe) =>
            cafe.availableGameIds.contains(gameId) &&
            cafe.distanceKm <= radiusKm)
        .toList();
  }

  @override
  Future<List<CafeModel>> getNearbyCafes({
    required double latitude,
    required double longitude,
    double radiusKm = 15.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return mockCafeListWithSeats
        .where((cafe) => cafe.distanceKm <= radiusKm)
        .toList();
  }

  @override
  Future<CafeModel?> getCafeById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      return mockCafeListWithSeats.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<BoardGameModel>> getCafeGames(String cafeId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final cafe = await getCafeById(cafeId);
    if (cafe == null) return [];

    return _allGames
        .where((g) => cafe.availableGameIds.contains(g.id))
        .toList();
  }

  @override
  Future<SeatAvailabilityModel> getSeatAvailability({
    required String cafeId,
    required DateTime timeSlot,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Return cached data with updated timestamp
    final cached = _seatAvailabilityCache[cafeId];
    if (cached != null) {
      return SeatAvailabilityModel(
        cafeId: cached.cafeId,
        cafeName: cached.cafeName,
        totalSeats: cached.totalSeats,
        availableSeats: cached.availableSeats,
        holdingSeats: cached.holdingSeats,
        reservedSeats: cached.reservedSeats,
        inUseSeats: cached.inUseSeats,
        overallStatus: cached.overallStatus,
        lastUpdated: DateTime.now(),
        nextAvailableAt: cached.nextAvailableAt,
      );
    }

    // Return default if cafe not found
    return SeatAvailabilityModel(
      cafeId: cafeId,
      cafeName: 'Unknown Cafe',
      totalSeats: 20,
      availableSeats: 0,
      holdingSeats: 0,
      reservedSeats: 0,
      inUseSeats: 0,
      overallStatus: SeatOverallStatus.unavailable,
      lastUpdated: DateTime.now(),
    );
  }

  @override
  Future<bool> checkSeatsAvailable({
    required String cafeId,
    required int requiredSeats,
    required DateTime timeSlot,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final availability = await getSeatAvailability(
      cafeId: cafeId,
      timeSlot: timeSlot,
    );
    
    // BR-05: Check if enough seats available
    return availability.availableSeats >= requiredSeats;
  }
}
