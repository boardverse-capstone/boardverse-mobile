import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_status.dart';
import 'package:boardverse_mobile/features/tournament/presentation/cubit/tournament_list_state.dart';

class TournamentUtils {
  TournamentUtils._();

  /// Format currency to VND display (e.g., 100000 -> "100.000")
  static String formatVnd(int value) {
    final s = value.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  /// Format DateTime to display (e.g., "21/07/2026 14:30")
  static String formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Filter tournaments based on selected filter index.
  ///
  /// Filter indices correspond to labels in `TournamentFilterSection`:
  ///   0 = Tất cả
  ///   1 = Đang mở
  ///   2 = Đang diễn ra
  ///   3 = Đã kết thúc
  ///
  /// "Sắp diễn ra" (index 2 in the old 5-label layout) was removed because
  /// the player API does not expose `/tournaments/upcoming`. Upcoming
  /// tournaments that arrive via `/tournaments/open` are still surfaced
  /// under the "Tất cả" view.
  static List<TournamentEntity> filterTournaments(
    TournamentListLoaded state,
    int selectedFilter,
  ) {
    switch (selectedFilter) {
      case 1:
        return state.openTournaments
            .where((t) => t.status == TournamentStatus.registrationOpen)
            .toList();
      case 2:
        return state.ongoingTournaments;
      case 3:
        return state.completedTournaments;
      default:
        return [
          ...state.openTournaments,
          ...state.ongoingTournaments,
          ...state.completedTournaments,
        ];
    }
  }
}
