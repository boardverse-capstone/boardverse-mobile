import 'package:equatable/equatable.dart';

/// Source of the player's last known location.
enum LocationSource { gps, manual }

/// Domain entity for the player's saved location.
class PlayerLocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final String? updatedAt;
  final LocationSource source;
  final bool hasLocation;

  const PlayerLocationEntity({
    required this.latitude,
    required this.longitude,
    this.updatedAt,
    required this.source,
    required this.hasLocation,
  });

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        updatedAt,
        source,
        hasLocation,
      ];
}
