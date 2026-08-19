// Widget test cho LobbyCafeInfoCard — verify render states khác nhau của cafe
// detail (loading / loaded / error) và hiển thị đầy đủ thông tin cafe khi
// load thành công.

import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/repositories/matchmaking_repository.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/cubit/cafe_detail_cubit.dart';
import 'package:boardverse/features/lobby_management/presentation/widgets/lobby_cafe_info_card.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CafeDetailEntity _makeCafe({
  String id = 'cafe-1',
  String name = 'BoardVerse Demo Cafe',
  String address = '123 Trần Hưng Đạo, Hà Nội',
  String? imageUrl,
  String? description = 'Quán board game hiện đại',
  String? phoneNumber = '0901234567',
  double? latitude = 21.0285,
  double? longitude = 105.8542,
  double? distanceKm = 1.3,
  int numberOfTables = 8,
  int numberOfGamesOwned = 45,
  bool isCurrentlyOpen = true,
  bool hasGameMaster = true,
}) {
  return CafeDetailEntity(
    id: id,
    name: name,
    address: address,
    imageUrl: imageUrl,
    description: description,
    phoneNumber: phoneNumber,
    latitude: latitude,
    longitude: longitude,
    distanceKm: distanceKm,
    createdAt: DateTime.utc(2026, 1, 1),
    billingModel: BillingModel.timeBased,
    basePrice: 50000,
    totalSeats: 24,
    operationalStatus: CafeOperationalStatus.active,
    isCurrentlyOpen: isCurrentlyOpen,
    refundPolicy: RefundPolicy.partial,
    refundTiers: const [],
    depositPercentage: 0.2,
    depositRatePerPerson: 20,
    availableSeats: 12,
    heldSeats: 4,
    inUseSeats: 8,
    availableSeatsByTimeSlot: const {},
    scheduleOverrides: const [],
    numberOfTables: numberOfTables,
    numberOfPrivateRooms: 2,
    numberOfGamesOwned: numberOfGamesOwned,
    hasGameMaster: hasGameMaster,
  );
}

/// Fake repo để control loadCafeDetail state dễ dàng.
class _FakeRepo implements MatchmakingRepository {
  _FakeRepo(this._result);

  final CafeDetailEntity? _result;
  int loadCafeDetailCalls = 0;
  String? lastRequestedId;

  @override
  Future<Either<Failure, CafeDetailEntity?>> getCafeDetail(String id) async {
    loadCafeDetailCalls++;
    lastRequestedId = id;
    if (_result == null) {
      return const Left<Failure, CafeDetailEntity?>(
        ServerFailure(message: 'Cafe not found'),
      );
    }
    return Right<Failure, CafeDetailEntity?>(_result);
  }

  @override
  Future<Either<Failure, CafeDetailEntity?>> getCafeById(String id) =>
      getCafeDetail(id);

  // Unused methods for this test — throw to catch accidental use.
  @override
  noSuchMethod(Invocation invocation) {
    throw UnimplementedError(
      'FakeRepo does not implement ${invocation.memberName}',
    );
  }
}

Widget _wrap(CafeDetailCubit cubit, {String cafeId = 'cafe-1'}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: LobbyCafeInfoCard(cafeId: cafeId, cubit: cubit),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Render card với thông tin cafe ngay khi vừa load xong',
    (tester) async {
      final repo = _FakeRepo(_makeCafe());
      final cubit = CafeDetailCubit(repo);

      await tester.pumpWidget(_wrap(cubit));
      // Đợi cubit emit Loaded → render body (không phải skeleton).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Body đã render — không còn CircularProgressIndicator.
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Tên cafe hiển thị.
      expect(find.text('BoardVerse Demo Cafe'), findsOneWidget);

      await cubit.close();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'Render card với thông tin cafe khi Loaded',
    (tester) async {
      final repo = _FakeRepo(_makeCafe());
      final cubit = CafeDetailCubit(repo);

      await tester.pumpWidget(_wrap(cubit));
      // Đợi cubit load xong và emit Loaded state.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tên cafe phải hiển thị.
      expect(find.text('BoardVerse Demo Cafe'), findsOneWidget);
      // Địa chỉ hiển thị.
      expect(find.text('123 Trần Hưng Đạo, Hà Nội'), findsOneWidget);
      // Số điện thoại hiển thị.
      expect(find.text('0901234567'), findsOneWidget);
      // Khoảng cách hiển thị.
      expect(find.text('1.3 km'), findsOneWidget);
      // Trạng thái ĐANG MỞ hiển thị.
      expect(find.text('ĐANG MỞ'), findsOneWidget);
      // Stats: số bàn, số game, GM.
      expect(find.text('8 bàn'), findsOneWidget);
      expect(find.text('45 game'), findsOneWidget);
      expect(find.text('Có GM'), findsOneWidget);
      // Repo phải được gọi đúng 1 lần với đúng cafeId.
      expect(repo.loadCafeDetailCalls, 1);
      expect(repo.lastRequestedId, 'cafe-1');

      await cubit.close();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'Ẩn card gracefully khi fetch fail (Error state)',
    (tester) async {
      final repo = _FakeRepo(null); // returns Left failure
      final cubit = CafeDetailCubit(repo);

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Card không render tên cafe (graceful degrade).
      expect(find.text('BoardVerse Demo Cafe'), findsNothing);
      // Không crash UI.
      expect(find.byType(LobbyCafeInfoCard), findsOneWidget);

      await cubit.close();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'Không hiển thị stats khi cafe không có bàn/game',
    (tester) async {
      final repo = _FakeRepo(_makeCafe(
        numberOfTables: 0,
        numberOfGamesOwned: 0,
        hasGameMaster: false,
      ));
      final cubit = CafeDetailCubit(repo);

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Tên cafe vẫn hiển thị.
      expect(find.text('BoardVerse Demo Cafe'), findsOneWidget);
      // Stats không hiển thị.
      expect(find.text('0 bàn'), findsNothing);
      expect(find.text('0 game'), findsNothing);
      expect(find.text('Có GM'), findsNothing);

      await cubit.close();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );

  testWidgets(
    'Hiển thị badge ĐÃ ĐÓNG khi cafe isCurrentlyOpen=false',
    (tester) async {
      final repo = _FakeRepo(_makeCafe(isCurrentlyOpen: false));
      final cubit = CafeDetailCubit(repo);

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('ĐÃ ĐÓNG'), findsOneWidget);
      expect(find.text('ĐANG MỞ'), findsNothing);

      await cubit.close();
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}