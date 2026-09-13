import 'package:flutter/material.dart';

/// Pure helper functions cho việc tính toán overnight / cross-midnight
/// reservation time. Tách riêng để có thể unit test mà không cần phụ
/// thuộc vào widget page phức tạp.
///
/// **Bối cảnh nghiệp vụ:** Backend hỗ trợ overnight rule BR-NEW-15
/// (`.agents/docs/apis_docs/reservation.md` § `preferredEndTime`):
///
///   - `endTime > startTime` → scheduledEndTime cùng ngày với playDate.
///   - `endTime < startTime` → scheduledEndTime = playDate + 1 ngày (overnight).
///   - `endTime == startTime` → 400 `PreferredTimesMustDiffer`.
///
/// Mobile UI phải cho phép user chọn bất kỳ end time nào (trừ = start)
/// và hiển thị rõ overnight cho user biết.
///
/// Các function ở đây là PURE — chỉ nhận TimeOfDay / DateTime, không
/// đụng widget tree, cubit, hay side-effects.
class LobbyTimeCalculator {
  LobbyTimeCalculator._();

  /// Convert `TimeOfDay` thành số phút tính từ 00:00.
  /// Dùng để so sánh 2 TimeOfDay: phút nào lớn hơn → muộn hơn trong ngày.
  ///
  /// Lưu ý: KHÔNG dùng giá trị này để tính duration của session qua đêm
  /// (vd: 23:00 → 05:00) — duration phải cộng thêm 24h nếu cross midnight,
  /// xem [sessionDurationMinutes].
  static int timeOfDayToMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  /// `true` khi session kéo dài qua đêm, tức `endTime < startTime` tính
  /// theo phút. Trả về `false` nếu một trong hai time null hoặc khi
  /// `endTime > startTime` (same-day) hoặc `endTime == startTime` (không hợp lệ).
  static bool isOvernight(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null || endTime == null) return false;
    return timeOfDayToMinutes(endTime) < timeOfDayToMinutes(startTime);
  }

  /// Tính tổng thời lượng session (phút) — xử lý overnight tự động:
  /// - Same-day (end > start): `end - start`.
  /// - Overnight (end < start): `(24h - start) + end`.
  /// - Equal: trả về 0 (backend sẽ reject, không phải duration hợp lệ).
  ///
  /// Constraint: `0 ≤ duration ≤ 12h` (BR-RES-07 §G7/G8 fix).
  static int sessionDurationMinutes(TimeOfDay? startTime, TimeOfDay? endTime) {
    if (startTime == null || endTime == null) return 0;
    final start = timeOfDayToMinutes(startTime);
    final end = timeOfDayToMinutes(endTime);
    if (end >= start) return end - start;
    // Overnight: (24*60 - start) + end
    return (24 * 60 - start) + end;
  }

  /// Trả về ngày kết thúc thực tế của session, tự động cộng 1 ngày nếu
  /// overnight. Dùng cho UI hiển thị "sẽ kết thúc vào X ngày".
  ///
  /// VD: playDate = 2026-09-08, start = 23:00, end = 05:00 →
  ///     `actualEndDate = 2026-09-09`.
  static DateTime actualEndDate({
    required DateTime playDate,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (isOvernight(startTime, endTime)) {
      return DateTime(playDate.year, playDate.month, playDate.day + 1);
    }
    return DateTime(playDate.year, playDate.month, playDate.day);
  }

  /// Kết quả validation khi user chọn end time.
  ///
  /// - [LobbyEndTimeValidation.accept] — chấp nhận (end > start hoặc overnight).
  /// - [LobbyEndTimeValidation.equal] — bằng start, backend sẽ trả 400.
  static LobbyEndTimeValidation validateEndTime(
    TimeOfDay startTime,
    TimeOfDay endTime,
  ) {
    final start = timeOfDayToMinutes(startTime);
    final end = timeOfDayToMinutes(endTime);
    if (end == start) return LobbyEndTimeValidation.equal;
    return LobbyEndTimeValidation.accept;
  }
}

/// Kết quả validation cho end time. Xem [LobbyTimeCalculator.validateEndTime].
enum LobbyEndTimeValidation {
  /// End time hợp lệ (cùng ngày hoặc overnight).
  accept,

  /// End time == Start time — backend reject với 400 `PreferredTimesMustDiffer`.
  equal,
}
