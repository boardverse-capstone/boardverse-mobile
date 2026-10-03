// Unit tests cho [ActiveCafesPaginatedResultModel.fromJson].
//
// **Bối cảnh bug (2026-10-03)**: Backend đổi response shape từ
// `{ data: [...], meta: {...} }` (flat) sang nested
// `{ isSaved, cafes: { data: [...], meta: {...} } }`. Parser cũ chỉ
// check `json['data']` ở top-level → trả empty list → UI hiển thị
// "chưa có quán nào có sẵn board game này" dù backend trả 3 quán.
//
// Test này cover:
// 1. Nested `cafes` wrapper (build mới) — bug chính.
// 2. `isSaved` top-level (build mới) — cho bookmark icon trên header.
// 3. Flat `data`/`meta` (backward compat với backend cũ).
// 4. Flat `items` (backward compat với envelope cũ).
// 5. Trực tiếp array (single-page edge case).

import 'package:boardverse/features/matchmaking_discovery/data/models/active_cafes_paginated_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ActiveCafesPaginatedResultModel.fromJson', () {
    test('build 2026-10-03+: nested "cafes" wrapper + top-level isSaved', () {
      // Arrange — response thực tế từ BE build mới.
      final json = {
        'isSaved': true,
        'cafes': {
          'data': [
            {
              'inventoryId': 'inv-1',
              'cafeId': 'cafe-a',
              'cafeName': 'Boardvearse cafe',
              'cafeAddress': '12345 Nguyen Thai Hoc, Q1, TP.HCM',
              'availableGameCount': 16,
              'totalGameBoxCount': 16,
              'availableTableCount': 8,
              'totalTableCount': 10,
              'isAvailableNow': true,
              'status': 'Available',
              'operatingStatus': 'Active',
            },
            {
              'inventoryId': 'inv-2',
              'cafeId': 'cafe-b',
              'cafeName': 'Boss Cafe',
              'cafeAddress': '1 Ly Thai To, TP.HCM',
              'availableGameCount': 0,
              'totalGameBoxCount': 0,
              'availableTableCount': 10,
              'totalTableCount': 10,
              'isAvailableNow': false,
              'status': 'InUse',
              'operatingStatus': 'Active',
            },
          ],
          'meta': {
            'currentPage': 1,
            'pageSize': 20,
            'totalItems': 2,
            'totalPages': 1,
            'hasPrevious': false,
            'hasNext': false,
          },
        },
      };

      // Act
      final result = ActiveCafesPaginatedResultModel.fromJson(json);

      // Assert — phải parse được 2 quán, không phải empty.
      expect(result.cafes, hasLength(2),
          reason: 'Bug chính: parser cũ trả empty list khi response dùng '
              'nested "cafes" wrapper.');
      expect(result.cafes[0].cafeId, 'cafe-a');
      expect(result.cafes[0].cafeName, 'Boardvearse cafe');
      expect(result.cafes[1].cafeId, 'cafe-b');
      expect(result.cafes[1].isAvailableNow, isFalse);

      // Pagination meta cũng phải parse đúng từ `meta` bên trong `cafes`.
      expect(result.page, 1);
      expect(result.pageSize, 20);
      expect(result.totalCount, 2);
      expect(result.totalPages, 1);
      expect(result.hasNextPage, isFalse);
      expect(result.hasPreviousPage, isFalse);

      // isSaved top-level phải propagate xuống.
      expect(result.isSaved, isTrue);
    });

    test('build 2026-10-03+: isSaved = false khi user chưa lưu', () {
      final json = {
        'isSaved': false,
        'cafes': {
          'data': <Map<String, dynamic>>[],
          'meta': {
            'currentPage': 1,
            'pageSize': 20,
            'totalItems': 0,
            'totalPages': 0,
            'hasPrevious': false,
            'hasNext': false,
          },
        },
      };

      final result = ActiveCafesPaginatedResultModel.fromJson(json);

      expect(result.cafes, isEmpty);
      expect(result.isSaved, isFalse);
      expect(result.totalCount, 0);
    });

    test('backward compat: flat "data"/"meta" (build cũ)', () {
      final json = {
        'data': [
          {
            'cafeId': 'cafe-x',
            'cafeName': 'X Cafe',
            'cafeAddress': 'addr',
          },
        ],
        'meta': {
          'currentPage': 1,
          'pageSize': 20,
          'totalItems': 1,
          'totalPages': 1,
        },
        // Không có `isSaved` (backend cũ) → default false.
      };

      final result = ActiveCafesPaginatedResultModel.fromJson(json);

      expect(result.cafes, hasLength(1));
      expect(result.cafes[0].cafeId, 'cafe-x');
      expect(result.isSaved, isFalse,
          reason: 'Default false khi BE cũ không trả isSaved.');
    });

    test('backward compat: flat "items" envelope', () {
      final json = {
        'items': [
          {
            'cafeId': 'cafe-y',
            'cafeName': 'Y Cafe',
            'cafeAddress': 'addr',
          },
        ],
        'page': 1,
        'pageSize': 20,
        'totalItems': 1,
        'totalPages': 1,
      };

      final result = ActiveCafesPaginatedResultModel.fromJson(json);

      expect(result.cafes, hasLength(1));
      expect(result.cafes[0].cafeId, 'cafe-y');
    });

    test('toEntity propagates isSaved', () {
      final json = {
        'isSaved': true,
        'cafes': {
          'data': [
            {
              'cafeId': 'cafe-z',
              'cafeName': 'Z',
              'cafeAddress': 'a',
            },
          ],
          'meta': {
            'currentPage': 1,
            'pageSize': 20,
            'totalItems': 1,
            'totalPages': 1,
            'hasPrevious': false,
            'hasNext': false,
          },
        },
      };

      final entity =
          ActiveCafesPaginatedResultModel.fromJson(json).toEntity();

      expect(entity.cafes, hasLength(1));
      expect(entity.isSaved, isTrue);
      // emptyResultMessage chỉ được set khi cafes rỗng.
      expect(entity.emptyResultMessage, isNull);
    });
  });
}
