import '../../domain/entities/seat_availability_entity.dart';

class SeatAvailabilityModel {
  final String cafeId;
  final String cafeName;
  final int totalSeats;
  final int availableSeats;
  final int holdingSeats;
  final int reservedSeats;
  final int inUseSeats;
  final SeatOverallStatus overallStatus;
  final DateTime lastUpdated;
  final DateTime? nextAvailableAt;
  final DateTime? timeSlot; // Khung giờ áp dụng (BR-05)

  const SeatAvailabilityModel({
    required this.cafeId,
    this.cafeName = '',
    this.totalSeats = 0,
    this.availableSeats = 0,
    this.holdingSeats = 0,
    this.reservedSeats = 0,
    this.inUseSeats = 0,
    this.overallStatus = SeatOverallStatus.plenty,
    required this.lastUpdated,
    this.nextAvailableAt,
    this.timeSlot,
  });

  factory SeatAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return SeatAvailabilityModel(
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String? ?? '',
      totalSeats: json['totalSeats'] as int,
      availableSeats: json['availableSeats'] as int,
      holdingSeats: json['holdingSeats'] as int? ?? 0,
      reservedSeats: json['reservedSeats'] as int? ?? 0,
      inUseSeats: json['inUseSeats'] as int? ?? 0,
      overallStatus: _parseStatus(json['overallStatus'] as String?),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
      nextAvailableAt: json['nextAvailableAt'] != null
          ? DateTime.parse(json['nextAvailableAt'] as String)
          : null,
    );
  }

  static SeatOverallStatus _parseStatus(String? status) {
    switch (status) {
      case 'moderate':
        return SeatOverallStatus.moderate;
      case 'limited':
        return SeatOverallStatus.limited;
      case 'unavailable':
        return SeatOverallStatus.unavailable;
      default:
        return SeatOverallStatus.plenty;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'cafeId': cafeId,
      'cafeName': cafeName,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'holdingSeats': holdingSeats,
      'reservedSeats': reservedSeats,
      'inUseSeats': inUseSeats,
      'overallStatus': overallStatus.name,
      'lastUpdated': lastUpdated.toIso8601String(),
      'nextAvailableAt': nextAvailableAt?.toIso8601String(),
      'timeSlot': timeSlot?.toIso8601String(),
    };
  }

  SeatAvailabilityEntity toEntity() => SeatAvailabilityEntity(
        cafeId: cafeId,
        cafeName: cafeName,
        totalSeats: totalSeats,
        availableSeats: availableSeats,
        holdingSeats: holdingSeats,
        reservedSeats: reservedSeats,
        inUseSeats: inUseSeats,
        overallStatus: overallStatus,
        lastUpdated: lastUpdated,
        nextAvailableAt: nextAvailableAt,
      );
}
