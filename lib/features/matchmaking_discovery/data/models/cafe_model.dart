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
  final double? depositAmount;
  final int? depositMinutesLimit;
  final String? openingHours;
  final String? phoneNumber;

  // ─── NearbyCafeDto fields (cafes nearby API) ────────────────────────
  final int availableTableCount;
  final int totalTableCount;
  final int totalGameBoxCount;
  final int availableGameCount;
  final SelectedGameAvailabilityStatus selectedGameAvailabilityStatus;

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
    this.depositAmount,
    this.depositMinutesLimit,
    this.openingHours,
    this.phoneNumber,
    // NearbyCafeDto fields
    this.availableTableCount = 0,
    this.totalTableCount = 0,
    this.totalGameBoxCount = 0,
    this.availableGameCount = 0,
    this.selectedGameAvailabilityStatus =
        SelectedGameAvailabilityStatus.gameAvailable,
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
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      depositMinutesLimit: json['depositMinutesLimit'] as int?,
      openingHours: json['openingHours'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      // Nearby fields
      availableTableCount: (json['availableTableCount'] as int?) ?? 0,
      totalTableCount: (json['totalTableCount'] as int?) ?? 0,
      totalGameBoxCount: (json['totalGameBoxCount'] as int?) ?? 0,
      availableGameCount: (json['availableGameCount'] as int?) ?? 0,
      selectedGameAvailabilityStatus: _parseAvailabilityStatus(
          json['selectedGameAvailabilityStatus'] as String?),
    );
  }

  /// Parse trực tiếp từ `NearbyCafeDto` (mỗi phần tử trong `cafes.data[]`
  /// của response `GET /api/cafes/nearby`).
  /// Lưu ý: NearbyCafeDto **không** có `name`, `address`, `imageUrl`, …
  /// nên sẽ cần gọi thêm `GET /api/cafes/{id}` để lấy chi tiết.
  /// Hàm này chấp nhận các trường optional — khi thiếu sẽ dùng default
  /// để hiển thị tạm thời.
  factory CafeModel.fromNearbyJson(Map<String, dynamic> json) {
    // Tính seatStatus string từ số bàn trống/tổng
    final available = json['availableTableCount'] as int? ?? 0;
    final total = json['totalTableCount'] as int? ?? 0;
    final seatStatusStr = _seatStatusStringFromAvailable(available, total);

    return CafeModel.fromJson({
      'id': json['cafeId'] ?? json['id'],
      'name': json['name'] ?? '',
      'address': json['address'] ?? '',
      'imageUrl': json['imageUrl'] ?? '',
      'distanceMeters': json['distanceMeters'],
      'availableTables': json['availableTableCount'] ?? 0,
      'hasGameInStock':
          (json['availableGameCount'] as int? ?? 0) > 0,
      'estimatedWaitMinutes': json['estimatedWaitMinutes'],
      'rating': 0,
      'availableGameIds': <String>[],
      'totalSeats': json['totalTableCount'] ?? 0,
      'availableSeats': json['availableTableCount'] ?? 0,
      'seatStatus': seatStatusStr, // String cho fromJson
      'availableTableCount': json['availableTableCount'] ?? 0,
      'totalTableCount': json['totalTableCount'] ?? 0,
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
      'depositAmount': depositAmount,
      'depositMinutesLimit': depositMinutesLimit,
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
        depositAmount: depositAmount,
        depositMinutesLimit: depositMinutesLimit,
        openingHours: openingHours,
        phoneNumber: phoneNumber,
        // Nearby fields
        availableTableCount: availableTableCount,
        totalTableCount: totalTableCount,
        totalGameBoxCount: totalGameBoxCount,
        availableGameCount: availableGameCount,
        selectedGameAvailabilityStatus: selectedGameAvailabilityStatus,
      );
}
