import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_location_entity.dart';

part 'player_location_model.freezed.dart';
part 'player_location_model.g.dart';

/// Response model for GET /api/userprofile/me/location.
@freezed
abstract class PlayerLocationModel with _$PlayerLocationModel {
  const factory PlayerLocationModel({
    required double latitude,
    required double longitude,
    required String updatedAt,
    /// 0 = Gps (device), 1 = Manual (map picker)
    required int source,
    required bool hasLocation,
  }) = _PlayerLocationModel;

  factory PlayerLocationModel.fromJson(Map<String, dynamic> json) =>
      _$PlayerLocationModelFromJson(json);
}

extension PlayerLocationModelX on PlayerLocationModel {
  PlayerLocationEntity toEntity() => PlayerLocationEntity(
        latitude: latitude,
        longitude: longitude,
        updatedAt: updatedAt,
        source: source == 0 ? LocationSource.gps : LocationSource.manual,
        hasLocation: hasLocation,
      );
}
