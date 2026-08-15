import '../../domain/entities/cafe_detail_entity.dart';
import '../../domain/entities/cafe_entity.dart';

class CafeModel {
  final String id;
  final String name;
  final String address;
  final String imageUrl;

  /// `distanceMeters` (PostGIS geography) — đơn vị chính từ backend.
  /// Field này là `nullable` để tương thích ngược với mock cũ (chỉ có
  /// `distanceKm`). Mock sẽ truyền `distanceKm * 1000` khi tạo model.
  final double distanceMeters;
  final int availableTables;
  final bool hasGameInStock;
  final int? estimatedWaitMinutes;
  final double rating;
  final List<String> availableGameIds;

  // ─── Seat-based fields (BR-01) ───────────────────────────────────────
  final int totalSeats;
  final int availableSeats;
  final CafeSeatStatus seatStatus;
  final String? openingHours;
  final String? phoneNumber;

  // ─── NearbyCafeDto fields (cafes nearby API) ────────────────────────
  final int availableTableCount;
  final int totalTableCount;
  final int totalGameBoxCount;
  final int availableGameCount;
  final SelectedGameAvailabilityStatus selectedGameAvailabilityStatus;

  // ─── CafeDetail API fields ──────────────────────────────────────────
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final double? basePrice; // Giá cơ bản từ API
  final String? billingModel; // TIME_BASED, FIXED, TIERED
  final double? tieredBlockRate;
  final int? tieredBlockMinutes;
  final bool isPricingLocked;
  final bool hasSePayConfigured;

  const CafeModel({
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
    // CafeDetail fields
    this.latitude,
    this.longitude,
    this.createdAt,
    this.basePrice,
    this.billingModel,
    this.tieredBlockRate,
    this.tieredBlockMinutes,
    this.isPricingLocked = false,
    this.hasSePayConfigured = false,
  });

  /// Parse từ `GET /api/cafes/{id}` (CafeDto cũ — không có distance, table).
  factory CafeModel.fromJson(Map<String, dynamic> json) {
    // Nếu response có `distanceMeters` thì dùng, fallback `distanceKm`.
    final distMeters = json['distanceMeters'] != null
        ? (json['distanceMeters'] as num).toDouble()
        : (json['distanceKm'] as num?)?.toDouble() != null
            ? (json['distanceKm'] as num).toDouble() * 1000.0
            : 0.0;

    return CafeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      imageUrl: (json['imageUrl'] as String?) ?? '',
      distanceMeters: distMeters,
      availableTables: (json['availableTables'] as int?) ?? 0,
      hasGameInStock: (json['hasGameInStock'] as bool?) ?? false,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      availableGameIds:
          (json['availableGameIds'] as List?)?.cast<String>() ??
              const <String>[],
      // Seat-based fields
      totalSeats: json['totalSeats'] as int? ?? 20,
      availableSeats: json['availableSeats'] as int? ?? 15,
      seatStatus: _parseSeatStatus(json['seatStatus'] as String?),
      openingHours: json['openingHours'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      // Nearby fields
      availableTableCount: (json['availableTableCount'] as int?) ?? 0,
      totalTableCount: (json['totalTableCount'] as int?) ?? 0,
      totalGameBoxCount: (json['totalGameBoxCount'] as int?) ?? 0,
      availableGameCount: (json['availableGameCount'] as int?) ?? 0,
      selectedGameAvailabilityStatus: _parseAvailabilityStatus(
          json['selectedGameAvailabilityStatus'] as String?),
      // CafeDetail fields
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      basePrice: (json['basePrice'] as num?)?.toDouble(),
      billingModel: json['billingModel'] as String?,
      tieredBlockRate: (json['tieredBlockRate'] as num?)?.toDouble(),
      tieredBlockMinutes: json['tieredBlockMinutes'] as int?,
      isPricingLocked: json['isPricingLocked'] as bool? ?? false,
      hasSePayConfigured: json['hasSePayConfigured'] as bool? ?? false,
    );
  }

  /// Parse trực tiếp từ `NearbyCafeDto` (mỗi phần tử trong `cafes.data[]`
  /// của response `GET /api/cafes/nearby`).
  ///
  /// **Field semantics** (xem `.agents/docs/apis_docs/cafe.md`):
  /// - `totalSeats` / `availableSeats` — sức chứa thực tế của quán (tổng số
  ///   ghế ngồi). Phản ánh đúng `CafeEntity.totalSeats` cho UI "Ghế trống".
  /// - `totalTableCount` / `availableTableCount` — số bàn vật lý. Map sang
  ///   field `availableTables` legacy cho UI "Bàn trống".
  /// - `totalGameBoxCount` / `availableGameCount` — số hộp game theo tựa
  ///   đã chọn tại quán.
  ///
  /// Lưu ý: NearbyCafeDto **không** có `name`, `address`, `imageUrl`, …
  /// nên sẽ cần gọi thêm `GET /api/cafes/{id}` để lấy chi tiết.
  /// Hàm này chấp nhận các trường optional — khi thiếu sẽ dùng default
  /// để hiển thị tạm thời.
  factory CafeModel.fromNearbyJson(Map<String, dynamic> json) {
    // Ưu tiên `availableSeats` thật từ API; nếu không có, ước lượng
    // theo `seatsPerTable = totalSeats / totalTableCount`:
    // `availableSeats ≈ availableTableCount * seatsPerTable`.
    final availableTables = json['availableTableCount'] as int? ?? 0;
    final totalTables = json['totalTableCount'] as int? ?? 0;
    final totalSeats = json['totalSeats'] as int? ?? 0;
    final availableSeatsRaw = json['availableSeats'] as int?;
    int availableSeats;
    if (availableSeatsRaw != null) {
      availableSeats = availableSeatsRaw;
    } else if (totalSeats > 0 && totalTables > 0) {
      // Ước lượng đều theo tỷ lệ ghế/bàn.
      final seatsPerTable = totalSeats / totalTables;
      availableSeats = (availableTables * seatsPerTable).round();
    } else {
      availableSeats = availableTables;
    }

    // Tính seatStatus từ tỷ lệ ghế trống nếu có dữ liệu; fallback dùng
    // tỷ lệ bàn trống (giữ behavior cũ cho backward-compat).
    final seatStatusStr = totalSeats > 0
        ? _seatStatusStringFromAvailable(availableSeats, totalSeats)
        : _seatStatusStringFromAvailable(availableTables, totalTables);

    return CafeModel.fromJson({
      'id': json['cafeId'] ?? json['id'],
      'name': json['name'] ?? '',
      'address': json['address'] ?? '',
      'imageUrl': json['imageUrl'] ?? '',
      'distanceMeters': json['distanceMeters'],
      'availableTables': availableTables,
      'hasGameInStock':
          (json['availableGameCount'] as int? ?? 0) > 0,
      'estimatedWaitMinutes': json['estimatedWaitMinutes'],
      'rating': 0,
      'availableGameIds': <String>[],
      // Seat-based fields — dùng `totalSeats`/`availableSeats` THẬT từ
      // backend; `availableSeats` ước lượng đều theo tỷ lệ ghế/bàn khi
      // backend chưa trả field này.
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'seatStatus': seatStatusStr,
      'phoneNumber': json['phoneNumber'],
      // Nearby fields — giữ nguyên để UI "Bàn trống" / "Box game" chạy đúng.
      'availableTableCount': availableTables,
      'totalTableCount': totalTables,
      'totalGameBoxCount': json['totalGameBoxCount'] ?? 0,
      'availableGameCount': json['availableGameCount'] ?? 0,
      'selectedGameAvailabilityStatus':
          json['selectedGameAvailabilityStatus'],
    });
  }

  static CafeSeatStatus _parseSeatStatus(String? status) {
    switch (status) {
      case 'limited':
        return CafeSeatStatus.limited;
      case 'full':
        return CafeSeatStatus.full;
      default:
        return CafeSeatStatus.available;
    }
  }

  /// Tính seatStatus dạng String từ số bàn (dùng trong fromNearbyJson).
  static String _seatStatusStringFromAvailable(int available, int total) {
    if (total <= 0) return 'available';
    if (available == 0) return 'full';
    if (available <= total * 0.2) return 'limited';
    return 'available';
  }

  static SelectedGameAvailabilityStatus _parseAvailabilityStatus(
      String? status) {
    switch (status) {
      case 'WaitingForGame':
        return SelectedGameAvailabilityStatus.waitingForGame;
      case 'GameAvailable':
      default:
        return SelectedGameAvailabilityStatus.gameAvailable;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
      'distanceMeters': distanceMeters,
      'availableTables': availableTables,
      'hasGameInStock': hasGameInStock,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'rating': rating,
      'availableGameIds': availableGameIds,
      // Seat-based fields
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'seatStatus': seatStatus.name,
      'openingHours': openingHours,
      'phoneNumber': phoneNumber,
      // Nearby fields
      'availableTableCount': availableTableCount,
      'totalTableCount': totalTableCount,
      'totalGameBoxCount': totalGameBoxCount,
      'availableGameCount': availableGameCount,
      'selectedGameAvailabilityStatus':
          selectedGameAvailabilityStatus.name,
    };
  }

  CafeEntity toEntity() => CafeEntity(
        id: id,
        name: name,
        address: address,
        imageUrl: imageUrl,
        distanceMeters: distanceMeters,
        availableTables: availableTables,
        hasGameInStock: hasGameInStock,
        estimatedWaitMinutes: estimatedWaitMinutes,
        rating: rating,
        availableGameIds: availableGameIds,
        // Seat-based fields
        totalSeats: totalSeats,
        availableSeats: availableSeats,
        seatStatus: seatStatus,
        openingHours: openingHours,
        phoneNumber: phoneNumber,
        // Nearby fields
        availableTableCount: availableTableCount,
        totalTableCount: totalTableCount,
        totalGameBoxCount: totalGameBoxCount,
        availableGameCount: availableGameCount,
        selectedGameAvailabilityStatus: selectedGameAvailabilityStatus,
      );

  /// Chuyển CafeModel (từ API) sang CafeDetailEntity
  /// dùng cho trang chi tiết quán cafe.
  CafeDetailEntity toDetailEntity() {
    // Parse billing model
    BillingModel parsedBilling;
    switch (billingModel) {
      case 'FIXED':
        parsedBilling = BillingModel.fixed;
        break;
      case 'TIERED':
        parsedBilling = BillingModel.tiered;
        break;
      case 'TIME_BASED':
      default:
        parsedBilling = BillingModel.timeBased;
    }

    return CafeDetailEntity(
      id: id,
      name: name,
      address: address,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
      description: null,
      phoneNumber: phoneNumber,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt ?? DateTime.now(),
      // Pricing
      billingModel: parsedBilling,
      basePrice: basePrice ?? 0,
      tieredBlockMinutes: tieredBlockMinutes,
      isPricingLocked: isPricingLocked,
      hasSePayConfigured: hasSePayConfigured,
      // Capacity
      totalSeats: totalSeats,
    );
  }
}
