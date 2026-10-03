import 'package:equatable/equatable.dart';

/// Model cho một game trong danh sách "Đã lưu".
///
/// **JSON field aliases** (BE trả về cả 2 tên tùy version):
/// - `playTime` ↔ `playTimeMinutes` — model ưu tiên `playTimeMinutes` (BE mới).
class SavedBoardGameModel extends Equatable {
  final String id;
  final String gameTemplateId;
  final String gameName;
  final String? thumbnailUrl;
  final List<String> categories;
  final double? weight;
  final int? playTime;
  final DateTime savedAt;

  const SavedBoardGameModel({
    required this.id,
    required this.gameTemplateId,
    required this.gameName,
    this.thumbnailUrl,
    required this.categories,
    this.weight,
    this.playTime,
    required this.savedAt,
  });

  factory SavedBoardGameModel.fromJson(Map<String, dynamic> json) {
    return SavedBoardGameModel(
      id: json['id'] as String,
      gameTemplateId: json['gameTemplateId'] as String,
      gameName: json['gameName'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['name'] as String? ?? '')
              .toList() ??
          [],
      weight: (json['weight'] ?? json['bggWeight']) != null
          ? (json['weight'] ?? json['bggWeight'] as num).toDouble()
          : null,
      // BE mới đổi tên `playTime` → `playTimeMinutes`. Vẫn ưu tiên key
      // mới, fallback về key cũ để tương thích ngược.
      playTime: (json['playTimeMinutes'] ?? json['playTime']) is num
          ? (json['playTimeMinutes'] ?? json['playTime'] as num).toInt()
          : null,
      savedAt: DateTime.parse(json['savedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id, gameTemplateId, gameName, thumbnailUrl,
        categories, weight, playTime, savedAt,
      ];
}

/// Wrapper response cho GET /saved.
///
/// **Hỗ trợ 4 format BE (tương thích ngược + tương thích buggy data):**
///
/// 1. **BE mới (2026-10):** `data` là List trực tiếp.
///    ```json
///    { "statusCode": 200, "message": "...", "data": [ {...}, {...} ] }
///    ```
///    Sau khi `DualFormatResponse.parse` unwrap → `data` là `List<dynamic>`
///    được truyền thẳng vào factory này.
///
/// 2. **BE cũ v1:** `data` là Map có field `savedGames`.
///    ```json
///    { "statusCode": 200, "data": { "savedGames": [...], "totalCount": 5 } }
///    ```
///
/// 3. **BE cũ v0:** `data` là Map có field `games`.
///    ```json
///    { "success": true, "data": { "games": [...], "totalCount": 5 } }
///    ```
///
/// 4. **BE buggy / data wrapper bất thường:**
///    - List bị wrap thêm 1 lớp: `data = [ [game1, game2] ]`
///      → tự động unwrap layer ngoài.
///    - Element trong list không phải Map (String, Number, null, nested List)
///      → skip element đó, KHÔNG throw toàn bộ parse.
///    - Map thiếu field `id` (required) → skip element đó.
class SavedGamesResponseModel extends Equatable {
  final List<SavedBoardGameModel> savedGames;
  final int totalCount;

  const SavedGamesResponseModel({
    required this.savedGames,
    required this.totalCount,
  });

  /// Build từ `dynamic` (response đã được Dio parse) — chấp nhận
  /// cả 4 format BE ở trên.
  ///
  /// **Robustness**: KHÔNG throw khi gặp element lỗi (List, String,
  /// null, Map thiếu field required). Thay vào đó skip element đó và
  /// log warning. Lý do: bug ngày 2026-10-03 trên Flutter Web —
  /// khi BE trả data dạng `[[game1, game2]]` thay vì `[game1, game2]`,
  /// cast `e as Map<String, dynamic>` throw
  /// `TypeError: ... 'List<dynamic>' is not a subtype of 'Map<String, dynamic>'`
  /// → cubit bị crash → UI render đỏ.
  factory SavedGamesResponseModel.fromJson(dynamic raw) {
    // Format 1 (BE mới): BE unwrap data xong, factory nhận List trực tiếp.
    if (raw is List) {
      return SavedGamesResponseModel._fromList(raw);
    }

    // Format 2 & 3: nhận Map (đã có hoặc chưa có field 'data' bên ngoài).
    final Map<String, dynamic> map;
    if (raw is Map<String, dynamic>) {
      map = raw;
    } else if (raw is Map) {
      map = Map<String, dynamic>.from(raw);
    } else {
      throw FormatException(
        'SavedGamesResponseModel.fromJson: expected List or Map, got '
        '${raw.runtimeType}',
      );
    }

    final data = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;
    final gamesList = (data['savedGames'] as List<dynamic>?) ??
        (data['games'] as List<dynamic>?) ??
        const <dynamic>[];

    return SavedGamesResponseModel._fromList(
      gamesList,
      totalCount: data['totalCount'] as int?,
    );
  }

  /// Parse từ list elements — defensive, skip non-Map / malformed entries.
  factory SavedGamesResponseModel._fromList(
    List<dynamic> rawList, {
    int? totalCount,
  }) {
    // 1. Normalize: thử unwrap 1 layer nếu toàn bộ rawList chỉ chứa
    //    1 List bên trong (case BE trả `[[game1, game2]]` thay vì
    //    `[game1, game2]` — đã xảy ra trong bug 2026-10-03 trên Web).
    final List<dynamic> gamesList = _unwrapIfSingleNestedList(rawList);

    // 2. Parse từng element, bỏ qua element không phải Map hợp lệ.
    final parsed = <SavedBoardGameModel>[];
    for (var i = 0; i < gamesList.length; i++) {
      final e = gamesList[i];
      // Skip null, List, String, Number — chỉ chấp nhận Map.
      if (e is! Map) {
        // ignore: avoid_print
        print(
          '[SavedGamesResponseModel] Skipped non-Map element at index $i '
          '(type: ${e.runtimeType}).',
        );
        continue;
      }
      try {
        // Map có thể là Map<dynamic, dynamic> (parsed từ JSON thuần).
        // Chuẩn hoá thành Map<String, dynamic> để SavedBoardGameModel
        // .fromJson có thể đọc an toàn.
        final normalized = <String, dynamic>{};
        e.forEach((k, v) {
          normalized[k.toString()] = v;
        });
        parsed.add(SavedBoardGameModel.fromJson(normalized));
      } catch (err) {
        // Element Map bị malformed (vd: thiếu field 'id') → skip,
        // KHÔNG throw. Vẫn parse các element còn lại.
        // ignore: avoid_print
        print(
          '[SavedGamesResponseModel] Skipped malformed game at index $i: $err',
        );
      }
    }

    return SavedGamesResponseModel(
      savedGames: parsed,
      totalCount: totalCount ?? parsed.length,
    );
  }

  /// Nếu [raw] là List có đúng 1 phần tử và phần tử đó cũng là List,
  /// trả về List bên trong (unwrap). Ngược lại trả về chính [raw].
  ///
  /// Lý do: Một số BE version trả về `data: [ [game1, game2] ]` thay
  /// vì `data: [game1, game2]` (có thể do bug ở BE hoặc schema chưa
  /// stable). Thay vì throw, ta thử unwrap 1 layer trước khi cast
  /// từng element.
  static List<dynamic> _unwrapIfSingleNestedList(List<dynamic> raw) {
    if (raw.length == 1 && raw.first is List) {
      return raw.first as List<dynamic>;
    }
    return raw;
  }

  @override
  List<Object?> get props => [savedGames, totalCount];
}
