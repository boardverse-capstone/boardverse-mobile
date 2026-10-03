// Unit tests cho [BoardGameDetailModel.fromJson] với field `isSaved`
// (build 2026-10-03+).
//
// **Bối cảnh**: Backend bắt đầu trả `isSaved` top-level trong response
// `GET /api/v1/board-games/{id}` để UI trang chi tiết hiển thị icon
// save/unsave. Trước đó chỉ endpoint `.../active-cafes` có field này.
// Detail là source of truth ưu tiên (không cache, luôn fresh).

import 'package:boardverse/features/matchmaking_discovery/data/models/board_game_detail_model.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/board_game_detail_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardGameDetailModel.fromJson — isSaved', () {
    test('build 2026-10-03+: isSaved = true (user đã lưu)', () {
      // Arrange — response thực tế từ BE build mới.
      final json = {
        'id': '33333333-3333-3333-3333-333333333333',
        'name': 'Uno',
        'thumbnailUrl': 'https://example.com/uno.jpg',
        'description': 'A fast-paced card game',
        'minPlayers': 2,
        'maxPlayers': 10,
        'playTime': 30,
        'createdAt': '2024-01-01T00:00:00Z',
        'updatedAt': '2026-09-29T04:05:31.268636Z',
        'categories': [
          {
            'id': 'c1111111-1111-1111-1111-111111111113',
            'name': 'Giải trí',
            'slug': 'giai-tri',
            'description': 'Nhẹ nhàng, vui vẻ',
            'sortOrder': 3,
          },
        ],
        'components': <Map<String, dynamic>>[],
        'isSaved': true,
      };

      // Act
      final model = BoardGameDetailModel.fromJson(json);

      // Assert
      expect(model.isSaved, isTrue);
      expect(model.id, '33333333-3333-3333-3333-333333333333');
      expect(model.name, 'Uno');
      expect(model.minPlayers, 2);
      expect(model.maxPlayers, 10);

      // Entity cũng phải carry isSaved qua.
      final entity = model.toEntity();
      expect(entity.isSaved, isTrue);
    });

    test('build 2026-10-03+: isSaved = false (user chưa lưu)', () {
      final json = {
        'id': '33333333-3333-3333-3333-333333333333',
        'name': 'Uno',
        'thumbnailUrl': '',
        'description': '',
        'minPlayers': 2,
        'maxPlayers': 10,
        'playTime': 30,
        'isSaved': false,
      };

      final model = BoardGameDetailModel.fromJson(json);

      expect(model.isSaved, isFalse);
      final entity = model.toEntity();
      expect(entity.isSaved, isFalse);
    });

    test('backward compat: BE cũ không trả isSaved → default false', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Cờ tỷ phú',
        'thumbnailUrl': '',
        'description': '',
        'minPlayers': 2,
        'maxPlayers': 4,
        'playTime': 60,
        // Không có `isSaved` (backend cũ) → default false.
      };

      final model = BoardGameDetailModel.fromJson(json);

      expect(model.isSaved, isFalse,
          reason: 'Default false khi BE cũ không trả isSaved.');
      final entity = model.toEntity();
      expect(entity.isSaved, isFalse);
    });

    test('entity default constructor: isSaved = false', () {
      const entity = BoardGameDetailEntity(
        id: 'x',
        name: 'x',
        description: '',
        thumbnailUrl: '',
        minPlayers: 1,
        maxPlayers: 1,
        playTime: 0,
      );

      expect(entity.isSaved, isFalse);
    });

    test('toJson round-trip preserves isSaved', () {
      const model = BoardGameDetailModel(
        id: 'x',
        name: 'x',
        description: '',
        thumbnailUrl: '',
        minPlayers: 1,
        maxPlayers: 1,
        playTime: 0,
        isSaved: true,
      );

      final json = model.toJson();
      expect(json['isSaved'], isTrue);

      final reparsed = BoardGameDetailModel.fromJson(json);
      expect(reparsed.isSaved, isTrue);
    });
  });
}
