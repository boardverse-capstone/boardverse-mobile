/// Format khoảng cách hiển thị trên UI từ giá trị meters trả về từ backend.
///
/// **Bối cảnh:** Các endpoint trả về danh sách quán (`GET /api/cafes`,
/// `/nearby`, `/nearby/me`, `/search`) đều trả field `distanceMeters`
/// (PostGIS `geography`, đơn vị meters). UI cần hiển thị thân thiện với
/// user Việt Nam (km khi ≥ 1 km, m khi < 1 km).
///
/// **Cách dùng:** Truyền `distanceMeters` từ `CafeEntity` (hoặc bất kỳ
/// model nào có field meters) — KHÔNG cần tự chia 1000 ở call site.
///
/// ```dart
/// DistanceFormatter.format(cafe.distanceMeters); // → '12.3 km'
/// DistanceFormatter.format(450);                  // → '450 m'
/// DistanceFormatter.format(null);                // → '—'
/// ```
///
/// Docs: `.agents/docs/apis_docs/cafe.md` §Ma trận bảo mật (field `distanceMeters`).
class DistanceFormatter {
  DistanceFormatter._();

  /// Format khoảng cách meters → string hiển thị trên UI.
  ///
  /// Quy tắc output:
  /// - `null` / `NaN` / `Infinity` / `< 0` → `'—'` (placeholder không xác định)
  /// - `< 1000m`  → `'450 m'` (làm tròn 0 chữ số thập phân)
  /// - `≥ 1000m`  → `'12.3 km'` (1 chữ số thập phân)
  ///
  /// Lưu ý: API endpoint `GET /api/cafes/{id}` trả `CafeDetailDto.distanceKm`
  /// (đã ở km). Trường hợp đó KHÔNG dùng hàm này — giữ nguyên giá trị từ
  /// `CafeDetailEntity.distanceKm` (vì backend đã tính và trả sẵn).
  static String format(double? meters) {
    if (meters == null || meters.isNaN || meters.isInfinite || meters < 0) {
      return '—';
    }
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}