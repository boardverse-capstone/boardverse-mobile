import 'package:equatable/equatable.dart';

/// Source of the player's last known location.
enum LocationSource { gps, manual }

/// Domain entity for the player's saved location.
///
/// When [hasLocation] is `false`, [latitude], [longitude], [updatedAt] and
/// [source] are all `null` — UI layers should check [hasLocation] before
/// reading any coordinate.
class PlayerLocationEntity extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? updatedAt;
  final LocationSource source;
  final bool hasLocation;

  const PlayerLocationEntity({
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.source = LocationSource.gps,
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