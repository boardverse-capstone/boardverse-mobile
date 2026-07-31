import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/player_location_entity.dart';

part 'player_location_model.freezed.dart';

int? _locationSourceFromJson(Object? value) {
  return switch (value) {
    null => null,
    num number => number.toInt(),
    String name when name.toLowerCase() == 'gps' => 0,
    String name when name.toLowerCase() == 'manual' => 1,
    _ => throw FormatException('Unsupported location source: $value'),
  };
}

/// Response model for GET /api/userprofile/me/location.
///
/// When the user has never set a location, the server returns
/// `{latitude: null, longitude: null, updatedAt: null, source: null}`
/// together with `hasLocation: false`. We therefore keep the numeric /
/// timestamp fields nullable so the parser does not throw when `hasLocation`
/// is false.
///
/// `fromJson` được viết tay (không dùng generated) để có thể nhìn thấy
/// cả payload khi suy ra `hasLocation` — `@JsonKey(fromJson:)` của
/// `json_serializable` chỉ nhận `value` của field, không có context json.
@freezed
abstract class PlayerLocationModel with _$PlayerLocationModel {
  const factory PlayerLocationModel({
    double? latitude,
    double? longitude,
    String? updatedAt,

    /// 0 = Gps (device), 1 = Manual (map picker). The API may serialize
    /// this enum as either a number or its string name.
    @JsonKey(fromJson: _locationSourceFromJson) int? source,

    /// `true` khi `latitude` và `longitude` đều có giá trị. Nếu server
    /// trả `hasLocation` rõ ràng thì dùng nó, ngược lại suy ra từ lat/lng.
    required bool hasLocation,
  }) = _PlayerLocationModel;

  /// Custom parser vì `json_serializable`'s `@JsonKey(fromJson:)` chỉ có
  /// quyền truy cập vào `value` của field đó, không có cả payload. Ở đây
  /// ta cần nhìn cả `latitude`/`longitude` để suy ra `hasLocation` khi server
  /// bỏ sót field này.
  factory PlayerLocationModel.fromJson(Map<String, dynamic> json) {
    final rawHas = json['hasLocation'];
    final hasFromServer = rawHas is bool ? rawHas : null;
    final lat = json['latitude'];
    final lng = json['longitude'];
    final hasLocation =
        hasFromServer ?? (lat != null && lng != null);

    return PlayerLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] as String?,
      source: _locationSourceFromJson(json['source']),
      hasLocation: hasLocation,
    );
  }
}

extension PlayerLocationModelX on PlayerLocationModel {
  PlayerLocationEntity toEntity() => PlayerLocationEntity(
    latitude: latitude,
    longitude: longitude,
    updatedAt: updatedAt,
    source: source == 0 ? LocationSource.gps : LocationSource.manual,
    hasLocation: hasLocation,
  );

  /// `toJson` thủ công — thay thế bản generated đã bị xoá khi custom hoá
  /// `fromJson`. Trước đó json_serializable + freezed tự sinh; giờ test
  /// vẫn cần gọi `model.toJson()` cho round-trip.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'updatedAt': updatedAt,
        'source': source,
        'hasLocation': hasLocation,
      };
}
