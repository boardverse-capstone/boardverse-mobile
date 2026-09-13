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
}
