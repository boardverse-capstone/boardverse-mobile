import 'package:flutter/material.dart';

/// Kết quả validation cho scheduled start time so với `now`.
///
/// - [StartTimeValidation.ok] — đủ buffer để backend chấp nhận
///   (`recruitmentDeadline - now >= minBufferMinutes`, mặc định 60p).
/// - [StartTimeValidation.tooSoon] — start time quá gần hiện tại
///   (buffer < 60 phút). Backend sẽ trả 400 với cùng lý do.
///   UI nên block gửi request và hiển thị inline warning thân thiện.
enum StartTimeValidation {
  ok,
  tooSoon,
}

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

  /// Tính default start time "an toàn" cho [selectedDate] — luôn nằm
  /// trong tương lai với buffer ≥ `leadTime + safetyBuffer` so với `now`.
  ///
  /// Tránh bug UX: user mở page sau 9h sáng mà default vẫn là 09:00 →
  /// backend trả 400 "thời gian tuyển người chỉ còn -X phút" → UI flash
  /// lỗi ~1s trước khi user kịp chỉnh tay.
  ///
  /// **Strategy**:
  /// - Ngày đã chọn KHÔNG PHẢI hôm nay → 09:00 (morning) — khung giờ
  ///   board game phổ biến, không bị ảnh hưởng bởi `now`.
  /// - Ngày đã chọn LÀ hôm nay:
  ///   - `earliest = now + leadTime + safetyBuffer` (mặc định 3h đệm).
  ///     Buffer 3h đảm bảo rơi vào `BufferWarningLevel.none` (≥ 120p)
  ///     theo ngưỡng ở `reservation_quote_entity.dart`.
  ///   - Làm tròn lên giờ chẵn kế tiếp (dễ đọc cho user).
  ///   - Clamp về [0, 22] — tránh default vượt quá 22:00 (giờ đóng cửa
  ///     cuối ngày của quán).
  ///
  /// Edge case: nếu `now > 22:00`, earliest sẽ clamp về 22:00 (đã nằm
  /// trong quá khứ). Caller nên kết hợp [hasValidLeadTime] để validate
  /// và show inline warning cho user chọn ngày khác.
  static TimeOfDay computeSmartDefaultStartTime(
    DateTime selectedDate, {
    Duration leadTime = const Duration(minutes: 20),
    Duration safetyBuffer = const Duration(hours: 3),
  }) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    if (!isToday) {
      // Ngày tương lai → 9 AM là khung giờ board game phổ biến.
      return const TimeOfDay(hour: 9, minute: 0);
    }

    // Hôm nay: chọn giờ trong tương lai.
    final earliest = now.add(leadTime + safetyBuffer);

    // Làm tròn lên giờ chẵn kế tiếp. Nếu earliest.minute > 0 (vd:
    // 21:37 → 22:00) thì lấy hour + 1.
    var hour = earliest.hour;
    if (earliest.minute > 0) hour += 1;

    // Wrap nếu vượt 24h (vd: now = 23:30 → earliest = 02:30 → 3:00).
    // Trả về next-day early-morning. Caller (UI) có thể hint user nên
    // chọn ngày mai.
    if (hour >= 24) hour -= 24;

    // Clamp về [0, 22] để tránh default vượt giờ đóng cửa quán.
    hour = hour.clamp(0, 22);

    return TimeOfDay(hour: hour, minute: 0);
  }

  /// Default end time dựa trên [startTime] — mặc định session kéo dài
  /// 4 tiếng (chuẩn board game).
  ///
  /// Wrap around 24h nếu start + 4h vượt ngày (vd: start = 22:00 →
  /// end = 02:00 next day, overnight). Overnight là hợp lệ theo
  /// BR-NEW-15 nên không cần lo.
  static TimeOfDay computeDefaultEndTime(TimeOfDay startTime) {
    final endMinutes = (startTime.hour + 4) * 60 + startTime.minute;
    final hour = (endMinutes ~/ 60) % 24;
    return TimeOfDay(hour: hour, minute: endMinutes % 60);
  }

  /// Validate xem scheduled start time có đủ buffer (`recruitmentDeadline -
  /// now >= minBuffer`) để backend chấp nhận không.
  ///
  /// Công thức: `scheduled = selectedDate + startTime`, `deadline =
  /// scheduled - leadTime`, `buffer = deadline - now`. Backend yêu cầu
  /// `buffer >= 60 phút` (xem swagger §RecruitmentRule và error message
  /// "Thời gian để tuyển người ... cần ít nhất 60 phút").
  ///
  /// Trả về [StartTimeValidation.ok] nếu buffer đủ, [StartTimeValidation.tooSoon]
  /// nếu không. Function PURE, không gọi API.
  ///
  /// [now] chỉ để test (mặc định `DateTime.now()`). Caller production
  /// không cần truyền.
/// Validate xem scheduled start time có đủ buffer (`scheduledStartTime -
/// now >= minBuffer`) để cho phép đặt lobby hay không.
///
/// **Lưu ý quan trọng (BR §XXI-B.6, cập nhật 2026-10-01):**
/// Buffer ở đây là `scheduledStartTime - now` (KHÔNG trừ `leadTime`).
/// Trước đây dùng `recruitmentDeadline - now >= 60p` (= 1h20p = leadTime
/// 20p + minBuffer 60p), quá strict vì:
///
///   - Ngăn cản nhóm bạn đi chung đặt lobby sát giờ (vd: nhóm 3 người
///     hẹn nhau lúc 20:00, lúc 19:45 mới mở app đặt → buffer = 15p).
///   - UI semantic đã đổi sang `scheduledTime - now` (xem
///     `_bufferMinutes` ở `lobby_config_page.dart`), validation phải
///     đồng bộ để tránh "UI thông báo OK nhưng gửi lên bị reject".
///
/// Ngưỡng mặc định 30 phút: đủ để
///   - Backend xử lý recruitment logic.
///   - Bạn bè trong group nhận invite + di chuyển đến quán (quán gần).
///
/// Trả về [StartTimeValidation.ok] nếu buffer đủ, [StartTimeValidation.tooSoon]
/// nếu không. Function PURE, không gọi API.
///
/// [now] chỉ để test (mặc định `DateTime.now()`). Caller production
/// không cần truyền.
static StartTimeValidation validateStartTime({
    required DateTime selectedDate,
    required TimeOfDay? startTime,
    Duration minBuffer = const Duration(minutes: 30),
    DateTime? now,
  }) {
    if (startTime == null) return StartTimeValidation.tooSoon;
    final scheduled = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      startTime.hour,
      startTime.minute,
    );
    final buffer = scheduled.difference(now ?? DateTime.now());
    return buffer >= minBuffer
        ? StartTimeValidation.ok
        : StartTimeValidation.tooSoon;
  }
}

/// Kết quả validation cho end time. Xem [LobbyTimeCalculator.validateEndTime].
enum LobbyEndTimeValidation {
  /// End time hợp lệ (cùng ngày hoặc overnight).
  accept,

  /// End time == Start time — backend reject với 400 `PreferredTimesMustDiffer`.
  equal,
}
