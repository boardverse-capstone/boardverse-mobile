import 'package:boardverse/features/discovery/data/models/saved_games_response_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// **Regression test cho bug ngày 2026-10-03:**
/// BE đổi format `/api/v1/discovery/saved` từ
/// `{ data: { savedGames: [...] } }` → `{ data: [...] }` (List trực tiếp).
/// Model cũ cast `data as Map<String, dynamic>` → `TypeError: ...type 'JSArray<dynamic>' is not a subtype of type 'Map<String, dynamic>'`.
void main() {
  group('SavedGamesResponseModel.fromJson', () {
    test('BE mới: data là List trực tiếp (format 2026-10)', () {
      // Đây chính xác là payload mà BE trả về trong terminal.
      final json = [
        {
          'id': 'aad9d699-2744-4749-b1d0-cfaca112636d',
          'gameTemplateId': '11111111-1111-1111-1111-111111111111',
          'gameName': 'Catan',
          'thumbnailUrl':
              'https://cf.geekdo-images.com/0XODRpReiZBFUffEcqT5-Q__itemrep/img/6Jf5G-bSvdOIMUSwxsJfZXl29B8=/fit-in/246x300/filters:strip_icc()/pic9156909.png',
          'description': 'A strategy board game...',
          'minPlayers': 3,
          'maxPlayers': 4,
          'playTimeMinutes': 60,
          'weight': 2.33,
          'categories': ['Chiến thuật', 'Đối kháng'],
          'savedAt': '2026-10-03T09:50:16.683327Z',
          'hasOpenLobby': false,
        },
        {
          'id': '1627eb8b-326e-423f-bfcb-efed1c1371f9',
          'gameTemplateId': '88888888-8888-8888-8888-888888888888',
          'gameName': 'Pandemic',
          'thumbnailUrl':
              'https://cf.geekdo-images.com/S3ybV1LAp-8SnHIXLLjVqA__micro@2x/img/efLAsciFR_HN8lhYp-EBfEgjjDU=/fit-in/128x128/filters:strip_icc()/pic1534148.jpg',
          'description': 'Người chơi hợp tác...',
          'minPlayers': 2,
          'maxPlayers': 4,
          'playTimeMinutes': 45,
          'weight': 2.56,
          'categories': ['Chiến thuật', 'Hợp tác'],
          'savedAt': '2026-10-03T09:50:11.497104Z',
          'hasOpenLobby': false,
        },
      ];

      final model = SavedGamesResponseModel.fromJson(json);

      expect(model.savedGames, hasLength(2));
      expect(model.savedGames[0].gameName, 'Catan');
      expect(model.savedGames[0].gameTemplateId,
          '11111111-1111-1111-1111-111111111111');
      expect(model.savedGames[0].playTime, 60); // playTimeMinutes alias
      expect(model.savedGames[0].weight, 2.33);
      expect(model.savedGames[0].categories, ['Chiến thuật', 'Đối kháng']);
      expect(model.savedGames[1].gameName, 'Pandemic');
      expect(model.savedGames[1].playTime, 45);
      expect(model.totalCount, 2);
    });

    test('BE cũ: data là Map có field savedGames (tương thích ngược)', () {
      final json = {
        'data': {
          'savedGames': [
            {
              'id': 'id-1',
              'gameTemplateId': 'gt-1',
              'gameName': 'Catan',
              'categories': ['Strategy'],
              'savedAt': '2026-10-03T09:50:16.683327Z',
            }
          ],
          'totalCount': 1,
        }
      };

      final model = SavedGamesResponseModel.fromJson(json);

      expect(model.savedGames, hasLength(1));
      expect(model.savedGames[0].gameName, 'Catan');
      expect(model.totalCount, 1);
    });

    test('BE cũ v0: data là Map có field games', () {
      final json = {
        'data': {
          'games': [
            {
              'id': 'id-1',
              'gameTemplateId': 'gt-1',
              'gameName': 'Catan',
              'categories': <String>[],
              'savedAt': '2026-10-03T09:50:16.683327Z',
            }
          ],
        }
      };

      final model = SavedGamesResponseModel.fromJson(json);

      expect(model.savedGames, hasLength(1));
      expect(model.totalCount, 1); // fallback về gamesList.length
    });

    test('playTimeMinutes alias: BE trả về cả 2 key, ưu tiên key mới', () {
      final json = [
        {
          'id': 'id-1',
          'gameTemplateId': 'gt-1',
          'gameName': 'Catan',
          'categories': <String>[],
          'playTime': 30, // key cũ
          'savedAt': '2026-10-03T09:50:16.683327Z',
        }
      ];

      final model = SavedGamesResponseModel.fromJson(json);
      expect(model.savedGames[0].playTime, 30);
    });

    test('categories chứa cả String và Map (BE cũ/mới đều OK)', () {
      final json = [
        {
          'id': 'id-1',
          'gameTemplateId': 'gt-1',
          'gameName': 'Catan',
          'categories': [
            'Chiến thuật',
            {'name': 'Hợp tác'},
          ],
          'savedAt': '2026-10-03T09:50:16.683327Z',
        }
      ];

      final model = SavedGamesResponseModel.fromJson(json);
      expect(model.savedGames[0].categories, ['Chiến thuật', 'Hợp tác']);
    });

    test('Danh sách rỗng → savedGames = [], totalCount = 0', () {
      final model = SavedGamesResponseModel.fromJson(<dynamic>[]);
      expect(model.savedGames, isEmpty);
      expect(model.totalCount, 0);
    });

    test('Type lạ (không phải List/Map) → throw FormatException', () {
      expect(
        () => SavedGamesResponseModel.fromJson('not-a-valid-response'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
