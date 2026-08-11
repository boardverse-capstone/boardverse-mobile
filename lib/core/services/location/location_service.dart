import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Kết quả đọc vị trí — chỉ chứa đúng 2 toạ độ, không kèm metadata
/// thừa (timestamp, accuracy,…) vì UI chỉ cần lat/lng.
class DeviceLocation {
  final double latitude;
  final double longitude;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
  });
}

/// Phân loại lỗi GPS — UI sẽ dịch sang toast tiếng Việt tương ứng.
/// Tránh để `LocationServiceDisabledException` / `PermissionDeniedException`
/// của `geolocator` lọt ra ngoài UI (vì chúng có message tiếng Anh
/// mặc định).
enum LocationFailureKind {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationFailure implements Exception {
  final LocationFailureKind kind;
  const LocationFailure(this.kind);

  /// Thông báo tiếng Việt hiển thị cho user.
  String get userMessage {
    switch (kind) {
      case LocationFailureKind.serviceDisabled:
        return 'Dịch vụ vị trí (GPS) đang tắt. Hãy bật Location trong cài đặt thiết bị.';
      case LocationFailureKind.permissionDenied:
        return 'Bạn đã từ chối cấp quyền vị trí. Hãy vào Cài đặt → Quyền → Vị trí để bật lại cho BoardVerse.';
      case LocationFailureKind.permissionDeniedForever:
        return 'Quyền vị trí đã bị chặn vĩnh viễn. Hãy vào Cài đặt → Ứng dụng → BoardVerse → Quyền để bật lại.';
      case LocationFailureKind.timeout:
        return 'Không lấy được vị trí (timeout). Vui lòng thử lại ngoài trời hoặc nơi sóng GPS tốt hơn.';
      case LocationFailureKind.unknown:
        return 'Không thể đọc vị trí hiện tại. Vui lòng thử lại.';
    }
  }
}

/// Thin wrapper quanh `geolocator` — đóng gói toàn bộ flow permission +
/// service-check + read-position, đ� error thành [LocationFailure] có
/// message tiếng Việt.
///
/// Trước đây home_page hardcode `(10.7769, 106.7008)` (Quận 1) — đây
/// là nguyên nhân backend trả reverse-geocode sai. Service này thay
/// thế luồng đó.
class LocationService {
  const LocationService();

  /// Đọc vị trí hiện tại của thiết bị.
  ///
  /// Flow:
  /// 1. Check service GPS có bật không → [LocationFailureKind.serviceDisabled].
  /// 2. Xin permission `whenInUse` (chỉ dùng khi app đang mở, không
  ///    xin quyền `always` — vì profile chỉ cần toạ độ lúc player
  ///    chủ động bấm nút).
  /// 3. Gọi `getCurrentPosition` với timeout 10s. Nếu timeout /
  ///    platform error → wrap thành [LocationFailure] tương ứng.
  Future<DeviceLocation> getCurrentLocation() async {
    // 1. Service phải bật (GPS / network location).
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    }

    // 2. Permission.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationFailure(LocationFailureKind.permissionDenied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureKind.permissionDeniedForever,
      );
    }

    // 3. Đọc toạ độ. Timeout 10s — fail nhanh để user không phải
    //    ch� quá lâu khi GPS kém.
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on TimeoutException {
      throw const LocationFailure(LocationFailureKind.timeout);
    } on LocationServiceDisabledException {
      throw const LocationFailure(LocationFailureKind.serviceDisabled);
    } catch (_) {
      throw const LocationFailure(LocationFailureKind.unknown);
    }
  }
}
