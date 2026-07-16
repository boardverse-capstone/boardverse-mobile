import 'package:equatable/equatable.dart';

import 'alternative_game_suggestion_entity.dart';
import 'cafe_entity.dart';

/// Kết quả trả về của `GET /api/cafes/nearby` (và `/api/cafes/nearby/me`).
/// Bao gồm danh sách quán, thông báo UI khi rỗng, và gợi ý game thay thế
/// khi không tìm được quán nào (AC 5.1, 5.2).
class NearbyCafesSearchResultEntity extends Equatable {
  final List<CafeEntity> cafes;

  /// Thông điệp UI khi danh sách rỗng (AC 5.1). `null` khi có kết quả.
  final String? emptyResultMessage;

  /// Gợi ý game cùng thể loại còn hàng (AC 5.2). `[]` khi có quán.
  final List<AlternativeGameSuggestionEntity> alternativeSuggestions;

  const NearbyCafesSearchResultEntity({
    this.cafes = const [],
    this.emptyResultMessage,
    this.alternativeSuggestions = const [],
  });

  bool get isEmpty => cafes.isEmpty;

  @override
  List<Object?> get props => [
        cafes,
        emptyResultMessage,
        alternativeSuggestions,
      ];
}
