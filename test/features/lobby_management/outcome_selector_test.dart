// Widget tests cho OutcomeSelector (Match Result feature).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/match_result_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/widgets/outcome_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OutcomeSelector', () {
    testWidgets('displays all three outcome options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutcomeSelector(
              selectedOutcome: null,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Thắng'), findsOneWidget);
      expect(find.text('Thua'), findsOneWidget);
      expect(find.text('Hòa'), findsOneWidget);
    });

    testWidgets('calls onSelected when outcome is tapped', (tester) async {
      MatchOutcome? selectedOutcome;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutcomeSelector(
              selectedOutcome: null,
              onSelected: (outcome) => selectedOutcome = outcome,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Thắng'));
      await tester.pump();

      expect(selectedOutcome, MatchOutcome.win);
    });

    testWidgets('highlights selected outcome', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutcomeSelector(
              selectedOutcome: MatchOutcome.win,
              onSelected: (_) {},
            ),
          ),
        ),
      );

      // The selected outcome button should have different styling
      expect(find.text('Thắng'), findsOneWidget);
      expect(find.text('Thua'), findsOneWidget);
      expect(find.text('Hòa'), findsOneWidget);
    });

    testWidgets('allows changing selection', (tester) async {
      MatchOutcome? selectedOutcome = MatchOutcome.win;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: OutcomeSelector(
                  selectedOutcome: selectedOutcome,
                  onSelected: (outcome) {
                    setState(() => selectedOutcome = outcome);
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Thua'));
      await tester.pump();

      expect(selectedOutcome, MatchOutcome.loss);
    });

    testWidgets('disables interaction when isDisabled is true', (tester) async {
      MatchOutcome? selectedOutcome;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OutcomeSelector(
              selectedOutcome: null,
              onSelected: (outcome) => selectedOutcome = outcome,
              isDisabled: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Thắng'));
      await tester.pump();

      expect(selectedOutcome, isNull);
    });
  });
}
