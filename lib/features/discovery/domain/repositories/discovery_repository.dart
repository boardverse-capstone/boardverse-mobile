import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/board_game_save_result_entity.dart';
import '../entities/discovery_request_entity.dart';
import '../entities/game_category_discovery_entity.dart';
import '../entities/group_board_game_entity.dart';
import '../entities/recommended_board_game_entity.dart';
import '../entities/saved_board_game_entity.dart';
import '../entities/solo_personalized_response_entity.dart';

/// Repository abstraction cho Discovery feature.
///
/// Cung cấp các phương thức để gọi Discovery API:
/// - Survey (Solo thường)
/// - Solo Personalized (cá nhân hóa từ saved games)
/// - Group Discovery
/// - Saved Games (CRUD)
abstract class DiscoveryRepository {
  // ─── Categories ────────────────────────────────────────────────────

  /// Lấy danh mục thể loại board game cho bộ lọc.
  Future<Either<Failure, List<GameCategoryDiscoveryEntity>>> getCategories();

  // ─── Solo Survey ──────────────────────────────────────────────────

  /// Khảo sát gợi ý solo (filter-based, không có personalization).
  /// Auth: Optional.
  Future<Either<Failure, List<RecommendedBoardGameEntity>>> runSurvey(
    DiscoveryRequestEntity request,
  );

  // ─── Solo Personalized ────────────────────────────────────────────

  /// Gợi ý cá nhân hóa — yêu cầu user đã đăng nhập.
  /// Cần ≥3 saved games để có userProfile; fallback về generic nếu chưa đủ.
  /// Auth: Required.
  Future<Either<Failure, SoloPersonalizedResponseEntity>>
      getSoloPersonalized({
    required DiscoveryRequestEntity request,
    double? latitude,
    double? longitude,
    int pageSize = 20,
    bool excludeSavedGames = false,
  });

  // ─── Group Discovery ──────────────────────────────────────────────

  /// Khảo sát gợi ý cho nhóm với nhiều sub-groups.
  /// Auth: Required.
  Future<Either<Failure, List<GroupBoardGameEntity>>> discoverForGroup({
    required List<MemberPreferenceRequest> members,
    double? latitude,
    double? longitude,
  });

  // ─── Saved Games ──────────────────────────────────────────────────

  /// Lấy danh sách games đã lưu của user.
  /// Auth: Required.
  Future<Either<Failure, List<SavedBoardGameEntity>>> getSavedGames();

  /// Toggle save/unsave một game.
  /// Auth: Required.
  Future<Either<Failure, BoardGameSaveResultEntity>> toggleSave(
    String gameTemplateId,
  );

  /// Xóa game khỏi danh sách lưu.
  /// Auth: Required.
  Future<Either<Failure, bool>> unsaveGame(String gameTemplateId);

  /// Đếm số game đã lưu (dùng để check personalization eligibility).
  Future<int> getSavedGamesCount();
}

/// DTO cho preference của một sub-group trong Group Discovery.
class MemberPreferenceRequest extends Equatable {
  /// UserId của thành viên (optional) — nếu có, backend tự extract
  /// saved-game preferences để personalize.
  final String? userId;
  final int playerCount;
  final int? experienceLevel;
  final List<String>? categoryIds;
  final List<String>? preferredDurations;
  final List<int>? weightRanges;
  final String? note;

  const MemberPreferenceRequest({
    this.userId,
    required this.playerCount,
    this.experienceLevel,
    this.categoryIds,
    this.preferredDurations,
    this.weightRanges,
    this.note,
  });

  @override
  List<Object?> get props => [
        userId, playerCount, experienceLevel,
        categoryIds, preferredDurations, weightRanges, note,
      ];
}
