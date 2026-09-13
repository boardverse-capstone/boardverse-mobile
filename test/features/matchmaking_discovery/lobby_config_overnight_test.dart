// Widget tests cho `LobbyConfigTabThoiGian` và overnight reservation flow.
//
// Bối cảnh: trước Sep 2026 UI ép `endTime > startTime` (cùng ngày) — user
// không thể đặt lobby qua đêm 23:00 → 05:00 dù backend hỗ trợ (BR-NEW-15:
// `preferredEndTime < preferredStartTime` → scheduledEndTime = playDate + 1).
//
// Test này verify UI giờ:
//   1. Hiển thị banner "Lobby kéo dài qua đêm" khi `endCrossesMidnight`.
//   2. Hiển thị badge "+1 ngày" trên End Time row.
//   3. KHÔNG render banner/badge khi cùng ngày (regression check).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/matchmaking_discovery/presentation/widgets/lobby_config/tab_thoi_gian.dart';

String _fmtDate(DateTime d) {
  const weekdays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final wd = weekdays[d.weekday % 7];
  return '$wd, ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

String _fmtTime(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _fmtBuffer(int minutes) => '${minutes}p';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

LobbyConfigTabThoiGian _buildTab({
  DateTime? selectedDate,
  TimeOfDay? startTime,
  TimeOfDay? endTime,
  required bool endCrossesMidnight,
}) {
  final now = DateTime.now();
  return LobbyConfigTabThoiGian(
    selectedDate: selectedDate ?? DateTime(now.year, now.month, now.day),
    preferredStartTime: startTime,
    preferredEndTime: endTime,
    endCrossesMidnight: endCrossesMidnight,
    onDateSelected: (_) {},
    onOpenDatePicker: () {},
    onPreferredTimeTap: () {},
    onPreferredEndTimeTap: () {},
    formatDate: _fmtDate,
    formatTime: _fmtTime,
    formatBuffer: _fmtBuffer,
    bufferMinutes: 60,
    isScheduledInPast: false,
    hasBufferWarning: false,
    onNext: () {},
  );
}

void main() {
  group('LobbyConfigTabThoiGian — overnight indicator', () {
    testWidgets(
        'khi endCrossesMidnight=true → hiển thị banner + badge "+1 ngày"',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 23, minute: 0),
        endTime: const TimeOfDay(hour: 5, minute: 0),
        endCrossesMidnight: true,
      )));

      // Banner "Lobby kéo dài qua đêm" phải hiển thị.
      expect(
        find.text('Lobby kéo dài qua đêm'),
        findsOneWidget,
        reason:
            'Banner overnight phải hiển thị khi endCrossesMidnight=true',
      );

      // Badge "+1 ngày" trên End Time row.
      expect(
        find.text('+1 ngày'),
        findsOneWidget,
        reason:
            'Badge "+1 ngày" phải hiển thị kế bên End Time value',
      );

      // End Time value hiển thị "05:00".
      expect(find.text('05:00'), findsOneWidget);

      // Subtitle của banner hiển thị ngày kế tiếp (08/09 + 1 = 09/09).
      expect(
        find.textContaining('09/09'),
        findsOneWidget,
        reason: 'Banner phải nhắc tới ngày kết thúc (09/09 = 08/09 + 1 ngày)',
      );
    });

    testWidgets(
        'khi endCrossesMidnight=false → KHÔNG có banner overnight, '
        'KHÔNG có badge "+1 ngày"',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 19, minute: 0),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        endCrossesMidnight: false,
      )));

      expect(
        find.text('Lobby kéo dài qua đêm'),
        findsNothing,
        reason:
            'Banner overnight KHÔNG được hiển thị khi lobby cùng ngày',
      );
      expect(
        find.text('+1 ngày'),
        findsNothing,
        reason:
            'Badge "+1 ngày" KHÔNG được hiển thị khi lobby cùng ngày',
      );

      // End Time value "22:00" vẫn hiển thị bình thường.
      expect(find.text('22:00'), findsOneWidget);
    });

    testWidgets(
        'khi endTime=null (chưa chọn) → tab vẫn render bình thường, '
        'không có banner overnight',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: null,
        endCrossesMidnight: false,
      )));

      // "Mặc định theo phiên" hiển thị cho End Time.
      expect(find.text('Mặc định theo phiên'), findsOneWidget);
      expect(find.text('Lobby kéo dài qua đêm'), findsNothing);
    });

    testWidgets(
        'Start time 09:00 / End time 13:00 (mặc định cùng ngày) → '
        'không có overnight indicator',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 13, minute: 0),
        endCrossesMidnight: false,
      )));

      expect(find.text('09:00'), findsOneWidget);
      expect(find.text('13:00'), findsOneWidget);
      expect(find.text('+1 ngày'), findsNothing);
      expect(find.text('Lobby kéo dài qua đêm'), findsNothing);
    });
  });
}
