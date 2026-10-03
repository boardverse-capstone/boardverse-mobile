// Edge-case tests cho [SavedGamesResponseModel.fromJson] — bổ sung
// cho `saved_games_response_model_test.dart`. Các test ở file này
// cover những format JSON mà production BE có thể trả về nhưng
// chưa được handle trong main test file.
//
// **Bối cảnh bug 2026-10-03**:
// Trên Flutter Web, khi BE trả về List chứa element không phải Map
// (vd: `[[game1], [game2]]` thay vì `[game1, game2]`), cast
// `e as Map<String, dynamic>` trong `_fromList` throw
// `TypeError: ... 'List<dynamic>' is not a subtype of 'Map<String, dynamic>'`.
// Test này cover các edge case đó để đảm bảo model xử lý gracefully.

import 'package:boardverse/features/discovery/data/models/saved_games_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SavedGamesResponseModel.fromJson - edge cases', () {
    test(
      'BE returns List chứa 1 element là List (wrapped list) - vẫn parse được',
      () {
        // Một số backend versions trả về data bị wrap trong 1 list ngoài
        // (vd: data field trỏ tới 1 list duy nhất chứa tất cả games).
        // Model phải unwrap và parse bên trong.
        final json = [
          [
            {
              'id': 'save-1',
              'gameTemplateId': 'game-1',
              'gameName': 'Catan',
              'categories': <String>[],
              'savedAt': '2026-10-03T09:50:16.683327Z',
            },
            {
              'id': 'save-2',
              'gameTemplateId': 'game-2',
              'gameName': 'Pandemic',
              'categories': <String>[],
              'savedAt': '2026-10-03T09:50:11.497104Z',
            },
          ],
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        expect(model.savedGames, hasLength(2));
        expect(model.savedGames[0].gameName, 'Catan');
        expect(model.savedGames[1].gameName, 'Pandemic');
        expect(model.totalCount, 2);
      },
    );

    test(
      'BE trả List chứa mix Map + List + null → chỉ parse được Map, skip phần còn lại',
      () {
        // BE có bug hoặc schema chưa stable, trả về data không đồng nhất.
        // Model phải robust: skip non-Map elements, không throw.
        final json = [
          {
            'id': 'save-1',
            'gameTemplateId': 'game-1',
            'gameName': 'Catan',
            'categories': <String>[],
            'savedAt': '2026-10-03T09:50:16.683327Z',
          },
          ['some', 'list'], // <-- BUG: list lẫn vào data
          null, // <-- BUG: null trong list
          {
            'id': 'save-2',
            'gameTemplateId': 'game-2',
            'gameName': 'Pandemic',
            'categories': <String>[],
            'savedAt': '2026-10-03T09:50:11.497104Z',
          },
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        // Chỉ 2 Map elements được parse, 2 elements invalid bị skip.
        expect(model.savedGames, hasLength(2));
        expect(model.savedGames[0].gameName, 'Catan');
        expect(model.savedGames[1].gameName, 'Pandemic');
      },
    );

    test(
      'BE trả List rỗng rỗng rỗng (3 lần lồng) → trả savedGames = []',
      () {
        // Empty edge case với lồng nhiều tầng.
        final json = [
          [],
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        expect(model.savedGames, isEmpty);
        expect(model.totalCount, 0);
      },
    );

    test(
      'BE trả List với toàn non-Map elements → trả savedGames = [] (không throw)',
      () {
        // Regression test cho bug chính: trước đây model throw
        // TypeError khi gặp non-Map element. Sau fix: skip hết, trả [].
        final json = [
          'string1',
          'string2',
          [1, 2, 3],
          {'some': 'object'}, // Map nhưng thiếu field id
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        // Map thiếu field id sẽ throw ở `SavedBoardGameModel.fromJson`.
        // Bỏ qua case này - test chỉ verify không cast List thành Map.
        // Tất cả elements đều không phải Map hợp lệ.
        // (Element {'some': 'object'} sẽ fail vì thiếu 'id' nên nó
        // cũng sẽ bị skip với try-catch mới.)
        expect(model.savedGames, anyOf(isEmpty, hasLength(0)));
      },
    );

    test(
      'Map thiếu field `id` → skip element (không throw toàn bộ parse)',
      () {
        // Nếu 1 element trong list bị malformed (thiếu field required),
        // các elements khác vẫn phải được parse bình thường.
        final json = [
          {
            'id': 'save-1',
            'gameTemplateId': 'game-1',
            'gameName': 'Catan',
            'categories': <String>[],
            'savedAt': '2026-10-03T09:50:16.683327Z',
          },
          {
            // Thiếu 'id' → should be skipped
            'gameTemplateId': 'game-broken',
            'gameName': 'Broken Game',
            'categories': <String>[],
            'savedAt': '2026-10-03T09:50:00.000000Z',
          },
          {
            'id': 'save-2',
            'gameTemplateId': 'game-2',
            'gameName': 'Pandemic',
            'categories': <String>[],
            'savedAt': '2026-10-03T09:50:11.497104Z',
          },
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        // Element giữa bị skip, 2 elements hợp lệ còn lại được parse.
        expect(model.savedGames, hasLength(2));
        expect(model.savedGames[0].gameName, 'Catan');
        expect(model.savedGames[1].gameName, 'Pandemic');
      },
    );

    test(
      'Format BE mới: List các Map (bình thường) - regression test vẫn pass',
      () {
        // Đảm bảo fix không phá vỡ case cũ đã pass.
        final json = [
          {
            'id': 'save-1',
            'gameTemplateId': 'game-1',
            'gameName': 'Catan',
            'categories': ['Strategy'],
            'weight': 2.33,
            'playTimeMinutes': 60,
            'savedAt': '2026-10-03T09:50:16.683327Z',
          },
        ];

        final model = SavedGamesResponseModel.fromJson(json);

        expect(model.savedGames, hasLength(1));
        expect(model.savedGames[0].gameName, 'Catan');
        expect(model.savedGames[0].playTime, 60);
      },
    );
  });
}
