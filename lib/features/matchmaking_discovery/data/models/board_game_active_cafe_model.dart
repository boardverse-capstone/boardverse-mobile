import '../../domain/entities/board_game_active_cafe_entity.dart';
import '../../domain/entities/cafe_detail_entity.dart';
import '../../domain/entities/cafe_entity.dart';

/// Model parse từ response của
/// `GET /api/v1/board-games/{boardgameId}/active-cafes`.
///
/// Đây là **chiều ngược** của `CafeActiveGameModel` — player hỏi
/// "chơi game này ở đâu?" thay vì "quán này có game nào?". Mỗi item
/// bao gồm thông tin quán + thông tin kho (inventory) của board game
/// đó tại quán.
///
/// Field semantics:
/// - `inventoryId` — mã mục kho (`CafeGameInventory.Id`). Dùng khi gọi
///   reservation flow liên quan đến hộp game cụ thể.
/// - `cafeId` — mã quán cafe (`Cafe.Id`).
/// - `availableGameBoxCount` — số hộp game đang `Available` (còn trống)
///   cho tựa board game này tại quán. Khác với `availableGameCount` của
///   `NearbyCafeDto` (đó là tổng số hộp trống của MỌI tựa game tại quán).
/// - `status` — `Available` (còn hộp trống) hoặc `InUse` (đang được thuê).
/// - `distanceMeters` — `null` nếu player không truyền `latitude`/
///   `longitude` (sort theo tên A→Z thay vì khoảng cách).
///
/// Docs: `.agents/docs/apis_docs/board-games.md`
/// §GET /api/v1/board-games/{id}/active-cafes
class BoardGameActiveCafeModel {
  final String inventoryId;
  final String cafeId;
  final String cafeName;
  final String cafeAddress;
  final String? imageUrl;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;

  /// `null` khi player không truyền location (sort theo tên).
  final int? distanceMeters;

  final int totalSeats;
  final int availableSeats;

  final int availableTableCount;
  final int totalTableCount;

  /// Tổng số hộp của board game này tại quán (Available + InUse).
  final int totalGameBoxCount;

  /// Số hộp `Available` (còn trống) của board game này tại quán.
  final int availableGameBoxCount;

  /// `true` ⇔ `availableGameBoxCount > 0`.
  final bool isAvailableNow;

  /// `Available` | `InUse` — trạng thái inventory entry.
  final String status;

  /// `Active` | `Inactive` | `Suspended` — trạng thái partner của quán.
  final String operatingStatus;

  /// Phút chờ ước tính khi `status = InUse`. `null` khi còn hộp trống.
  final int? estimatedWaitMinutes;

  // ─── Pricing (build 2026-10-03) ─────────────────────────────────────
  /// Giá cơ bản (VNĐ) — map từ `basePrice` trong response. Hiển thị trên
  /// stat box "Giá" của [CafeCard]. Default 0 khi BE không trả → UI
  /// hiển thị "—".
  final double basePrice;

  /// Billing model — quyết định suffix giá (`/giờ` | `/lượt` | `/Xph`).
  /// Map từ `billingModel` string (`TIME_BASED` | `FIXED` | `TIERED`).
  final BillingModel billingModel;

  /// Block minutes cho `tiered` billing. Null khi billing khác `tiered`.
  final int? tieredBlockMinutes;

  const BoardGameActiveCafeModel({
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

  factory BoardGameActiveCafeModel.fromJson(Map<String, dynamic> json) {
    // BE trả `id`/`name`/`address` cho thông tin quán (giống shape `CafeDto`),
    // không phải `cafeId`/`cafeName`/`cafeAddress`. Fallback `cafeId`/`cafeName`
    // để tương thích với response cũ (nếu BE đổi lại).
    final cafeId = (json['cafeId'] as String?) ?? (json['id'] as String? ?? '');
    final cafeName = (json['cafeName'] as String?) ?? (json['name'] as String? ?? '');
    final cafeAddress =
        (json['cafeAddress'] as String?) ?? (json['address'] as String? ?? '');

    // `inventoryId` không có trong response hiện tại (response trả 1 entry /
    // cafe, không phải entry-level). Fallback về `cafeId` để giữ field
    // non-null cho entity, tránh cast `Null as String` throw trên web (DDC).
    final inventoryId = (json['inventoryId'] as String?) ?? cafeId;

    return BoardGameActiveCafeModel(
      inventoryId: inventoryId,
      cafeId: cafeId,
      cafeName: cafeName,
      cafeAddress: cafeAddress,
      imageUrl: json['imageUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // `distanceMeters` null khi player không gửi location → backend
      // không tính khoảng cách (sort theo tên A→Z).
      distanceMeters: json['distanceMeters'] == null
          ? null
          : (json['distanceMeters'] as num).toInt(),
      totalSeats: (json['totalSeats'] as int? ?? 0),
      availableSeats: (json['availableSeats'] as int? ?? 0),
      availableTableCount: (json['availableTableCount'] as int? ?? 0),
      totalTableCount: (json['totalTableCount'] as int? ?? 0),
      // `totalGameBoxCount` trong response — tổng box của MỌI game tại quán.
      // Vì endpoint là `/board-games/{id}/active-cafes`, tất cả box này
      // thuộc về game đang query (filter server-side).
      totalGameBoxCount: (json['totalGameBoxCount'] as int? ?? 0),
      // `availableGameCount` = số hộp Available của game này tại quán.
      // Tên field BE trả là `availableGameCount` (không phải
      // `availableGameBoxCount` như entity docs cũ mô tả).
      availableGameBoxCount: (json['availableGameBoxCount'] as int?) ??
          (json['availableGameCount'] as int? ?? 0),
      isAvailableNow: ((json['availableGameBoxCount'] as int?) ??
              (json['availableGameCount'] as int? ?? 0)) >
          0,
      status: (json['status'] as String?) ?? 'Available',
      operatingStatus: (json['operatingStatus'] as String?) ?? 'Active',
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      // Pricing (build 2026-10-03).
      //
      // `basePrice` — BE trả theo VNĐ (vd: 60000 cho 60k/giờ). Default 0
      // nếu field không có → UI hiển thị "—" thay vì crash.
      //
      // `billingModel` — string enum: `TIME_BASED` | `FIXED` | `TIERED`.
      // Parse qua [billingModelFromString] (helper trong cafe_entity.dart
      // từ build 2026-10-03). Default `timeBased` nếu BE trả giá trị lạ.
      //
      // `tieredBlockMinutes` — int, null khi billing khác `tiered`.
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0,
      billingModel: billingModelFromString(json['billingModel'] as String?),
      tieredBlockMinutes: json['tieredBlockMinutes'] as int?,
    );
  }

  /// Chuyển sang domain [BoardGameActiveCafeEntity] cho UI / cubit.
  BoardGameActiveCafeEntity toEntity() {
    return BoardGameActiveCafeEntity(
      inventoryId: inventoryId,
      cafeId: cafeId,
      cafeName: cafeName,
      cafeAddress: cafeAddress,
      imageUrl: imageUrl ?? '',
      phoneNumber: phoneNumber,
      latitude: latitude,
      longitude: longitude,
      distanceMeters: distanceMeters,
      totalSeats: totalSeats,
      availableSeats: availableSeats,
      availableTableCount: availableTableCount,
      totalTableCount: totalTableCount,
      totalGameBoxCount: totalGameBoxCount,
      availableGameBoxCount: availableGameBoxCount,
      isAvailableNow: isAvailableNow,
      status: status,
      operatingStatus: operatingStatus,
      estimatedWaitMinutes: estimatedWaitMinutes,
      // Pricing (build 2026-10-03) — propagate sang entity để CafeCard
      // hiển thị "Giá" stat box.
      basePrice: basePrice,
      billingModel: billingModel,
      tieredBlockMinutes: tieredBlockMinutes,
    );
  }
}