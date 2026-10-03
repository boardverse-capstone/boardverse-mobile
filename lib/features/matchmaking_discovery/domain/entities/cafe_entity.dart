import 'package:equatable/equatable.dart';

import 'cafe_detail_entity.dart';

/// Trạng thái ghế ngồi theo business rules (BR-01)
enum CafeSeatStatus {
  available, // Trống khả dụng - có thể đặt
  limited, // Còn ít ghế - nên đặt sớm
  full, // Hết ghế - không thể đặt thêm
}

/// Trạng thái tựa game đã chọn tại quán — map từ
/// `NearbyCafeDto.selectedGameAvailabilityStatus` trong backend response.
enum SelectedGameAvailabilityStatus {
  /// Hộp game đang `Available` (rảnh) — UI: "Còn trống".
  gameAvailable,

  /// Tất cả hộp đang `InUse` — UI: "Chờ game ~X phút".
  waitingForGame,
}

/// Parse `BillingModel` từ BE string (vd: "TIME_BASED" → timeBased).
///
/// **Public** (không underscore) để data/model layer có thể gọi khi
/// map JSON response → entity. Default `timeBased` nếu BE trả giá trị
/// lạ hoặc null (giả định phổ biến nhất).
///
/// Build 2026-10-03: dùng cho parse `billingModel` từ response
/// `/api/v1/board-games/{id}/active-cafes`.
BillingModel billingModelFromString(String? raw) {
  switch (raw) {
    case 'FIXED':
      return BillingModel.fixed;
    case 'TIERED':
      return BillingModel.tiered;
    case 'TIME_BASED':
    default:
      return BillingModel.timeBased;
  }
}

class CafeEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double distanceMeters;
  final int availableTables;
  final bool hasGameInStock;
  final int? estimatedWaitMinutes;
  final double rating;
  final List<String> availableGameIds;

  // ─── Seat-based fields (BR-01) ───────────────────────────────────────
  final int totalSeats; // Tổng số ghế của quán
  final int availableSeats; // Ghế trống khả dụng hiện tại
  final CafeSeatStatus seatStatus; // Trạng thái ghế tổng quan
  final String? openingHours; // Giờ mở cửa
  final String? phoneNumber; // Số điện thoại liên hệ

  // ─── NearbyCafeDto fields (board-games nearby API) ──────────────────
  final int availableTableCount;
  final int totalTableCount;
  final int totalGameBoxCount;
  final int availableGameCount;
  final SelectedGameAvailabilityStatus
      selectedGameAvailabilityStatus; // AC 3.2

  // ─── Pricing (build 2026-10-03) ─────────────────────────────────────
  /// Giá cơ bản (VNĐ) — map từ `basePrice` trong response `.../active-cafes`
  /// và `GET /cafes/{id}`. Dùng để hiển thị "Giá" stat box trên card.
  ///
  /// Default 0 khi BE cũ chưa trả field này — UI hiển thị "—" thay vì số.
  final double basePrice;

  /// Billing model — quyết định suffix hiển thị giá (`/giờ` | `/lượt` | `/Xph`).
  final BillingModel billingModel;

  /// Block minutes cho `tiered` billing. Null khi billing model khác `tiered`.
  final int? tieredBlockMinutes;

  const CafeEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.distanceMeters,
    required this.availableTables,
    required this.hasGameInStock,
    this.estimatedWaitMinutes,
    required this.rating,
    required this.availableGameIds,
    // Seat-based fields
    required this.totalSeats,
    required this.availableSeats,
    required this.seatStatus,
    this.openingHours,
    this.phoneNumber,
    // NearbyCafeDto fields
    this.availableTableCount = 0,
    this.totalTableCount = 0,
    this.totalGameBoxCount = 0,
    this.availableGameCount = 0,
    this.selectedGameAvailabilityStatus =
        SelectedGameAvailabilityStatus.gameAvailable,
    // Pricing (build 2026-10-03)
    this.basePrice = 0,
    this.billingModel = BillingModel.timeBased,
    this.tieredBlockMinutes,
  });

  /// Backward-compat getter: chuyển `distanceMeters` → `distanceKm` cho UI
  /// cũ vẫn dùng `cafe.distanceKm`.
  double get distanceKm => distanceMeters / 1000.0;

  /// Tính toán trạng thái ghế dựa trên availableSeats / totalSeats
  static CafeSeatStatus calculateSeatStatus(int available, int total) {
    if (available == 0) return CafeSeatStatus.full;
    if (available <= total * 0.2) return CafeSeatStatus.limited;
    return CafeSeatStatus.available;
  }

  /// Tính phần trăm ghế còn trống
  double get availableSeatPercentage =>
      totalSeats > 0 ? (availableSeats / totalSeats) * 100 : 0;

  /// Tính phần trăm bàn còn trống (dùng `availableTableCount/totalTableCount`)
  double get availableTablePercentage =>
      totalTableCount > 0 ? (availableTableCount / totalTableCount) * 100 : 0;

  /// UI helper: có đang chờ game hay không.
  bool get isWaitingForGame =>
      selectedGameAvailabilityStatus ==
      SelectedGameAvailabilityStatus.waitingForGame;

  /// Format giá hiển thị trên stat box "Giá".
  ///
  /// - Nếu `basePrice == 0` (BE cũ không trả) → trả "—" thay vì số.
  /// - Ngược lại → format theo billing model:
  ///   - `timeBased` → "{X}k/giờ"
  ///   - `fixed`     → "{X}k/lượt"
  ///   - `tiered`    → "{X}k/{N}ph"
  ///
  /// Quy ước chia 1000 + suffix "k" (vd: 60000 → "60k") theo pattern đã
  /// có ở [CafeDetailEntity.priceDisplay]. BE trả basePrice theo VNĐ.
  String get priceDisplay {
    if (basePrice <= 0) return '—';
    final priceStr = _formatPriceK(basePrice);
    switch (billingModel) {
      case BillingModel.timeBased:
        return '$priceStr/giờ';
      case BillingModel.fixed:
        return '$priceStr/lượt';
      case BillingModel.tiered:
        return '$priceStr/${tieredBlockMinutes ?? 15}ph';
    }
  }

  /// Format số tiền dạng "Xk" (chia 1000 + làm tròn).
  /// - `60000` → "60k"
  /// - `10`    → "10" (giữ nguyên vì < 1000 — tránh hiển thị "0k")
  static String _formatPriceK(double price) {
    if (price >= 1000) {
      // Chia 1000 rồi làm tròn. Nếu có phần thập phân > 0 → giữ 1 chữ số.
      final k = price / 1000;
      if (k == k.truncateToDouble()) {
        return '${k.toInt()}k';
      }
      return '${k.toStringAsFixed(1)}k';
    }
    // < 1000 (vd: 10 VND) — hiển thị nguyên giá trị, không ép "k".
    return price.toStringAsFixed(0);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        distanceMeters,
        availableTables,
        hasGameInStock,
        estimatedWaitMinutes,
        rating,
        availableGameIds,
        // Seat-based fields
        totalSeats,
        availableSeats,
        seatStatus,
        openingHours,
        phoneNumber,
        // Nearby fields
        availableTableCount,
        totalTableCount,
        totalGameBoxCount,
        availableGameCount,
        selectedGameAvailabilityStatus,
        // Pricing (build 2026-10-03)
        basePrice,
        billingModel,
        tieredBlockMinutes,
      ];
}
