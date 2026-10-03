// Unit tests cho [BoardGameActiveCafeModel.fromJson] — build 2026-10-03.
//
// **Bối cảnh bug**: User báo cáo màn hình "QUÁN CÓ BOARD GAME NÀY"
// hiển thị sai thông tin giá:
// - Quán có `totalSeats: 40` nhưng `availableSeats` không được BE trả
//   → display "0/40" (mặc dùng default 0).
// - Quán có `totalSeats: 0` → display "Ghế 10/10" (fallback sang tables
//   gây hiểu nhầm).
// - Không hiển thị `basePrice` (giá cơ bản) — user muốn thấy để biết
//   chi phí trước khi đặt.
//
// Test cover:
// 1. Parse `basePrice` (VNĐ) từ JSON → toEntity.toCafeEntity.priceDisplay
//    hiển thị "Xk/giờ" | "Xk/lượt" | "Xk/15ph".
// 2. Parse `billingModel` (string enum TIME_BASED | FIXED | TIERED) →
//    enum tương ứng.
// 3. Parse `tieredBlockMinutes` cho TIERED billing.
// 4. Default 0 khi BE không trả → priceDisplay = "—".
// 5. toEntity.toCafeEntity() propagate basePrice + billingModel +
//    tieredBlockMinutes vào CafeEntity (UI dùng để render stat box).

import 'package:boardverse/features/matchmaking_discovery/data/models/board_game_active_cafe_model.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_detail_entity.dart';
import 'package:boardverse/features/matchmaking_discovery/domain/entities/cafe_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardGameActiveCafeModel — parse pricing fields (build 2026-10-03)',
      () {
    test('parse basePrice + TIME_BASED billing → priceDisplay "60k/giờ"',
        () {
      // Arrange — response thực tế từ BE với đầy đủ field pricing.
      final json = {
        'cafeId': 'cafe-1',
        'cafeName': 'BossCafe',
        'cafeAddress': '13 Nguyen Thai Hoc, Q1, TP.HCM',
        'totalSeats': 40,
        'availableTableCount': 7,
        'totalTableCount': 10,
        'availableGameCount': 10,
        'totalGameBoxCount': 10,
        'status': 'Available',
        'operatingStatus': 'Active',
        // Pricing.
        'basePrice': 60000,
        'billingModel': 'TIME_BASED',
      };

      // Act
      final model = BoardGameActiveCafeModel.fromJson(json);
      final cafe = model.toEntity().toCafeEntity();

      // Assert — pricing propagate xuyên suốt các layer.
      expect(model.basePrice, 60000);
      expect(model.billingModel, BillingModel.timeBased);
      expect(cafe.basePrice, 60000);
      expect(cafe.billingModel, BillingModel.timeBased);
      // UI hiển thị "60k/giờ" cho timeBased.
      expect(cafe.priceDisplay, '60k/giờ');
    });

    test('parse FIXED billing → priceDisplay "150k/lượt"', () {
      final json = {
        'cafeId': 'cafe-fixed',
        'cafeName': 'Fixed Cafe',
        'cafeAddress': 'addr',
        'basePrice': 150000,
        'billingModel': 'FIXED',
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      expect(cafe.priceDisplay, '150k/lượt');
    });

    test('parse TIERED billing + tieredBlockMinutes → priceDisplay "10k/15ph"',
        () {
      final json = {
        'cafeId': 'cafe-tiered',
        'cafeName': 'Tiered Cafe',
        'cafeAddress': 'addr',
        'basePrice': 10000,
        'billingModel': 'TIERED',
        'tieredBlockMinutes': 15,
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      expect(cafe.priceDisplay, '10k/15ph');
    });

    test('default billing = TIME_BASED khi BE không trả billingModel', () {
      final json = {
        'cafeId': 'cafe-legacy',
        'cafeName': 'Legacy Cafe',
        'cafeAddress': 'addr',
        'basePrice': 50000,
        // Không có `billingModel` → default TIME_BASED.
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      // Default TIME_BASED → "50k/giờ".
      expect(cafe.billingModel, BillingModel.timeBased);
      expect(cafe.priceDisplay, '50k/giờ');
    });

    test('default basePrice = 0 khi BE không trả → priceDisplay "—"', () {
      // Trường hợp BE cũ chưa hỗ trợ pricing — UI hiển thị "—"
      // thay vì crash với "0đ/giờ".
      final json = {
        'cafeId': 'cafe-old',
        'cafeName': 'Old Cafe',
        'cafeAddress': 'addr',
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      expect(cafe.basePrice, 0);
      expect(cafe.priceDisplay, '—');
    });

    test('billingModel không nhận diệnh được → fallback TIME_BASED', () {
      // Trường hợp BE trả giá trị lạ (vd: "PER_HOUR" thay vì "TIME_BASED").
      // Default TIME_BASED là giả định phổ biến nhất.
      final json = {
        'cafeId': 'cafe-unknown',
        'cafeName': 'Unknown Billing',
        'cafeAddress': 'addr',
        'basePrice': 30000,
        'billingModel': 'PER_HOUR', // không nằm trong enum
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      expect(cafe.billingModel, BillingModel.timeBased);
      expect(cafe.priceDisplay, '30k/giờ');
    });

    test('seat/price logic độc lập — fix bug "ngược" (build 2026-10-03)', () {
      // User phản ánh:
      // - Quán totalSeats=40, availableSeats=0 → "0/40" (OK theo data,
      //     nhưng BE không trả availableSeats — model default 0).
      // - Quán totalSeats=0, availableTableCount=10 → "Ghế 10/10"
      //     (fallback sang tables = nhầm).
      //
      // Fix: Khi totalSeats=0 → CafeEntity.priceDisplay dùng basePrice
      // (giá), không dùng ghế/tables. Ghế stat box hiển thị "—"
      // (test trong cafe_card_test.dart).
      //
      // Test này verify: CafeEntity có đủ basePrice, billingModel,
      // tieredBlockMinutes fields → UI có data để render.
      final json = {
        'cafeId': 'cafe-bug',
        'cafeName': 'Bug Repro',
        'cafeAddress': 'addr',
        'totalSeats': 40,
        // BE KHÔNG trả `availableSeats` → default 0 (data limitation).
        // Hiển thị "0/40" — không phải bug logic, chỉ thiếu data BE.
        'availableTableCount': 7,
        'totalTableCount': 10,
        'basePrice': 60000,
        'billingModel': 'TIME_BASED',
      };

      final cafe =
          BoardGameActiveCafeModel.fromJson(json).toEntity().toCafeEntity();

      // Đủ field pricing để UI hiển thị "Giá" stat box đúng.
      expect(cafe.basePrice, 60000);
      expect(cafe.priceDisplay, '60k/giờ');
      // Seat data vẫn propagate (UI hiển thị "0/40" từ data thực tế).
      expect(cafe.totalSeats, 40);
      expect(cafe.availableSeats, 0);
    });
  });
}