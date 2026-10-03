// Widget tests cho [CafeCard] — focus vào logic hiển thị seats/gia
// theo yêu cầu user (build 2026-10-03):
//
// 1. Quán seat-based (totalSeats > 0):
//    - available = 0 → "Hết chỗ" (status chip red) + ghế stat box red.
//    - available > 0 → "Còn chỗ" (green) + ghế stat box green.
//    - limited (≤ 20%) → "Sắp hết" (amber) + ghế stat box amber.
//
// 2. Quán table-based (totalSeats = 0):
//    - KHONG fallback sang tables nua (build 2026-10-03 — fix bug).
//    - Stat box "Ghế" hien thi "—" voi mau grey.
//    - User phan bi truoc day fallback "Ghế 10/10" gay hieu nham quán
//      có 10 ghế trống trong khi thực tế quán chỉ track tables.
//
// 3. Stat box "Bàn trống" da bi XOA (build 2026-10-03).
//    Thay bằng stat box "Giá" hien thi basePrice (vi du "60k/giờ").
//
// 4. Card layout: có name, address, 3 stat boxes (ghế/giá/box), distance
//    pill, status chip. Không hiển thị ảnh (backend chưa trả imageUrl).

import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/widgets/cafe_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CafeEntity _makeCafe({
  String id = 'cafe-1',
  String name = 'Boardvearse cafe',
  String address = '12345 Nguyen Thai Hoc, Q1, TP.HCM',
  int totalSeats = 40,
  int availableSeats = 8,
  int totalTableCount = 10,
  int availableTableCount = 8,
  int totalGameBoxCount = 20,
  int availableGameCount = 20,
  CafeSeatStatus seatStatus = CafeSeatStatus.available,
  double distanceMeters = 2887.0,
  // Pricing (build 2026-10-03)
  double basePrice = 60000,
  BillingModel billingModel = BillingModel.timeBased,
}) {
  return CafeEntity(
    id: id,
    name: name,
    address: address,
    imageUrl: '',
    distanceMeters: distanceMeters,
    availableTables: availableTableCount,
    hasGameInStock: availableGameCount > 0,
    estimatedWaitMinutes: null,
    rating: 4.5,
    availableGameIds: const [],
    totalSeats: totalSeats,
    availableSeats: availableSeats,
    seatStatus: seatStatus,
    phoneNumber: '0854315553',
    availableTableCount: availableTableCount,
    totalTableCount: totalTableCount,
    totalGameBoxCount: totalGameBoxCount,
    availableGameCount: availableGameCount,
    // Pricing
    basePrice: basePrice,
    billingModel: billingModel,
  );
}

Future<void> _pumpCard(WidgetTester tester, CafeEntity cafe) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CafeCard(cafe: cafe),
        ),
      ),
    ),
  );
}

void main() {
  group('CafeCard — seat display logic (build 2026-10-03)', () {
    testWidgets('seat-based: available > 0 → green "Còn chỗ" + ghế stat box green',
        (tester) async {
      final cafe = _makeCafe(
        totalSeats: 40,
        availableSeats: 30,
        seatStatus: CafeSeatStatus.available,
      );
      await _pumpCard(tester, cafe);

      // Status chip "Còn chỗ" (green) — áp dụng cho seat-based cafe.
      expect(find.text('CÒN CHỖ'), findsOneWidget);
      // Ghế stat box: hiển thị "30/40" vì totalSeats > 0.
      expect(find.text('30/40'), findsOneWidget);
    });

    testWidgets('seat-based: available = 0 → red "Hết chỗ" + ghế stat box red',
        (tester) async {
      final cafe = _makeCafe(
        totalSeats: 40,
        availableSeats: 0,
        seatStatus: CafeSeatStatus.full,
      );
      await _pumpCard(tester, cafe);

      // Status chip "Hết chỗ" (red).
      expect(find.text('HẾT CHỖ'), findsOneWidget);
      // Ghế stat box: hiển thị "0/40" với màu đỏ (AppColors.error).
      expect(find.text('0/40'), findsOneWidget);
    });

    testWidgets('seat-based: limited (≤ 20%) → "Sắp hết" + ghế stat box amber',
        (tester) async {
      // 5/40 = 12.5% → limited.
      final cafe = _makeCafe(
        totalSeats: 40,
        availableSeats: 5,
        seatStatus: CafeSeatStatus.limited,
      );
      await _pumpCard(tester, cafe);

      // Status chip "Sắp hết" (amber).
      expect(find.text('SẮP HẾT'), findsOneWidget);
      // Ghế stat box: "5/40".
      expect(find.text('5/40'), findsOneWidget);
    });

    testWidgets(
        'table-based (totalSeats=0): ghế hiển thị "—" (KHÔNG dùng tables)',
        (tester) async {
      // Backend trả totalSeats=0 (table-based pricing) — trước đây code
      // fallback sang tables làm "Ghế 10/10" gây hiểu nhầm. Build
      // 2026-10-03 fix: hiển thị "—" thay vì fallback.
      final cafe = _makeCafe(
        totalSeats: 0,
        availableSeats: 0,
        totalTableCount: 10,
        availableTableCount: 8,
      );
      await _pumpCard(tester, cafe);

      // Ghế stat box: "—" (màu grey, không dùng tables).
      expect(find.text('—'), findsOneWidget);

      // Box game stat box vẫn hiển thị ratio như cũ (không liên quan
      // đến bug seat-based fallback).
      expect(find.text('20/20'), findsOneWidget);
    });
  });

  group('CafeCard — price display (build 2026-10-03)', () {
    testWidgets('timeBased billing: hiển thị "Xk/giờ"', (tester) async {
      final cafe = _makeCafe(
        basePrice: 60000,
        billingModel: BillingModel.timeBased,
      );
      await _pumpCard(tester, cafe);

      // 60000 VND / timeBased → "60k/giờ".
      expect(find.text('60k/giờ'), findsOneWidget);
    });

    testWidgets('fixed billing: hiển thị "Xk/lượt"', (tester) async {
      final cafe = _makeCafe(
        basePrice: 150000,
        billingModel: BillingModel.fixed,
      );
      await _pumpCard(tester, cafe);

      expect(find.text('150k/lượt'), findsOneWidget);
    });

    testWidgets('tiered billing: hiển thị "Xk/{N}ph"', (tester) async {
      // tieredBlockMinutes = 15 → "Xk/15ph".
      final cafe = _makeCafe(
        basePrice: 10000,
        billingModel: BillingModel.tiered,
      );
      await _pumpCard(tester, cafe);

      expect(find.text('10k/15ph'), findsOneWidget);
    });

    testWidgets('basePrice = 0 (BE cũ) → "—"', (tester) async {
      final cafe = _makeCafe(basePrice: 0);
      await _pumpCard(tester, cafe);

      // "—" xuất hiện 1 lần ở stat box "Giá" (nếu totalSeats > 0 thì
      // stat box ghế hiển thị "X/Y", không có "—").
      expect(find.text('—'), findsOneWidget);
    });
  });

  group('CafeCard — layout (build 2026-10-03)', () {
    testWidgets('hiển thị cafe name + address + 3 stat boxes (ghế/giá/box)',
        (tester) async {
      final cafe = _makeCafe();
      await _pumpCard(tester, cafe);

      // Name + address.
      expect(find.text('Boardvearse cafe'), findsOneWidget);
      expect(find.textContaining('Nguyen Thai Hoc'), findsOneWidget);

      // 3 stat boxes (ghế/giá/box) với label.
      expect(find.text('Ghế trống'), findsOneWidget);
      expect(find.text('Giá'), findsOneWidget);
      expect(find.text('Box game'), findsOneWidget);

      // Bàn trống KHONG con xuat hien (build 2026-10-03 đã bỏ).
      expect(find.text('Bàn trống'), findsNothing);

      // Ghế ratio "8/40" (seat-based cafe, totalSeats=40).
      expect(find.text('8/40'), findsOneWidget);
      // Box ratio "20/20".
      expect(find.text('20/20'), findsOneWidget);
    });

    testWidgets('hiển thị distance pill ~2.9 km', (tester) async {
      final cafe = _makeCafe(distanceMeters: 2887.0);
      await _pumpCard(tester, cafe);

      // DistanceFormatter.format(2887) → "2.9 km".
      expect(find.text('2.9 km'), findsOneWidget);
    });

    testWidgets('hiển thị rating pill', (tester) async {
      final cafe = _makeCafe();
      await _pumpCard(tester, cafe);

      expect(find.text('4.5'), findsOneWidget);
    });

    testWidgets('hiển thị wait banner khi game đang chờ', (tester) async {
      // Build cafe thủ công với waiting status + estimatedWaitMinutes.
      final waitingCafe = CafeEntity(
        id: 'cafe-1',
        name: 'Boardvearse cafe',
        address: '12345 Nguyen Thai Hoc, Q1, TP.HCM',
        imageUrl: '',
        distanceMeters: 2887.0,
        availableTables: 0,
        hasGameInStock: false,
        estimatedWaitMinutes: 15,
        rating: 4.5,
        availableGameIds: const [],
        totalSeats: 40,
        availableSeats: 30,
        seatStatus: CafeSeatStatus.available,
        availableTableCount: 0,
        totalTableCount: 10,
        totalGameBoxCount: 5,
        availableGameCount: 0,
        selectedGameAvailabilityStatus:
            SelectedGameAvailabilityStatus.waitingForGame,
      );
      await _pumpCard(tester, waitingCafe);

      // Wait banner hiển thị "~15 phút".
      expect(find.textContaining('15 phút'), findsOneWidget);
    });
  });
}
