import 'package:equatable/equatable.dart';

import 'cafe_detail_entity.dart';
import 'cafe_entity.dart';

/// Trạng thái vận hành của inventory entry tại quán — map từ
/// `status` trong response `GET /api/v1/board-games/{id}/active-cafes`.
enum CafeInventoryStatus {
  /// Hộp đang trống — player có thể đặt ngay.
  available,

  /// Hộp đang được thuê — UI: "Chờ game ~X phút".
  inUse,
}

extension CafeInventoryStatusX on CafeInventoryStatus {
  String get apiKey {
    switch (this) {
      case CafeInventoryStatus.available:
        return 'Available';
      case CafeInventoryStatus.inUse:
        return 'InUse';
    }
  }

  static CafeInventoryStatus fromApi(String? value) {
    switch (value) {
      case 'InUse':
        return CafeInventoryStatus.inUse;
      case 'Available':
      default:
        return CafeInventoryStatus.available;
    }
  }

  /// UI label tiếng Việt.
  String get displayLabel {
    switch (this) {
      case CafeInventoryStatus.available:
        return 'Còn trống';
      case CafeInventoryStatus.inUse:
        return 'Đang thuê';
    }
  }
}

/// Trạng thái partner của quán — map từ `operatingStatus`.
enum CafePartnerStatus {
  active,
  inactive,
  suspended,
}

extension CafePartnerStatusX on CafePartnerStatus {
  static CafePartnerStatus fromApi(String? value) {
    switch (value) {
      case 'Inactive':
        return CafePartnerStatus.inactive;
      case 'Suspended':
        return CafePartnerStatus.suspended;
      case 'Active':
      default:
        return CafePartnerStatus.active;
    }
  }
}

/// Entity domain cho response của
/// `GET /api/v1/board-games/{boardgameId}/active-cafes`.
///
/// Entity này **mở rộng** [CafeEntity] (kế thừa các trường cơ bản của
/// quán) + bổ sung thông tin inventory của board game cụ thể tại quán
/// (`inventoryId`, `availableGameBoxCount`, `status`, …).
///
/// Dùng cho [BoardGameDetailPage] — thay thế section "QUÁN CAFE GẦN BẠN"
/// bằng "QUÁN CÓ BOARD GAME NÀY" (player xem quán nào có sẵn board game
/// này để chơi).
///
/// Docs: `.agents/docs/apis_docs/board-games.md`
/// §GET /api/v1/board-games/{id}/active-cafes
class BoardGameActiveCafeEntity extends Equatable {
  /// Mã mục kho (`CafeGameInventory.Id`) — dùng cho reservation flow
  /// khi cần reference inventory entry.
  final String inventoryId;

  /// Mã quán cafe (`Cafe.Id`).
  final String cafeId;

  /// Tên quán cafe.
  final String cafeName;

  /// Địa chỉ quán (free-form).
  final String cafeAddress;

  /// URL ảnh đại diện. Empty string nếu backend không trả.
  final String imageUrl;

  /// Số điện thoại liên hệ (optional).
  final String? phoneNumber;

  /// Toạ độ quán — null nếu backend không trả (vd: quán quá xa).
  final double? latitude;
  final double? longitude;

  /// Khoảng cách (m) từ player đến quán. **`null`** khi player không
  /// truyền `latitude`/`longitude` (sort theo tên A→Z).
  final int? distanceMeters;

  // ─── Capacity (BR-01) ───────────────────────────────────────────────
  final int totalSeats;
  final int availableSeats;
  final int availableTableCount;
  final int totalTableCount;

  // ─── Inventory of THIS board game ───────────────────────────────────
  /// Tổng hộp của board game này tại quán (`Available` + `InUse`).
  final int totalGameBoxCount;

  /// Số hộp `Available` — player có thể đặt ngay.
  final int availableGameBoxCount;

  /// `true` ⇔ `availableGameBoxCount > 0`.
  final bool isAvailableNow;

  /// Trạng thái inventory: `Available` (còn trống) hoặc `InUse`.
  final String status;

  /// Trạng thái partner: `Active` | `Inactive` | `Suspended`.
  final String operatingStatus;

  /// Phút chờ ước tính khi `status = InUse`. `null` khi còn hộp trống.
  final int? estimatedWaitMinutes;

  // ─── Pricing (build 2026-10-03) ─────────────────────────────────────
  /// Giá cơ bản (VNĐ) — map từ `basePrice` trong response. UI hiển thị
  /// trên stat box "Giá" của [CafeCard].
  final double basePrice;

  /// Billing model — quyết định suffix giá (`/giờ` | `/lượt` | `/Xph`).
  /// Map từ `billingModel` string (`TIME_BASED` | `FIXED` | `TIERED`).
  final BillingModel billingModel;

  /// Block minutes cho `tiered` billing. Null khi billing khác `tiered`.
  final int? tieredBlockMinutes;

  const BoardGameActiveCafeEntity({
    required this.inventoryId,
    required this.cafeId,
    required this.cafeName,
    required this.cafeAddress,
    required this.imageUrl,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.totalSeats,
    required this.availableSeats,
    required this.availableTableCount,
    required this.totalTableCount,
    required this.totalGameBoxCount,
    required this.availableGameBoxCount,
    required this.isAvailableNow,
    required this.status,
    required this.operatingStatus,
    required this.estimatedWaitMinutes,
    // Pricing (build 2026-10-03)
    this.basePrice = 0,
    this.billingModel = BillingModel.timeBased,
    this.tieredBlockMinutes,
  });

  /// Convert sang [CafeEntity] cho các widget cũ (vd: [CafeCard]) chỉ cần
  /// thông tin quán cơ bản. Các field inventory-specific (`inventoryId`,
  /// `availableGameBoxCount`, …) sẽ được bind riêng qua card wrapper.
  CafeEntity toCafeEntity() {
    return CafeEntity(
      id: cafeId,
      name: cafeName,
      address: cafeAddress,
      imageUrl: imageUrl,
      // CafeEntity.distanceMeters không nullable — fallback 0 nếu null
      // (xảy ra khi player không truyền location → sort theo tên).
      distanceMeters: (distanceMeters ?? 0).toDouble(),
      availableTables: availableTableCount,
      // `hasGameInStock = isAvailableNow` — quán có hộp Available của
      // game này → player có thể đặt ngay.
      hasGameInStock: isAvailableNow,
      estimatedWaitMinutes: estimatedWaitMinutes,
      // CafeEntity có field `rating` — `singing` ở backend không trả;
      // default 0 để UI không hiển thị rating pill (xem `CafeCard`).
      rating: 0,
      // Không có list `availableGameIds` — endpoint active-cafes chỉ
      // trả về quán có 1 board game cụ thể, không phải full inventory.
      availableGameIds: const [],
      // Seat-based fields
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      // Seat status derived from availableSeats / totalSeats ratio.
      seatStatus: CafeEntity.calculateSeatStatus(availableSeats, totalSeats),
      phoneNumber: phoneNumber,
      // Nearby fields — không có sẵn, default 0.
      availableTableCount: availableTableCount,
      totalTableCount: totalTableCount,
      // `totalGameBoxCount` map sang `totalGameBoxCount` (tổng box Available
      // + InUse) cho UI "Box game".
      totalGameBoxCount: totalGameBoxCount,
      // `availableGameBoxCount` map sang `availableGameCount`.
      availableGameCount: availableGameBoxCount,
      // Trạng thái box: nếu đang InUse → "Chờ game ~X phút" (UI).
      selectedGameAvailabilityStatus: isAvailableNow
          ? SelectedGameAvailabilityStatus.gameAvailable
          : SelectedGameAvailabilityStatus.waitingForGame,
      // Pricing (build 2026-10-03) — truyền vào CafeEntity để stat
      // box "Giá" hiển thị đúng suffix (`/giờ` | `/lượt` | `/Xph`).
      basePrice: basePrice,
      billingModel: billingModel,
      tieredBlockMinutes: tieredBlockMinutes,
    );
  }

  // ─── Convenience helpers ────────────────────────────────────────────

  /// Khoảng cách dạng km (null-safe). Dùng cho UI hiển thị "Xkm".
  double? get distanceKm {
    final d = distanceMeters;
    if (d == null) return null;
    return d / 1000.0;
  }

  /// Trạng thái inventory dạng enum.
  CafeInventoryStatus get statusEnum =>
      CafeInventoryStatusX.fromApi(status);

  /// Trạng thái partner dạng enum.
  CafePartnerStatus get operatingStatusEnum =>
      CafePartnerStatusX.fromApi(operatingStatus);

  /// UI helper: có đang chờ game (không có hộp Available) không.
  bool get isWaitingForGame =>
      !isAvailableNow || statusEnum == CafeInventoryStatus.inUse;

  @override
  List<Object?> get props => [
        inventoryId,
        cafeId,
        cafeName,
        cafeAddress,
        imageUrl,
        phoneNumber,
        latitude,
        longitude,
        distanceMeters,
        totalSeats,
        availableSeats,
        availableTableCount,
        totalTableCount,
        totalGameBoxCount,
        availableGameBoxCount,
        isAvailableNow,
        status,
        operatingStatus,
        estimatedWaitMinutes,
        // Pricing (build 2026-10-03)
        basePrice,
        billingModel,
        tieredBlockMinutes,
      ];
}

/// Wrapper kết quả trả về cho
/// `GET /api/v1/board-games/{boardgameId}/active-cafes` — re-uses pattern
/// `NearbyCafesSearchResultEntity` (empty result message + alternative
/// suggestions) để cubit/UI có thể tái sử dụng render logic.
class ActiveCafesSearchResultEntity extends Equatable {
  /// Danh sách quán ACTIVE có board game này trong kho.
  final List<BoardGameActiveCafeEntity> cafes;

  /// Thông điệp UI khi danh sách rỗng (AC 5.1 tương tự `/cafes/nearby`).
  /// `null` khi có ít nhất 1 quán.
  final String? emptyResultMessage;

  /// Gợi ý thay thế khi rỗng — backend **chưa thiết kế**, để trống
  /// cho tương lai (vd: gợi ý board game cùng thể loại mà player có thể
  /// thử). Hiện tại luôn `[]`.
  final List<dynamic> alternativeSuggestions;

  /// Game hiện tại có nằm trong danh sách yêu thích của user hay không
  /// (build 2026-10-03+). UI dùng để hiển thị icon save/unsave trên
  /// header trang chi tiết board game. `false` khi:
  /// - User chưa đăng nhập (endpoint vẫn trả 200).
  /// - Backend cũ chưa hỗ trợ field này.
  final bool isSaved;

  const ActiveCafesSearchResultEntity({
    this.cafes = const [],
    this.emptyResultMessage,
    this.alternativeSuggestions = const [],
    this.isSaved = false,
  });

  bool get isEmpty => cafes.isEmpty;

  @override
  List<Object?> get props => [
        cafes,
        emptyResultMessage,
        alternativeSuggestions,
        isSaved,
      ];
}