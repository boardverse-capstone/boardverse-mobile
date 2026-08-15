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
    // Lưu ý: `json` ở đây đã được `ApiResponse.fromJson` strip wrapper
    // (xem `getNearbyCafesSearch` / `getNearbyCafesForCurrentUser` /
    // `searchCafes` trong matchmaking_remote_datasource_impl.dart). Tức là
    // `json` chính là object `data` của envelope.
    //
    // Hai shape khả dĩ:
    //   • `/api/cafes/nearby` (và `/nearby/me`) trả:
    //       { "cafes": { "data": [...], "meta": {...} },
    //         "emptyResultMessage": "...", "alternativeSuggestions": [...] }
    //   • `/api/cafes/search` trả dạng paginated trực tiếp:
    //       { "data": [...], "meta": {...} }
    // Hai endpoint dùng chung model này — đoạn parse dưới đây chấp nhận cả
    // hai để không phải tạo thêm DTO riêng.

    List<CafeModel> cafes = const <CafeModel>[];

    // Case 1: `/nearby` → json['cafes'] = { "data": [...], "meta": {...} }
    final cafesJson = json['cafes'];
    if (cafesJson is Map<String, dynamic>) {
      final cafesData = cafesJson['data'];
      if (cafesData is List) {
        cafes = cafesData
            .cast<Map<String, dynamic>>()
            .map(CafeModel.fromNearbyJson)
            .toList();
      }
    }
    // Case 2: `/search` → json['data'] = [ ... ] (paginated trực tiếp)
    else if (cafesJson == null) {
      final searchData = json['data'];
      if (searchData is List) {
        cafes = searchData
            .cast<Map<String, dynamic>>()
            .map(CafeModel.fromNearbyJson)
            .toList();
      }
    }
    // Case 3: fallback — array phẳng trực tiếp dưới `cafes`.
    else if (cafesJson is List) {
      cafes = cafesJson
          .cast<Map<String, dynamic>>()
          .map(CafeModel.fromNearbyJson)
          .toList();
    }

    return NearbyCafesSearchResultModel(
      cafes: cafes,
      emptyResultMessage: json['emptyResultMessage'] as String?,
      alternativeSuggestions:
          (json['alternativeSuggestions'] as List?)
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
