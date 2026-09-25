// Unit tests cho WeightRange enum + SavedGamesCache.
//
// Verify:
// - WeightRange enum: apiValue, tryFromApiValue, fromWeightValue, displayLabel
// - SavedGamesCache: add/remove/toggle/replaceAll/clear

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boardverse/core/enums/weight_range.dart';
import 'package:boardverse/core/storage/saved_games_cache.dart';

void main() {
  group('WeightRange enum', () {
    test('apiValue maps 1-5 cho Light..Heavy', () {
      expect(WeightRange.light.apiValue, 1);
      expect(WeightRange.mediumLight.apiValue, 2);
      expect(WeightRange.medium.apiValue, 3);
      expect(WeightRange.mediumHeavy.apiValue, 4);
      expect(WeightRange.heavy.apiValue, 5);
    });

    test('tryFromApiValue returns enum for valid 1-5', () {
      expect(WeightRangeX.tryFromApiValue(1), WeightRange.light);
      expect(WeightRangeX.tryFromApiValue(3), WeightRange.medium);
      expect(WeightRangeX.tryFromApiValue(5), WeightRange.heavy);
    });

    test('tryFromApiValue returns null for invalid values', () {
      expect(WeightRangeX.tryFromApiValue(null), isNull);
      expect(WeightRangeX.tryFromApiValue(0), isNull);
      expect(WeightRangeX.tryFromApiValue(6), isNull);
      expect(WeightRangeX.tryFromApiValue(-1), isNull);
    });

    test('fromWeightValue buckets by BGG ranges', () {
      expect(WeightRangeX.fromWeightValue(1.0), WeightRange.light);
      expect(WeightRangeX.fromWeightValue(1.99), WeightRange.light);
      expect(WeightRangeX.fromWeightValue(2.0), WeightRange.mediumLight);
      expect(WeightRangeX.fromWeightValue(2.99), WeightRange.mediumLight);
      expect(WeightRangeX.fromWeightValue(3.0), WeightRange.medium);
      expect(WeightRangeX.fromWeightValue(3.49), WeightRange.medium);
      expect(WeightRangeX.fromWeightValue(3.5), WeightRange.mediumHeavy);
      expect(WeightRangeX.fromWeightValue(3.99), WeightRange.mediumHeavy);
      expect(WeightRangeX.fromWeightValue(4.0), WeightRange.heavy);
      expect(WeightRangeX.fromWeightValue(5.0), WeightRange.heavy);
    });

    test('fromWeightValue defaults to medium when null', () {
      expect(WeightRangeX.fromWeightValue(null), WeightRange.medium);
    });

    test('displayLabel contains Vietnamese text', () {
      expect(WeightRange.light.displayLabel, 'Nhẹ');
      expect(WeightRange.medium.displayLabel, 'Trung bình');
      expect(WeightRange.heavy.displayLabel, 'Nặng');
    });

    test('displayRange contains BGG ranges', () {
      expect(WeightRange.light.displayRange.contains('1'), true);
      expect(WeightRange.heavy.displayRange.contains('4'), true);
    });
  });

  group('SavedGamesCache', () {
    late SavedGamesCache cache;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      cache = SavedGamesCache(prefs);
    });

    test('starts empty', () {
      expect(cache.read(), isEmpty);
      expect(cache.count, 0);
    });

    test('add appends a game id', () async {
      await cache.add('game-1');
      expect(cache.read(), {'game-1'});
      expect(cache.count, 1);
      expect(cache.isSaved('game-1'), true);
    });

    test('remove removes a game id', () async {
      await cache.add('game-1');
      await cache.add('game-2');
      await cache.remove('game-1');
      expect(cache.read(), {'game-2'});
      expect(cache.isSaved('game-1'), false);
    });

    test('toggle flips saved state', () async {
      final result1 = await cache.toggle('game-1');
      expect(result1, true); // now saved
      expect(cache.isSaved('game-1'), true);

      final result2 = await cache.toggle('game-1');
      expect(result2, false); // now unsaved
      expect(cache.isSaved('game-1'), false);
    });

    test('replaceAll replaces the entire set', () async {
      await cache.add('game-1');
      await cache.replaceAll(['a', 'b', 'c']);
      expect(cache.read(), {'a', 'b', 'c'});
    });

    test('clear empties the cache', () async {
      await cache.add('game-1');
      await cache.add('game-2');
      await cache.clear();
      expect(cache.read(), isEmpty);
    });

    test('count returns 0 for empty cache', () {
      expect(cache.count, 0);
    });

    test('count returns correct size for multiple items', () async {
      await cache.add('game-1');
      await cache.add('game-2');
      await cache.add('game-3');
      expect(cache.count, 3);
    });
  });
}
