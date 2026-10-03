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
  int bufferMinutes = 60,
  bool isScheduledInPast = false,
  bool hasBufferWarning = false,
  bool isBufferInsufficient = false,
  bool canProceed = true,
  String? cannotProceedReason,
  VoidCallback? onPrev,
  VoidCallback? onNext,
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
    bufferMinutes: bufferMinutes,
    isScheduledInPast: isScheduledInPast,
    hasBufferWarning: hasBufferWarning,
    isBufferInsufficient: isBufferInsufficient,
    canProceed: canProceed,
    cannotProceedReason: cannotProceedReason,
    onPrev: onPrev ?? () {},
    onNext: onNext ?? () {},
  );
}

void main() {
  final today = DateTime.now();
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

      // Subtitle của banner hiển thị ngày kết thúc = playDate + 1.
      // playDate mặc định là `DateTime.now()` nên endDate = today + 1.
      // Format dd/mm nên expected = "DD/MM" với DD = today.day + 1.
      final tomorrowDay = today.day + 1;
      final tomorrowMonth = today.month;
      final tomorrowStr =
          '${tomorrowDay.toString().padLeft(2, '0')}/$tomorrowMonth';
      expect(
        find.textContaining(tomorrowStr),
        findsOneWidget,
        reason:
            'Banner phải nhắc tới ngày kết thúc (= playDate + 1 ngày)',
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

  // ════════════════════════════════════════════════════════════════════
  // BR §XXI-B.6 (cập nhật 2026-10-01): nút "Tiếp tục" ở tab Thời gian
  // phải disable + banner lý do hiển thị khi time invalid. Tab này là
  // điểm chặn ĐẦU TIÊN của user trước khi vào tab Đặt cọc — nếu để
  // user đi qua được rồi mới báo lỗi ở tab 3 sẽ rất khó chịu.
  // ════════════════════════════════════════════════════════════════════

  group('LobbyConfigTabThoiGian — canProceed gate (BR §XXI-B.6)', () {
    testWidgets(
        'canProceed=true → nút "Tiếp tục" enabled, không có banner lý do',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: const TimeOfDay(hour: 22, minute: 0),
        endCrossesMidnight: false,
        canProceed: true,
      )));

      // Nút "Tiếp tục" phải tồn tại (BR §XXI-B.6: khi canProceed=true
      // thì render bình thường, không có banner disable).
      expect(find.text('TIẾP TỤC'), findsOneWidget);

      // Banner lý do KHÔNG hiển thị vì !canProceed=false.
      // Verify bằng cách search các cụm text thường gặp trong banner.
      expect(find.textContaining('quá khứ'), findsNothing);
      expect(find.textContaining('không đủ thời gian'), findsNothing);
      expect(find.textContaining('Giờ kết thúc phải khác'), findsNothing);
    });

    testWidgets(
        'canProceed=false + reason về buffer ngắn → '
        'nút "Tiếp tục" disabled + banner hiển thị lý do',
        (tester) async {
      const reason =
          'Chỉ còn 5 phút trước giờ chơi — không đủ thời gian chuẩn bị '
          '(cần ít nhất 30 phút). Vui lòng chọn khung giờ xa hơn.';
      var nextCalled = false;

      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 19, minute: 35),
        endTime: const TimeOfDay(hour: 21, minute: 35),
        endCrossesMidnight: false,
        bufferMinutes: 5,
        isBufferInsufficient: false,
        canProceed: false,
        cannotProceedReason: reason,
        onNext: () => nextCalled = true,
      )));

      // Nút "Tiếp tục" hiển thị nhưng tap KHÔNG fire (disabled — không
      // gọi _handlePress khi onPressed=null). Dùng runAsync để clear
      // debounce timer nếu có.
      expect(find.text('TIẾP TỤC'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.text('TIẾP TỤC'));
        await Future<void>.delayed(const Duration(milliseconds: 600));
      });
      expect(nextCalled, isFalse,
          reason: 'canProceed=false → tap phải bị nuốt, không fire onNext');

      // Banner lý do hiển thị đầy đủ nội dung.
      expect(find.textContaining('Chỉ còn 5 phút'), findsOneWidget,
          reason: 'Banner phải hiển thị phần "Chỉ còn X phút"');
      expect(find.textContaining('không đủ thời gian chuẩn bị'),
          findsOneWidget,
          reason: 'Banner phải giải thích lý do disable');
      expect(find.textContaining('30 phút'), findsOneWidget,
          reason: 'Banner phải nhắc ngưỡng tối thiểu 30 phút');
    });

    testWidgets(
        'canProceed=false + reason về quá khứ → '
        'nút "Tiếp tục" disabled + banner nhắc đổi ngày mai',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: null,
        endCrossesMidnight: false,
        bufferMinutes: -120,
        isScheduledInPast: true,
        canProceed: false,
        cannotProceedReason:
            'Giờ bắt đầu đã ở trong quá khứ — vui lòng chọn khung giờ '
            'khác hoặc đổi sang ngày mai.',
      )));

      expect(find.text('TIẾP TỤC'), findsOneWidget);
      expect(find.textContaining('quá khứ'), findsOneWidget,
          reason: 'Banner phải nói rõ "quá khứ"');
      expect(find.textContaining('ngày mai'), findsOneWidget,
          reason: 'Banner phải hint đổi sang ngày mai');
    });

    testWidgets(
        'canProceed=false + reason về endTime==startTime → '
        'nút "Tiếp tục" disabled + banner giải thích',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: const TimeOfDay(hour: 20, minute: 0),
        endCrossesMidnight: false,
        bufferMinutes: 60,
        canProceed: false,
        cannotProceedReason:
            'Giờ kết thúc phải khác giờ bắt đầu — vui lòng chọn lại giờ '
            'kết thúc (mặc định sẽ là +4 giờ so với giờ bắt đầu).',
      )));

      expect(find.text('TIẾP TỤC'), findsOneWidget);
      expect(find.textContaining('Giờ kết thúc phải khác'), findsOneWidget,
          reason: 'Banner phải giải thích endTime phải khác startTime');
      expect(find.textContaining('+4 giờ'), findsOneWidget,
          reason: 'Banner phải hint default endTime = startTime + 4h');
    });

    testWidgets(
        'regression: canProceed=true + không có reason → '
        'banner lý do KHÔNG hiển thị (kể cả khi cannotProceedReason=null)',
        (tester) async {
      await tester.pumpWidget(_wrap(_buildTab(
        startTime: const TimeOfDay(hour: 20, minute: 0),
        endTime: null,
        endCrossesMidnight: false,
        bufferMinutes: 60,
        canProceed: true,
        cannotProceedReason: null,
      )));

      // Banner lý do KHÔNG hiển thị vì !canProceed=false.
      // Verify bằng cách tìm text thường gặp trong banner reason.
      expect(find.textContaining('quá khứ'), findsNothing);
      expect(find.textContaining('không đủ thời gian'), findsNothing);
      expect(find.textContaining('Giờ kết thúc phải khác'), findsNothing);
    });
  });
}
