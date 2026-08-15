import 'package:flutter/material.dart';

import '../../../features/tournament/presentation/pages/tournament_page.dart';
import '../widgets/tournament_mini_nav_bar.dart';

/// Shell wrapper for TournamentPage that provides bottom navigation.
///
/// This allows users to switch tabs while browsing tournaments without
/// losing their tournament context.
class TournamentShell extends StatelessWidget {
  const TournamentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const TournamentPage(),
      bottomNavigationBar: TournamentMiniNavBar(
        currentIndex: 0,
        onTabSelected: (index) {
          if (index == 0) return; // Already on Tournament tab
          // Pop and return the tab index to MainScaffold
          Navigator.of(context).pop(index);
        },
      ),
    );
  }
}
