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

bool? _boolFromJson(Object? value) {
  if (value is bool) return value;
  if (value == null) return null;
  return null;
}

/// Response model for GET /api/userprofile/me/location.
///
/// Khi user chưa set vị trí, server trả
/// `{latitude: null, longitude: null, updatedAt: null, source: null}`
/// cùng `hasLocation: false`. Khi server đã reverse-geocode thành công sẽ
/// trả thêm `district`, `city`, `country`, `displayName` + cờ
/// `hasResolvedName` — toàn bộ đều nullable để parser không throw.
///
/// `fromJson` được viết tay (không dùng generated) để có thể nhìn thấy
/// cả payload khi suy ra `hasLocation` / `hasResolvedName`.
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

    /// Địa ch� đã reverse-geocode (optional — có thể `null` nếu server
    /// chưa build xong hoặc thất bại).
    String? district,
    String? city,
    String? country,
    String? displayName,

    /// `true` khi [displayName] đã được build. Nếu server trả cờ này thì
    /// dùng, ngược lại suy ra từ `displayName != null`.
    @JsonKey(fromJson: _boolFromJson) bool? hasResolvedName,
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
    final hasLocation = hasFromServer ?? (lat != null && lng != null);

    final rawResolved = json['hasResolvedName'];
    final resolvedFromServer = rawResolved is bool ? rawResolved : null;
    final displayName = json['displayName'] as String?;
    final hasResolvedName =
        resolvedFromServer ?? (displayName != null && displayName.isNotEmpty);

    return PlayerLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      updatedAt: json['updatedAt'] as String?,
      source: _locationSourceFromJson(json['source']),
      hasLocation: hasLocation,
      district: json['district'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      displayName: displayName,
      hasResolvedName: hasResolvedName,
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
    district: district,
    city: city,
    country: country,
    displayName: displayName,
    hasResolvedName: hasResolvedName ?? false,
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
        'district': district,
        'city': city,
        'country': country,
        'displayName': displayName,
        'hasResolvedName': hasResolvedName,
      };
}
