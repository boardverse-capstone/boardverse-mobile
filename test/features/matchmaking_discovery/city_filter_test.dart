// Unit tests cho MatchmakingCubit `_filterCafesByCityToken` — verify
// filter "Trong thành phố" match đúng các biến thể address backend
// trả về (vd "Ho Chi Minh City" / "Hồ Chí Minh" / "TP.HCM" đều phải
// match cùng 1 nhóm quán ở TP.HCM).
//
// Lý do cần thiết: trước đây alias map chỉ lookup được khi `cityToken`
// khớp ĐÚNG canonical key (vd 'hồ chí minh'). Khi backend trả
// 'TP.HCM' / 'Ho Chi Minh City' / 'Thành phố Hồ Chí Minh' thì miss
// toàn bộ alias → player chỉ thấy 1 phần nhỏ quán trong city mode.

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/nearby_cafes_search_result_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/matchmaking_cubit.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/matchmaking_state.dart';

// Hand-written Fake — chỉ stub `getAllActiveCafes` (method mà
// `MatchmakingCubit.loadCafesByCity` gọi). Các method khác throw qua
// `noSuchMethod` để tránh phải implement 20+ abstract methods không
// dùng tới trong test này. Pattern tương tự `MockDiscoveryRepository`
// trong `survey_cubit_test.dart`.
class FakeMatchmakingRepository implements MatchmakingRepository {
  /// Quán sẽ trả về cho `getAllActiveCafes` — list full ACTIVE trên
  /// toàn quốc, sau đó cubit filter client-side theo city.
  final List<CafeEntity> activeCafes;

  FakeMatchmakingRepository({required this.activeCafes});

  @override
  Future<Either<Failure, NearbyCafesSearchResultEntity>>
      getAllActiveCafes({
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    return Right(NearbyCafesSearchResultEntity(cafes: activeCafes));
  }

  // Tất cả method khác không dùng trong test này — throw qua noSuchMethod
  // để nếu vô tình gọi nhầm sẽ fail ngay, không silently pass.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(
        'FakeMatchmakingRepository chưa stub: '
        '${invocation.memberName}',
      );
}

/// Helper tạo quán mock với address cho trước — `name` để sort A→Z ổn
/// định, các trường khác dùng default để compile.
CafeEntity cafe(String id, String name, String address) => CafeEntity(
      id: id,
      name: name,
      address: address,
      imageUrl: '',
      distanceMeters: 0,
      availableTables: 0,
      hasGameInStock: false,
      rating: 0,
      availableGameIds: const [],
      totalSeats: 0,
      availableSeats: 0,
      seatStatus: CafeSeatStatus.available,
    );

void main() {
  // ─── Fixture: data mẫu đúng như response `/api/cafes` user cung cấp ─
  // 5 quán "BoardVerse Demo Cafe" ở "Ho Chi Minh City" (English form)
  // 1 quán "Boss Cafe" ở "Hồ Chí Minh" (VN có dấu, có dấu phẩy)
  // 1 quán "BossCafe" ở "TP.HCM" (viết tắt)
  final sampleCafes = <CafeEntity>[
    cafe('1', 'BoardVerse Demo Cafe A', '123 Board Game Street, Ho Chi Minh City'),
    cafe('2', 'BoardVerse Demo Cafe B', '123 Board Game Street, Ho Chi Minh City'),
    cafe('3', 'BoardVerse Demo Cafe C', '123 Board Game Street, Ho Chi Minh City'),
    cafe('4', 'BoardVerse Demo Cafe D', '123 Board Game Street, Ho Chi Minh City'),
    cafe('5', 'BoardVerse Demo Cafe E', '123 Board Game Street, Ho Chi Minh City'),
    cafe('6', 'Boss Cafe', '1 Lý Thái Tổ, Tăng Nhơn Phú, Hồ Chí Minh'),
    cafe('7', 'BossCafe', '13 Nguyen Thai Hoc, Q1, TP.HCM'),
    // Quán ở tỉnh khác — phải KHÔNG match khi filter HCMC.
    cafe('8', 'Hanoi Hub', '10 Phố Huế, Hà Nội'),
  ];

  Future<MatchmakingState> runCityFilter(
    String city,
    String cityDisplayName,
  ) async {
    final cubit = MatchmakingCubit(
      repository: FakeMatchmakingRepository(activeCafes: sampleCafes),
    );
    await cubit.loadCafesByCity(
      city: city,
      cityDisplayName: cityDisplayName,
    );
    return cubit.state;
  }

  group('MatchmakingCubit.loadCafesByCity — city filter', () {
    test('canonical VN ("Hồ Chí Minh") match đủ 7 quán HCMC', () async {
      final state = await runCityFilter('Hồ Chí Minh', 'Hồ Chí Minh');
      expect(state, isA<MatchmakingCafesByCityLoaded>());
      final loaded = state as MatchmakingCafesByCityLoaded;
      expect(loaded.cafes.length, 7);
      expect(
        loaded.cafes.any((c) => c.id == '6'),
        isTrue,
        reason: 'Boss Cafe (Hồ Chí Minh) phải match',
      );
      expect(
        loaded.cafes.any((c) => c.id == '7'),
        isTrue,
        reason: 'BossCafe (TP.HCM) phải match',
      );
    });

    test('canonical lowercase ("hồ chí minh") vẫn match đủ 7 quán', () async {
      final state = await runCityFilter('hồ chí minh', 'Hồ Chí Minh');
      expect(state, isA<MatchmakingCafesByCityLoaded>());
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test(
        'English full ("Ho Chi Minh City") match đủ 7 quán — bug trước đây chỉ match 5',
        () async {
      final state = await runCityFilter(
          'Ho Chi Minh City', 'Ho Chi Minh City');
      final loaded = state as MatchmakingCafesByCityLoaded;
      expect(loaded.cafes.length, 7,
          reason: 'Boss Cafe + BossCafe phải match (trước đây miss)');
    });

    test('English short ("Ho Chi Minh") match đủ 7 quán', () async {
      final state = await runCityFilter('Ho Chi Minh', 'Ho Chi Minh');
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test('viết tắt ("TP.HCM") match đủ 7 quán — bug trước đây chỉ match 1',
        () async {
      final state = await runCityFilter('TP.HCM', 'TP.HCM');
      final loaded = state as MatchmakingCafesByCityLoaded;
      expect(
        loaded.cafes.length,
        7,
        reason:
            'Trước đây chỉ match 1 (BossCafe). Sau fix phải match full 7 quán HCMC',
      );
    });

    test('viết tắt có dấu cách ("TP HCM") match đủ 7 quán', () async {
      final state = await runCityFilter('TP HCM', 'TP HCM');
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test('VN có prefix ("Thành phố Hồ Chí Minh") match đủ 7 quán',
        () async {
      final state =
          await runCityFilter('Thành phố Hồ Chí Minh', 'Thành phố Hồ Chí Minh');
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test('tên cũ ("Sài Gòn") match đủ 7 quán', () async {
      final state = await runCityFilter('Sài Gòn', 'Sài Gòn');
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test('viết tắt EN ("HCMC") match đủ 7 quán', () async {
      final state = await runCityFilter('HCMC', 'HCMC');
      expect(
        (state as MatchmakingCafesByCityLoaded).cafes.length,
        7,
      );
    });

    test('canonical tỉnh khác ("Hà Nội") chỉ match quán ở Hà Nội',
        () async {
      final state = await runCityFilter('Hà Nội', 'Hà Nội');
      final loaded = state as MatchmakingCafesByCityLoaded;
      expect(loaded.cafes.length, 1);
      expect(loaded.cafes.first.id, '8');
    });

    test('thành phố lạ (không trong map alias) → fallback match chính xác cụm đó',
        () async {
      // "Hạ Long" không có trong alias map nhưng vẫn match nếu quán nào
      // có address chứa "Hạ Long". Đây là fallback — không nên miss.
      final cafesWithHaLong = <CafeEntity>[
        cafe('hl1', 'HaLong Hub', '123 Sun Square, Hạ Long'),
        cafe('hl2', 'Other Cafe', '456 Phố Huế, Hà Nội'),
      ];
      final cubit = MatchmakingCubit(
        repository: FakeMatchmakingRepository(activeCafes: cafesWithHaLong),
      );
      await cubit.loadCafesByCity(
        city: 'Hạ Long',
        cityDisplayName: 'Hạ Long',
      );
      final loaded = cubit.state as MatchmakingCafesByCityLoaded;
      expect(loaded.cafes.length, 1);
      expect(loaded.cafes.first.id, 'hl1');
    });

    test('sort theo name A→Z sau khi filter', () async {
      final state = await runCityFilter('Hồ Chí Minh', 'Hồ Chí Minh');
      final loaded = state as MatchmakingCafesByCityLoaded;
      final names = loaded.cafes.map((c) => c.name).toList();
      expect(names, [
        'BoardVerse Demo Cafe A',
        'BoardVerse Demo Cafe B',
        'BoardVerse Demo Cafe C',
        'BoardVerse Demo Cafe D',
        'BoardVerse Demo Cafe E',
        'Boss Cafe',
        'BossCafe',
      ]);
    });
  });
}