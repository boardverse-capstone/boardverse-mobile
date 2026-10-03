import 'package:boardverse/core/utils/date_formatter.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';
import 'package:boardverse/features/tournament/presentation/cubit/tournament_list_state.dart';

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
  /// Delegates to [DateFormatter.fullDateTime] for consistency.
  static String formatDateTime(DateTime d) => DateFormatter.fullDateTime(d);

  /// Filter tournaments based on selected filter index.
  ///
  /// Filter indices correspond to labels in `TournamentFilterSection`:
  ///   0 = Tất cả
  ///   1 = Đang mở           (RegistrationOpen — chưa đăng ký + đã đăng ký)
  ///   2 = Đang diễn ra     (OnGoing — player đã đăng ký)
  ///   3 = Đã kết thúc      (Completed — player đã tham gia)
  ///   4 = Đã hủy           (Cancelled — player đã đăng ký)
  ///
  /// Lưu ý: "Đã đóng đăng ký" không còn là filter riêng — các giải đã
  /// đóng đăng ký vẫn nằm trong "Tất cả" để player xem thông tin.
  static List<TournamentEntity> filterTournaments(
    TournamentListLoaded state,
    int selectedFilter,
  ) {
    switch (selectedFilter) {
      case 1:
        return state.openTournaments;
      case 2:
        return state.ongoingTournaments;
      case 3:
        return state.completedTournaments;
      case 4:
        return state.cancelledTournaments;
      default:
        return [
          ...state.openTournaments,
          ...state.closedTournaments,
          ...state.ongoingTournaments,
          ...state.completedTournaments,
          ...state.cancelledTournaments,
        ];
    }
  }
}
