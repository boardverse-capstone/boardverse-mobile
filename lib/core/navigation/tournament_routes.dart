import 'package:flutter/material.dart';

import '../../features/tournament/presentation/pages/elo_history_page.dart';
import '../../features/tournament/presentation/pages/leaderboard_page.dart';
import '../../features/tournament/presentation/pages/match_detail_page.dart';
import '../../features/tournament/presentation/pages/my_registrations_page.dart';
import '../../features/tournament/presentation/pages/participant_detail_page.dart';
import '../../features/tournament/presentation/pages/tournament_detail_page.dart';
import '../../features/tournament/domain/entities/tournament_match_entity.dart';
import '../../features/tournament/domain/entities/tournament_participant_entity.dart';

/// Centralized navigation helpers for tournament feature.
///
/// All tournament-related navigation goes through this class so we have a
/// single place to:
/// - Apply consistent transition animations
/// - Track analytics later if needed
/// - Make future routing changes (deep links, go_router) easier
class TournamentRoutes {
  TournamentRoutes._();

  /// Push full tournament detail page (with 3 tabs).
  static Future<T?> openTournamentDetail<T>({
    required BuildContext context,
    required String tournamentId,
  }) {
    return _push<T>(
      context,
      TournamentDetailPage(tournamentId: tournamentId),
    );
  }

  /// Push participant detail page.
  ///
  /// If [initial] is provided we skip the network round-trip on first frame
  /// and only refresh on explicit pull-to-refresh.
  static Future<T?> openParticipantDetail<T>({
    required BuildContext context,
    required String tournamentId,
    required String participantId,
    TournamentParticipantEntity? initial,
  }) {
    return _push<T>(
      context,
      ParticipantDetailPage(
        tournamentId: tournamentId,
        participantId: participantId,
        initial: initial,
      ),
    );
  }

  /// Push match detail page.
  static Future<T?> openMatchDetail<T>({
    required BuildContext context,
    required String matchId,
    TournamentMatchEntity? initial,
  }) {
    return _push<T>(
      context,
      MatchDetailPage(matchId: matchId, initial: initial),
    );
  }

  /// Push "My Registrations" page (with status filter).
  static Future<T?> openMyRegistrations<T>(BuildContext context) {
    return _push<T>(context, const MyRegistrationsPage());
  }

  /// Push "Elo History" page.
  static Future<T?> openEloHistory<T>(BuildContext context) {
    return _push<T>(context, const EloHistoryPage());
  }

  /// Push "Leaderboard" page.
  static Future<T?> openLeaderboard<T>(BuildContext context) {
    return _push<T>(context, const LeaderboardPage());
  }

  /// Shared transition — iOS-style slide from right.
  static Route<T> _routeBuilder<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
        return SlideTransition(position: slide, child: child);
      },
    );
  }

  static Future<T?> _push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(_routeBuilder<T>(page));
  }
}