import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_location_entity.dart';

part 'player_location_model.freezed.dart';
part 'player_location_model.g.dart';

/// Response model for GET /api/userprofile/me/location.
///
/// When the user has never set a location, the server returns
/// `{latitude: null, longitude: null, updatedAt: null, source: null}`
/// together with `hasLocation: false`. We therefore keep the numeric /
/// timestamp fields nullable so the parser does not throw when `hasLocation`
/// is false.
@freezed
abstract class PlayerLocationModel with _$PlayerLocationModel {
  const factory PlayerLocationModel({
    double? latitude,
    double? longitude,
    String? updatedAt,
    /// 0 = Gps (device), 1 = Manual (map picker)
    int? source,
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