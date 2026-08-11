import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:boardverse_mobile/features/lobby_management/presentation/widgets/lobby_page_shimmer.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/widgets/lobby_list_shimmer.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_entity.dart';

/// Tests cho shimmer skeleton (Phase 3 — thay thế spinner).
///
/// Cover các entry point:
/// - LobbyPageShimmer (skeleton cho LobbyPage khi loading)
/// - LobbyInvitesShimmer (skeleton cho lobby invites list)
/// - LobbyRatingShimmer (skeleton cho rating page)
/// - MatchResultShimmer (skeleton cho match result)
/// - GenericPageShimmer (placeholder tổng quát)
void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  group('LobbyPageShimmer', () {
    testWidgets('render without errors', (tester) async {
      await tester.pumpWidget(
        wrap(const LobbyPageShimmer(playerSlots: 4, showChatSection: true)),
      );
      // 1 frame là đủ (linear progress shimmer).
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LobbyPageShimmer), findsOneWidget);
    });

    testWidgets('render không có chat section', (tester) async {
      await tester.pumpWidget(
        wrap(const LobbyPageShimmer(showChatSection: false)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LobbyPageShimmer), findsOneWidget);
    });

    testWidgets('render với nhiều slot player', (tester) async {
      await tester.pumpWidget(
        wrap(const LobbyPageShimmer(playerSlots: 6)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LobbyPageShimmer), findsOneWidget);
    });
  });

  group('LobbyInvitesShimmer', () {
    testWidgets('render list invites skeleton', (tester) async {
      await tester.pumpWidget(
        wrap(const LobbyInvitesShimmer(itemCount: 3)),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LobbyInvitesShimmer), findsOneWidget);
    });
  });

  group('LobbyRatingShimmer', () {
    testWidgets('render rating skeleton', (tester) async {
      await tester.pumpWidget(wrap(const LobbyRatingShimmer()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(LobbyRatingShimmer), findsOneWidget);
    });
  });

  group('MatchResultShimmer', () {
    testWidgets('render match result skeleton', (tester) async {
      await tester.pumpWidget(wrap(const MatchResultShimmer()));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(MatchResultShimmer), findsOneWidget);
    });
  });

  group('GenericPageShimmer', () {
    testWidgets('render generic skeleton', (tester) async {
      await tester.pumpWidget(
        wrap(const GenericPageShimmer(itemCount: 5, appBarTitle: 'Test')),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GenericPageShimmer), findsOneWidget);
    });

    testWidgets('render generic skeleton không có appBar', (tester) async {
      await tester.pumpWidget(
        wrap(const GenericPageShimmer()),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(GenericPageShimmer), findsOneWidget);
    });
  });

  // Sanity check: LobbyStatus enum đầy đủ 12 giá trị (mapping đầy đủ).
  test('LobbyStatus enum có đầy đủ 12 giá trị', () {
    expect(LobbyStatus.values.length, 12);
  });
}
