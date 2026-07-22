// Widget tests cho LobbyInviteCard.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:boardverse_mobile/features/lobby_management/domain/entities/lobby_invite_entity.dart';
import 'package:boardverse_mobile/features/lobby_management/presentation/widgets/lobby_invite_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LobbyInviteCard', () {
    final testInvite = LobbyInviteEntity(
      inviteId: 'invite_123',
      lobbyId: 'lobby_456',
      inviterId: 'user_789',
      inviterName: 'Test User',
      inviterAvatar: 'https://i.pravatar.cc/150?u=testuser',
      inviteeId: 'user_current',
      message: 'Chơi Catan nhé!',
      status: LobbyInviteStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      expiresAt: DateTime.now().add(const Duration(hours: 23)),
      gameName: 'Catan',
      cafeName: 'Board Game Cafe',
      currentMembers: 2,
      maxMembers: 4,
    );

    testWidgets('displays invite information correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyInviteCard(
              invite: testInvite,
              onAccept: () {},
              onDecline: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Catan'), findsOneWidget);
      expect(find.text('Board Game Cafe'), findsOneWidget);
      expect(find.text('Chơi Catan nhé!'), findsOneWidget);
    });

    testWidgets('shows Tham gia button for pending invite', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyInviteCard(
              invite: testInvite,
              onAccept: () {},
              onDecline: () {},
            ),
          ),
        ),
      );

      expect(find.text('Tham gia'), findsOneWidget);
      expect(find.text('Từ chối'), findsOneWidget);
    });

    testWidgets('calls onAccept when Tham gia is tapped', (tester) async {
      bool acceptCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyInviteCard(
              invite: testInvite,
              onAccept: () => acceptCalled = true,
              onDecline: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tham gia'));
      await tester.pump();

      expect(acceptCalled, true);
    });

    testWidgets('calls onDecline when Từ chối is tapped', (tester) async {
      bool declineCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyInviteCard(
              invite: testInvite,
              onAccept: () {},
              onDecline: () => declineCalled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Từ chối'));
      await tester.pump();

      expect(declineCalled, true);
    });

    testWidgets('displays member count correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LobbyInviteCard(
              invite: testInvite,
              onAccept: () {},
              onDecline: () {},
            ),
          ),
        ),
      );

      expect(find.text('2/4'), findsOneWidget);
    });
  });
}
