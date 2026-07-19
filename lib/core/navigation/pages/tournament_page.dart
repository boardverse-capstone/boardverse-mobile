import 'package:flutter/material.dart';

import '../../../features/tournament/presentation/pages/tournament_page.dart'
    as feature;

/// Tab "Giải đấu" — delegate toàn bộ UI cho [feature.TournamentPage].
///
/// Exposes [requestRefresh] so the bottom-nav double-tap handler can
/// re-load the tournaments list (currently mock data, so the hook is
/// wired for future API integration).
class TournamentPage extends StatelessWidget {
  const TournamentPage({super.key});

  static void requestRefresh(BuildContext context) {
    TournamentRefreshSignal.instance.notify();
  }

  @override
  Widget build(BuildContext context) {
    return const feature.TournamentPage();
  }
}

class TournamentRefreshSignal extends ChangeNotifier {
  TournamentRefreshSignal._();
  static final TournamentRefreshSignal instance = TournamentRefreshSignal._();

  void notify() {
    if (hasListeners) notifyListeners();
  }
}