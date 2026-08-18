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
  static String formatDateTime(DateTime d) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  /// Filter tournaments based on selected filter index.
  ///
  /// Filter indices correspond to labels in `TournamentFilterSection`:
  ///   0 = Tất cả
  ///   1 = Đang mở           (RegistrationOpen — chưa đăng ký + đã đăng ký)
  ///   2 = Đã đóng đăng ký   (RegistrationClosed — player đã đăng ký, đang
  ///                          chờ manager bấm Start, vẫn có thể rút lui)
  ///   3 = Đang diễn ra     (OnGoing — player đã đăng ký)
  ///   4 = Đã kết thúc      (Completed — player đã tham gia)
  ///   5 = Đã hủy           (Cancelled — player đã đăng ký)
  ///
  /// Mục đích của việc tách "Đã đóng đăng ký" / "Đã hủy" thành filter
  /// riêng: player đã đăng ký nhưng giải đã chuyển trạng thái vẫn phải
  /// hiển thị để player xem thông tin / rút lui. Trước đây các giải này
  /// "biến mất" khỏi tab Tournament vì `loadTournaments()` chỉ fetch
  /// OnGoing + Completed từ `/my-registrations`.
  static List<TournamentEntity> filterTournaments(
    TournamentListLoaded state,
    int selectedFilter,
  ) {
    switch (selectedFilter) {
      case 1:
        return state.openTournaments;
      case 2:
        return state.closedTournaments;
      case 3:
        return state.ongoingTournaments;
      case 4:
        return state.completedTournaments;
      case 5:
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
