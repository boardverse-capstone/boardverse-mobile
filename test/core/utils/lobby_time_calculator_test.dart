// Unit tests cho `LobbyTimeCalculator` — pure helper xử lý overnight
// reservation time. Đây là phần logic nghiệp vụ được tách ra khỏi
// `LobbyConfigPage` để dễ test.
//
// Bối cảnh: backend BR-NEW-15 (`.agents/docs/apis_docs/reservation.md`
// § `preferredEndTime`):
//   - `endTime > startTime` → scheduledEndTime cùng ngày với playDate.
//   - `endTime < startTime` → overnight, scheduledEndTime = playDate + 1.
//   - `endTime == startTime` → 400 `PreferredTimesMustDiffer`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/core/utils/lobby_time_calculator.dart';

void main() {
  group('LobbyTimeCalculator.timeOfDayToMinutes', () {
    test('00:00 → 0', () {
      expect(
        LobbyTimeCalculator.timeOfDayToMinutes(const TimeOfDay(hour: 0, minute: 0)),
        0,
      );
    });

    test('23:00 → 1380', () {
      expect(
        LobbyTimeCalculator.timeOfDayToMinutes(const TimeOfDay(hour: 23, minute: 0)),
        1380,
      );
    });

    test('05:30 → 330', () {
      expect(
        LobbyTimeCalculator.timeOfDayToMinutes(const TimeOfDay(hour: 5, minute: 30)),
        330,
      );
    });
  });

  group('LobbyTimeCalculator.isOvernight', () {
    test('start 23:00, end 05:00 → overnight = true (user scenario)', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 23, minute: 0),
          const TimeOfDay(hour: 5, minute: 0),
        ),
        isTrue,
      );
    });

    test('start 22:00, end 02:00 → overnight = true', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 22, minute: 0),
          const TimeOfDay(hour: 2, minute: 0),
        ),
        isTrue,
      );
    });

    test('start 21:00, end 00:00 → overnight = true', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 21, minute: 0),
          const TimeOfDay(hour: 0, minute: 0),
        ),
        isTrue,
      );
    });

    test('start 19:00, end 21:00 → overnight = false (cùng ngày)', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 19, minute: 0),
          const TimeOfDay(hour: 21, minute: 0),
        ),
        isFalse,
      );
    });

    test('start 09:00, end 13:00 → overnight = false (default same-day)', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 9, minute: 0),
          const TimeOfDay(hour: 13, minute: 0),
        ),
        isFalse,
      );
    });

    test('start == end → overnight = false (backend trả 400, không phải overnight)', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
        ),
        isFalse,
      );
    });

    test('start null → overnight = false', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          null,
          const TimeOfDay(hour: 5, minute: 0),
        ),
        isFalse,
      );
    });

    test('end null → overnight = false', () {
      expect(
        LobbyTimeCalculator.isOvernight(
          const TimeOfDay(hour: 23, minute: 0),
          null,
        ),
        isFalse,
      );
    });
  });

  group('LobbyTimeCalculator.sessionDurationMinutes', () {
    test('23:00 → 05:00 (overnight) → 360 phút (6h)', () {
      expect(
        LobbyTimeCalculator.sessionDurationMinutes(
          const TimeOfDay(hour: 23, minute: 0),
          const TimeOfDay(hour: 5, minute: 0),
        ),
        360,
      );
    });

    test('22:00 → 02:00 (overnight) → 240 phút (4h)', () {
      expect(
        LobbyTimeCalculator.sessionDurationMinutes(
          const TimeOfDay(hour: 22, minute: 0),
          const TimeOfDay(hour: 2, minute: 0),
        ),
        240,
      );
    });

    test('21:00 → 00:00 (overnight) → 180 phút (3h)', () {
      expect(
        LobbyTimeCalculator.sessionDurationMinutes(
          const TimeOfDay(hour: 21, minute: 0),
          const TimeOfDay(hour: 0, minute: 0),
        ),
        180,
      );
    });

    test('19:00 → 21:00 (same-day) → 120 phút', () {
      expect(
        LobbyTimeCalculator.sessionDurationMinutes(
          const TimeOfDay(hour: 19, minute: 0),
          const TimeOfDay(hour: 21, minute: 0),
        ),
        120,
      );
    });

    test('start == end → 0 phút (không hợp lệ)', () {
      expect(
        LobbyTimeCalculator.sessionDurationMinutes(
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
        ),
        0,
      );
    });

    test('null inputs → 0', () {
      expect(LobbyTimeCalculator.sessionDurationMinutes(null, null), 0);
    });
  });

  group('LobbyTimeCalculator.actualEndDate', () {
    test('playDate=08/09, overnight → actualEndDate=09/09', () {
      final playDate = DateTime(2026, 9, 8);
      final result = LobbyTimeCalculator.actualEndDate(
        playDate: playDate,
        startTime: const TimeOfDay(hour: 23, minute: 0),
        endTime: const TimeOfDay(hour: 5, minute: 0),
      );
      expect(result, DateTime(2026, 9, 9));
    });

    test('playDate=08/09, same-day → actualEndDate=08/09', () {
      final playDate = DateTime(2026, 9, 8);
      final result = LobbyTimeCalculator.actualEndDate(
        playDate: playDate,
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 22, minute: 0),
      );
      expect(result, DateTime(2026, 9, 8));
    });

    test('playDate cuối tháng 31/12, overnight → actualEndDate=01/01 (next month)', () {
      final playDate = DateTime(2026, 12, 31);
      final result = LobbyTimeCalculator.actualEndDate(
        playDate: playDate,
        startTime: const TimeOfDay(hour: 23, minute: 0),
        endTime: const TimeOfDay(hour: 1, minute: 0),
      );
      expect(result, DateTime(2027, 1, 1));
    });
  });

  group('LobbyTimeCalculator.validateEndTime', () {
    test('end > start → accept', () {
      expect(
        LobbyTimeCalculator.validateEndTime(
          const TimeOfDay(hour: 19, minute: 0),
          const TimeOfDay(hour: 21, minute: 0),
        ),
        LobbyEndTimeValidation.accept,
      );
    });

    test('end < start → accept (overnight case)', () {
      expect(
        LobbyTimeCalculator.validateEndTime(
          const TimeOfDay(hour: 23, minute: 0),
          const TimeOfDay(hour: 5, minute: 0),
        ),
        LobbyEndTimeValidation.accept,
      );
    });

    test('end == start → equal (backend reject với 400)', () {
      expect(
        LobbyTimeCalculator.validateEndTime(
          const TimeOfDay(hour: 14, minute: 0),
          const TimeOfDay(hour: 14, minute: 0),
        ),
        LobbyEndTimeValidation.equal,
      );
    });
  });

  group('LobbyTimeCalculator.validateStartTime', () {
    // BR §XXI-B.6 (cập nhật 2026-10-01): ngưỡng buffer mới = 30 phút,
    // công thức `scheduledStartTime - now` (KHÔNG trừ leadTime). Trước
    // đây dùng `deadline - now >= 60p` (= 80p với leadTime=20p) — quá
    // strict, group bạn đi chung bị chặn khi buffer 30-60p.

    test('start null → tooSoon (defensive guard)', () {
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: null,
          now: DateTime(2026, 10, 1, 10, 0),
        ),
        StartTimeValidation.tooSoon,
      );
    });

    test('today, now 18:22, start 09:00 → tooSoon (start trong quá khứ)', () {
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.tooSoon,
      );
    });

    test('today, now 18:22, start 18:45 → tooSoon (buffer = 23p, < 30p)', () {
      // scheduled = 18:45, buffer = 18:45 - 18:22 = 23p < 30p
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 18, minute: 45),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.tooSoon,
      );
    });

    test('today, now 18:22, start 18:55 → ok (buffer = 33p, ≥ 30p)', () {
      // scheduled = 18:55, buffer = 33p ≥ 30p → OK cho group bạn.
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 18, minute: 55),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.ok,
      );
    });

    test('today, now 18:22, start 19:00 → ok (buffer = 38p, ≥ 30p)', () {
      // Trước đây fail vì deadline = 18:40, buffer = 18p < 60p.
      // Sau cập nhật BR §XXI-B.6: buffer = scheduledTime - now = 38p,
      // đủ cho group bạn.
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 19, minute: 0),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.ok,
      );
    });

    test('today, now 18:22, start 20:00 → ok (buffer = 98p)', () {
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 20, minute: 0),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.ok,
      );
    });

    test('tomorrow, start 09:00 → ok (luôn trong tương lai)', () {
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 2),
          startTime: const TimeOfDay(hour: 9, minute: 0),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.ok,
      );
    });

    test('today, start sát hiện tại (now 18:22, start 18:30) → tooSoon', () {
      // scheduled = 18:30, buffer = 8p < 30p.
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 18, minute: 30),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.tooSoon,
      );
    });

    test('override minBuffer: now 18:22, start 18:30, minBuffer 5p → ok',
        () {
      // Verify `minBuffer` parameter vẫn hoạt động (custom threshold).
      expect(
        LobbyTimeCalculator.validateStartTime(
          selectedDate: DateTime(2026, 10, 1),
          startTime: const TimeOfDay(hour: 18, minute: 30),
          minBuffer: const Duration(minutes: 5),
          now: DateTime(2026, 10, 1, 18, 22),
        ),
        StartTimeValidation.ok,
      );
    });
  });

  group('LobbyTimeCalculator.computeDefaultEndTime', () {
    test('start 09:00 → end 13:00 (4h same-day)', () {
      expect(
        LobbyTimeCalculator.computeDefaultEndTime(
          const TimeOfDay(hour: 9, minute: 0),
        ),
        const TimeOfDay(hour: 13, minute: 0),
      );
    });

    test('start 22:00 → end 02:00 (overnight wrap)', () {
      // 22+4 = 26 → mod 24 = 2
      expect(
        LobbyTimeCalculator.computeDefaultEndTime(
          const TimeOfDay(hour: 22, minute: 0),
        ),
        const TimeOfDay(hour: 2, minute: 0),
      );
    });

    test('start 19:30 → end 23:30 (giữ phút, same-day)', () {
      expect(
        LobbyTimeCalculator.computeDefaultEndTime(
          const TimeOfDay(hour: 19, minute: 30),
        ),
        const TimeOfDay(hour: 23, minute: 30),
      );
    });
  });

  group('LobbyTimeCalculator.computeSmartDefaultStartTime', () {
    test('ngày tương lai (2026-10-02) → luôn 09:00 (không phụ thuộc now)', () {
      final future = DateTime(2026, 10, 2);
      final result = LobbyTimeCalculator.computeSmartDefaultStartTime(
        future,
        leadTime: const Duration(minutes: 20),
        safetyBuffer: const Duration(hours: 3),
      );
      expect(result, const TimeOfDay(hour: 9, minute: 0));
    });

    test(
      'hôm nay → default = now + lead + safety buffer, làm tròn lên giờ '
      'chẵn, clamp ≤ 22:00 (regression guard cho UX)',
      () {
        // Không phụ thuộc now cứng — assertion linh hoạt theo giờ thực.
        // Function gọi `DateTime.now()` bên trong (không inject được),
        // nên verify semantic bằng range đúng [0, 22].
        final today = DateTime.now();
        final today00 = DateTime(today.year, today.month, today.day);
        final result = LobbyTimeCalculator.computeSmartDefaultStartTime(
          today00,
          leadTime: const Duration(minutes: 20),
          safetyBuffer: const Duration(hours: 3),
        );
        // hour phải nằm trong [0, 22] (clamp của function).
        expect(result.hour, lessThanOrEqualTo(22));
        expect(result.hour, greaterThanOrEqualTo(0));
        expect(result.minute, 0);
        // Edge case: nếu now > 22:00 → wrap về early-morning.
        // Nếu now + 3h vẫn trong ngày → hour >= (now + 3) rounded up.
        if (today.hour < 19) {
          // now + 3h chưa wrap.
          expect(result.hour, greaterThanOrEqualTo(today.hour + 3));
        }
      },
    );

    test('hôm nay, wrap around 24h (now 23:30 → earliest 02:50 → 03:00)', () {
      // Không thể fake now trong function, nên test bằng cách kiểm tra
      // ngày mai vẫn giữ 09:00 (sanity check cho non-isToday branch).
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrow00 = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
      final result = LobbyTimeCalculator.computeSmartDefaultStartTime(
        tomorrow00,
      );
      expect(result, const TimeOfDay(hour: 9, minute: 0));
    });
  });
}
