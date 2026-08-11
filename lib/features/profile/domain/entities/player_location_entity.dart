import 'package:equatable/equatable.dart';

/// Source of the player's last known location.
enum LocationSource { gps, manual }

/// Domain entity for the player's saved location.
///
/// When [hasLocation] is `false`, [latitude], [longitude], [updatedAt] and
/// [source] are all `null` — UI layers should check [hasLocation] before
/// reading any coordinate.
///
/// Backend mới trả thêm các trường địa chỉ đã resolve (`district`, `city`,
/// `country`, `displayName`) cùng cờ [hasResolvedName] để biết khi nào
/// reverse-geocode thành công. Khi vị trí chỉ là toạ độ thô, các trường này
/// sẽ là `null` và [hasResolvedName] = `false`.
class PlayerLocationEntity extends Equatable {
  final double? latitude;
  final double? longitude;
  final String? updatedAt;
  final LocationSource source;
  final bool hasLocation;

  /// Quận/Huyện (hoặc cấp hành chính tương đương) sau khi reverse-geocode.
  final String? district;

  /// Thành phố/Tỉnh sau khi reverse-geocode.
  final String? city;

  /// Quốc gia sau khi reverse-geocode.
  final String? country;

  /// Chuỗi địa chỉ đầy đủ do backend build sẵn (VD:
  /// "Phường Bến Thành, Thành phố Thủ Đức, Việt Nam"). Có thể `null` nếu
  /// reverse-geocode chưa chạy hoặc thất bại.
  final String? displayName;

  /// `true` khi backend đã trả về chuỗi [displayName] (kể cả khi
  /// [district]/[city]/[country] riêng lẻ bị `null`). UI dùng cờ này để
  /// quyết định hiển thị block "địa chỉ" hay chỉ hiện toạ độ thô.
  final bool hasResolvedName;

  const PlayerLocationEntity({
    this.latitude,
    this.longitude,
    this.updatedAt,
    this.source = LocationSource.gps,
    required this.hasLocation,
    this.district,
    this.city,
    this.country,
    this.displayName,
    this.hasResolvedName = false,
  });

  /// Chuỗi hiển thị gọn cho UI — ưu tiên [displayName] nếu backend đã
  /// resolve, ngược lại ghép từ district/city/country, fallback về
  /// toạ độ.
  String get resolvedLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!;
    }
    final parts = <String>[
      if (district != null && district!.trim().isNotEmpty) district!,
      if (city != null && city!.trim().isNotEmpty) city!,
      if (country != null && country!.trim().isNotEmpty) country!,
    ];
    if (parts.isNotEmpty) return parts.join(', ');
    if (latitude != null && longitude != null) {
      return '${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}';
    }
    return '';
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        updatedAt,
        source,
        hasLocation,
        district,
        city,
        country,
        displayName,
        hasResolvedName,
      ];
}
