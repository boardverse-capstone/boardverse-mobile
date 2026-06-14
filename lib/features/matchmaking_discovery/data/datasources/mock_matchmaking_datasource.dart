import '../models/board_game_model.dart';
import '../models/cafe_model.dart';

/// Mock data source for matchmaking discovery feature.
/// Provides realistic sample data for UI development and testing.
class MockMatchmakingDatasource {
  // ─── Board Game Mock Data ───────────────────────────────────────────────

  /// Chi tiết một tựa game cụ thể
  static BoardGameModel get mockBoardGameDetail => const BoardGameModel(
        id: 'bg_001',
        name: 'Avalon: The Resistance Game',
        description:
            'Avalon là game đối kháng giữa lực lượng Good và Evil. Người chơi sẽ được phân vai trò bí mật và tham gia các nhiệm vụ. Ai là kẻ phản bội ẩn mình trong đội quân của Arthur? Hãy phát hiện và loại bỏ chúng trước khi quá muộn!',
        imageUrl: 'https://picsum.photos/seed/avalon/800/600',
        minPlayers: 5,
        maxPlayers: 10,
        estimatedMinutes: 45,
        category: 'Social Deduction',
        components: [
          '10 thẻ nhân vật',
          '25 thẻ nhiệm vụ',
          '5 thẻ Approve',
          '5 thẻ Reject',
          '7 marker nhiệm vụ',
          '1 marker lãnh đạo',
          'Sổ hướng dẫn',
        ],
        mechanics: [
          'Secret Identity',
          'Deduction',
          'Voting',
          'Team Building',
          'Memory',
        ],
        rating: 4.8,
      );

  /// Danh sách các tựa game có phong cách chơi tương đồng
  static List<BoardGameModel> get mockSimilarGamesCarousel => const [
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
          components: ['30 thẻ vai trò', 'Biểu quyết treo cổ'],
          mechanics: ['Secret Identity', 'Deduction', 'Voting'],
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
          components: ['22 thẻ vai trò', 'Timer'],
          mechanics: ['Secret Identity', 'Deduction', 'Voting'],
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
          components: ['17 thẻ chính trị', 'Đĩa quyền lực'],
          mechanics: ['Secret Identity', 'Deduction', 'Voting', 'Bluffing'],
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
          components: ['10 thẻ nhân vật', 'Mission cards'],
          mechanics: ['Secret Identity', 'Deduction', 'Voting', 'Team Building'],
          rating: 4.4,
        ),
      ];

  // ─── Cafe Mock Data ────────────────────────────────────────────────────

  /// Danh sách quán cafe đối tác có sẵn game, xếp từ gần đến xa
  static List<CafeModel> get mockCafeListWithGps => const [
        CafeModel(
          id: 'cafe_001',
          name: 'Board Game Hub District 1',
          address: '123 Nguyễn Trãi, Quận 1, TP.HCM',
          imageUrl: 'https://picsum.photos/seed/cafe1/400/300',
          distanceKm: 0.5,
          availableTables: 8,
          hasGameInStock: true,
          rating: 4.6,
          availableGameIds: ['bg_001', 'bg_002', 'bg_003'],
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
          availableGameIds: ['bg_001', 'bg_004', 'bg_005'],
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
          availableGameIds: ['bg_001', 'bg_002', 'bg_003', 'bg_004'],
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
          availableGameIds: ['bg_001', 'bg_005'],
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
          availableGameIds: ['bg_001', 'bg_002', 'bg_004', 'bg_005'],
        ),
      ];

  // ─── Search Mock Data ──────────────────────────────────────────────────

  /// Kết quả tìm kiếm game
  List<BoardGameModel> searchBoardGames({
    String? query,
    String? category,
    int? minPlayers,
    int? maxPlayers,
  }) {
    var results = <BoardGameModel>[
      mockBoardGameDetail,
      ...mockSimilarGamesCarousel,
    ];

    if (query != null && query.isNotEmpty) {
      results = results
          .where((g) =>
              g.name.toLowerCase().contains(query.toLowerCase()) ||
              g.description.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    if (category != null && category.isNotEmpty) {
      results = results.where((g) => g.category == category).toList();
    }

    if (minPlayers != null) {
      results =
          results.where((g) => g.maxPlayers >= minPlayers).toList();
    }

    if (maxPlayers != null) {
      results = results.where((g) => g.minPlayers <= maxPlayers).toList();
    }

    return results;
  }
}
