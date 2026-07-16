import '../../domain/entities/nearby_cafes_search_result_entity.dart';
import 'alternative_game_suggestion_model.dart';
import 'cafe_model.dart';

/// Model cho response `GET /api/cafes/nearby` (và `/api/cafes/nearby/me`).
class NearbyCafesSearchResultModel {
  final List<CafeModel> cafes;
  final String? emptyResultMessage;
  final List<AlternativeGameSuggestionModel> alternativeSuggestions;

  const NearbyCafesSearchResultModel({
    this.cafes = const [],
    this.emptyResultMessage,
    this.alternativeSuggestions = const [],
  });

  factory NearbyCafesSearchResultModel.fromJson(Map<String, dynamic> json) {
    // Backend trả `{ "data": { "cafes": { "data": [...], "meta": {...} } } }`
    // Cần đi vào đúng level: data → cafes → data
    final dataJson = json['data'] as Map<String, dynamic>?;
    final cafesJson = dataJson?['cafes'];

    List<CafeModel> cafes;
    if (cafesJson is Map<String, dynamic>) {
      // Paginated: `{ "data": [...], "meta": {...} }`
      final cafesData = cafesJson['data'];
      cafes = (cafesData is List)
          ? cafesData
              .cast<Map<String, dynamic>>()
              .map(CafeModel.fromNearbyJson)
              .toList()
          : const <CafeModel>[];
    } else if (cafesJson is List) {
      // Flat array: `cafes: [...]`
      cafes = cafesJson
          .cast<Map<String, dynamic>>()
          .map(CafeModel.fromNearbyJson)
          .toList();
    } else {
      cafes = const <CafeModel>[];
    }

    return NearbyCafesSearchResultModel(
      cafes: cafes,
      emptyResultMessage: dataJson?['emptyResultMessage'] as String?,
      alternativeSuggestions:
          (dataJson?['alternativeSuggestions'] as List?)
                  ?.cast<Map<String, dynamic>>()
                  .map(AlternativeGameSuggestionModel.fromJson)
                  .toList() ??
              const <AlternativeGameSuggestionModel>[],
    );
  }

  Map<String, dynamic> toJson() => {
        'cafes': cafes.map((c) => c.toJson()).toList(),
        'emptyResultMessage': emptyResultMessage,
        'alternativeSuggestions':
            alternativeSuggestions.map((a) => a.toJson()).toList(),
      };

  NearbyCafesSearchResultEntity toEntity() =>
      NearbyCafesSearchResultEntity(
        cafes: cafes.map((c) => c.toEntity()).toList(),
        emptyResultMessage: emptyResultMessage,
        alternativeSuggestions:
            alternativeSuggestions.map((a) => a.toEntity()).toList(),
      );
}
