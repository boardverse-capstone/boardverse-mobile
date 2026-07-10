import '../../domain/entities/cafe_entity.dart';

class CafeModel {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double distanceKm;
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

  const CafeModel({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.distanceKm,
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
  });

  factory CafeModel.fromJson(Map<String, dynamic> json) {
    return CafeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      imageUrl: json['imageUrl'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      availableTables: json['availableTables'] as int,
      hasGameInStock: json['hasGameInStock'] as bool,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      rating: (json['rating'] as num).toDouble(),
      availableGameIds: List<String>.from(json['availableGameIds'] as List),
      // Seat-based fields
      totalSeats: json['totalSeats'] as int? ?? 20,
      availableSeats: json['availableSeats'] as int? ?? 15,
      seatStatus: _parseSeatStatus(json['seatStatus'] as String?),
      depositAmount: (json['depositAmount'] as num?)?.toDouble(),
      depositMinutesLimit: json['depositMinutesLimit'] as int?,
      openingHours: json['openingHours'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
    );
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
      'distanceKm': distanceKm,
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
    };
  }

  CafeEntity toEntity() => CafeEntity(
        id: id,
        name: name,
        address: address,
        imageUrl: imageUrl,
        distanceKm: distanceKm,
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
      );
}
