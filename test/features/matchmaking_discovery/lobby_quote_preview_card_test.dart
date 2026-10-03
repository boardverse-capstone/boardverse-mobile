// Widget tests cho [LobbyConfigQuotePreviewCard] và helper
// [LobbyConfigQuoteRow] — verify:
// - Không còn tiếng Anh lẫn tiếng Việt ("Base deposit", "Risk
//   multiplier", "Buffer: ... để tuyển người").
// - Copy thân thiện cho player ("Giá vé cơ bản", "Số người tối đa",
//   "BẠN CẦN CỌC", "Còn X để tuyển người").
// - BR-DEPOSIT-02 (2026-08-27 chỉnh): `cafeBasePriceVnd` mới thay
//   cho `depositRatePerPerson` + `baseDeposit` cũ. Hiển thị giá vé cơ
//   bản (VND/người) + số người tối đa.
// - `cafeBasePriceVnd = null` → hiển thị "—" (backward-compat cho
//   response cũ pre-2026-08-27).
// - `riskMultiplier = 1.0` → ẩn row "Hệ số rủi ro" (chỉ hiện khi > 1.0).
// - `riskMultiplier > 1.0` → hiện row với giá trị highlight warning.
// - `LobbyConfigQuoteRow` chấp nhận `valueColor` override.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse/features/matchmaking_discovery/presentation/widgets/lobby_config/quote_preview_card.dart';
import 'package:boardverse/features/matchmaking_discovery/presentation/widgets/lobby_config/quote_row.dart';
import 'package:boardverse/features/reservation/domain/entities/reservation_quote_entity.dart';
import 'package:boardverse/features/reservation/domain/entities/reservation_entity.dart';
import 'package:boardverse/core/theme/app_colors.dart';

/// Helper tạo quote fixture cho test.
ReservationQuoteEntity _buildQuote({
  int? cafeBasePriceVnd,
  double riskMultiplier = 1.0,
  int finalDeposit = 3,
  int minPlayers = 2,
  int maxPlayers = 3,
  int bufferMinutes = 120,
}) {
  final now = DateTime.now();
  return ReservationQuoteEntity(
    cafeId: 'cafe-1',
    cafeName: 'Boss Cafe',
    gameId: 'game-1',
    gameName: 'Catan',
    playDate: now.add(const Duration(days: 1)),
    timeSlot: TimeSlot.evening,
    scheduledStartTime: now.add(const Duration(days: 1, hours: 4)),
    scheduledEndTime: now.add(const Duration(days: 1, hours: 6)),
    recruitmentDeadline: now.add(const Duration(hours: 23)),
    minPlayers: minPlayers,
    maxPlayers: maxPlayers,
    // Field cũ — không còn dùng để hiển thị breakdown, mặc định 0.
    depositRatePerPerson: 0,
    baseDeposit: 0,
    riskMultiplier: riskMultiplier,
    minDepositApplied: 0,
    finalDeposit: finalDeposit,
    // BR-DEPOSIT-02 (2026-08-27 chỉnh): field mới — null khi response
    // cũ, có giá trị khi response mới.
    cafeBasePriceVnd: cafeBasePriceVnd,
    currentBalance: 100,
    missingAmount: 0,
    bufferMinutes: bufferMinutes,
    bufferWarning: bufferMinutes < 60,
    requiresCafeApproval: false,
    expiresAt: now.add(const Duration(minutes: 5)),
    warnings: const [],
  );
}

String _fmtBuffer(int m) {
  if (m >= 60) {
    final h = m ~/ 60;
    final r = m % 60;
    return r == 0 ? '${h}h' : '${h}h ${r}p';
  }
  return '${m}p';
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LobbyConfigQuoteRow', () {
    testWidgets('render label + value', (tester) async {
      await tester.pumpWidget(_wrap(
        const LobbyConfigQuoteRow(label: 'Cọc mỗi người', value: '5 BVC'),
      ));
      expect(find.text('Cọc mỗi người'), findsOneWidget);
      expect(find.text('5 BVC'), findsOneWidget);
    });

    testWidgets('apply valueColor override', (tester) async {
      await tester.pumpWidget(_wrap(
        LobbyConfigQuoteRow(
          label: 'Hệ số rủi ro',
          value: '×1.20',
          valueColor: AppColors.warning,
        ),
      ));
      final widget = tester.widget<Text>(find.text('×1.20'));
      expect(widget.style?.color, AppColors.warning);
    });
  });

  group('LobbyConfigQuotePreviewCard', () {
    testWidgets(
      'BR-DEPOSIT-02 (2026-08-27) — hiển thị cafeBasePriceVnd + maxPlayers',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(cafeBasePriceVnd: 50000, maxPlayers: 4),
          formatBuffer: _fmtBuffer,
        )));

        // ─── Friendly Vietnamese labels (BR-DEPOSIT-02) ──────────
        expect(find.text('Giá vé cơ bản'), findsOneWidget);
        expect(find.text('Số người tối đa'), findsOneWidget);
        expect(find.text('BẠN CẦN CỌC'), findsOneWidget);
        // bufferMinutes = thời gian từ now → recruitment deadline
        // (= scheduledStartTime - leadTime), KHÔNG phải thời gian
        // đến giờ chơi. Label phải là "để tuyển người".
        expect(find.text('Còn 2h để tuyển người'), findsOneWidget);

        // ─── KHÔNG hiển thị label cũ (đã bỏ theo BR-DEPOSIT-02) ──
        expect(find.text('Cọc mỗi người'), findsNothing);
        expect(find.text('Số người chơi'), findsNothing);
        expect(find.text('Cọc tối thiểu'), findsNothing);

        // ─── KHÔNG hiển thị tiếng Anh ──────────────────────────────
        expect(find.text('Base deposit'), findsNothing);
        expect(find.text('Risk multiplier'), findsNothing);
        expect(find.textContaining('Buffer:'), findsNothing);
        // Không dùng cụm "trước giờ chơi" nữa vì semantic sai —
        // giá trị buffer là recruitment window, không phải play time.
        expect(find.textContaining('trước giờ chơi'), findsNothing);

        // ─── Giá trị ────────────────────────────────────────────
        // cafeBasePriceVnd = 50000 → "50.000 đ/người"
        expect(find.text('50.000 đ/người'), findsOneWidget);
        // maxPlayers = 4 → "4"
        expect(find.text('4'), findsOneWidget);
        // finalDeposit = 3 → "3 BVC"
        expect(find.text('3 BVC'), findsOneWidget);
      },
    );

    testWidgets(
      'cafeBasePriceVnd = null → fallback hiển thị "—" (backward-compat)',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(cafeBasePriceVnd: null),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('Giá vé cơ bản'), findsOneWidget);
        expect(find.text('—'), findsOneWidget);
      },
    );

    testWidgets(
      'cafeBasePriceVnd = 1.250.000 → format dấu chấm hàng nghìn',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(cafeBasePriceVnd: 1250000),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('1.250.000 đ/người'), findsOneWidget);
      },
    );

    testWidgets(
      'riskMultiplier = 1.0 → ẩn row "Hệ số rủi ro"',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(riskMultiplier: 1.0),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('Hệ số rủi ro'), findsNothing);
      },
    );

    testWidgets(
      'riskMultiplier > 1.0 → hiện row với value highlight warning',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(riskMultiplier: 1.25),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('Hệ số rủi ro'), findsOneWidget);
        expect(find.text('×1.25'), findsOneWidget);

        // Verify value rendered với warning color (highlight rủi ro).
        final widget = tester.widget<Text>(find.text('×1.25'));
        expect(widget.style?.color, AppColors.warning);
      },
    );

    testWidgets(
      'buffer = 30p → hiển thị "Còn 30p để tuyển người"',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(bufferMinutes: 30),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('Còn 30p để tuyển người'), findsOneWidget);
      },
    );

    testWidgets(
      'buffer = 7h 28p → format "Còn 7h 28p để tuyển người"',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(bufferMinutes: 7 * 60 + 28),
          formatBuffer: _fmtBuffer,
        )));
        expect(find.text('Còn 7h 28p để tuyển người'), findsOneWidget);
      },
    );

    testWidgets(
      'maxPlayers thay thế playerRangeDisplay cũ',
      (tester) async {
        await tester.pumpWidget(_wrap(LobbyConfigQuotePreviewCard(
          quote: _buildQuote(minPlayers: 2, maxPlayers: 2),
          formatBuffer: _fmtBuffer,
        )));
        // Hiển thị "2" cho cả min == max (BR-DEPOSIT-02 mới — chỉ show
        // maxPlayers, không dùng playerRangeDisplay cũ).
        expect(find.text('2'), findsOneWidget);
        expect(find.text('2-2'), findsNothing);
      },
    );
  });
}