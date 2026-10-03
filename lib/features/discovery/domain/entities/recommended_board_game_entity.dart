import 'package:equatable/equatable.dart';

/// Entity đại diện cho một board game được gợi ý trong Survey
/// (Solo Survey thường — không có personalization).
class RecommendedBoardGameEntity extends Equatable {
  final String id;
  final String name;

  /// URL ảnh đại diện — map từ `thumbnailUrl`.
  final String? imageUrl;

  /// Độ phức tạp (BGG weight) — có thể null nếu chưa có data từ BGG.
  final double? weight;

  final int minPlayers;
  final int maxPlayers;

  /// Thời gian chơi trung bình (phút) — map từ `playTimeMinutes`.
  final int playTimeMinutes;

  /// Danh sách thể loại (string) — map từ `categories`.
  final List<String> categories;

  /// Điểm match score (0-100).
  final double score;

  /// Trạng thái đã lưu vào danh sách yêu thích — map từ field `isSaved`
  /// trong response của survey/personalized. Dùng làm "icon hint" hiển thị
  /// ban đầu khi [SavedGamesCubit] chưa load xong (SavedGamesInitial /
  /// SavedGamesError không có savedIds) → tránh trường hợp user thấy icon
  /// "chưa lưu" dù DB đã có bản ghi save.
  final bool isSaved;

  /// Các lý do game này được gợi ý.
  /// Ví dụ: ["Số người chơi phù hợp", "Weight phù hợp mức độ phức tạp mong muốn"]
  final List<String> matchReasons;

  const RecommendedBoardGameEntity({
    required this.id,
    required this.name,
    this.imageUrl,
    this.weight,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    required this.categories,
    required this.score,
    this.isSaved = false,
    this.matchReasons = const [],
  });

  String get playerRangeDisplay =>
      minPlayers == maxPlayers ? '$minPlayers người' : '$minPlayers-$maxPlayers người';

  @override
  List<Object?> get props => [
        id, name, imageUrl, weight, minPlayers, maxPlayers,
        playTimeMinutes, categories, score, isSaved, matchReasons,
      ];
}