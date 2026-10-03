import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/profile_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'my_lobbies_state.dart';

/// Cubit cho section "Phòng chờ của tôi" trong Discovery → tab "Phòng chờ".
///
/// Sử dụng `GET /api/v1/lobbies/my` với 2 filter riêng biệt (chạy song song):
///   1. Active filter (?statuses=4,16,1,0,6,14&statusFilter=TimeoutFailed)
///      → 7 status đang có thể tương tác (BR-NEW-MY-LOBBY-FILTER-FIX
///      2026-10-02, BR-NEW-MY-LOBBY-TIMEOUT).
///   2. History filter (?statuses=5,12,13,15&statusFilter=HostCancelled)
///      → 5 status terminal (BR-NEW-MY-LOBBY-HISTORY 2026-10-02):
///      Closed, RejectedByCafe, ExpiredByCafe, Dissolved, HostCancelled.
///
/// Backend sort kết quả: trong mỗi status theo scheduledTime desc; thứ
/// tự status ưu tiên do BE quyết định. Client không sort thêm.
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;

  MyLobbiesCubit({
    required this.repository,
  }) : super(const MyLobbiesInitial());

  /// ─── ACTIVE FILTER ─────────────────────────────────────────────────
  /// Int whitelist (statuses — bind `List<int>`) cho 6 status active nằm
  /// trong swagger whitelist của `GET /lobbies/my`:
  ///
  /// **`statuses` (int array)** — chỉ chứa giá trị nằm trong whitelist
  /// int của swagger (BR-NEW-MY-LOBBY-FILTER-FIX 2026-10-02). Theo
  /// swagger `GET /lobbies/my`, hợp lệ:
  ///   Open=0, Full=1, InProgress=4, Closed=5, RatingOpen=6,
  ///   PendingActivation=10, PendingCafeApproval=11, RejectedByCafe=12,
  ///   ExpiredByCafe=13, Viable=14, Dissolved=15, WaitingCheckIn=16.
  ///
  /// **Lưu ý quan trọng:** `TimeoutFailed=7` và `HostCancelled=8`
  /// **bị loại cố ý** khỏi whitelist int — gửi `?statuses=7` sẽ bị
  /// custom validator của BE reject:
  ///   `"Giá trị status không hợp lệ: 7. Hợp lệ: Open,Full,..."`.
  /// Hai status này PHẢI đi qua `statusFilter` (string CSV enum names).
  static const _activeStatusInts = [
    4,  // InProgress — đang chơi
    16, // WaitingCheckIn — chờ check-in
    1,  // Full — đã đầy
    0,  // Open — đang mở
    6,  // RatingOpen — đang đánh giá
    14, // Viable — đủ người chơi
  ];

  /// CSV enum names cho status bị loại khỏi whitelist int của `statuses`
  /// (active side). Hiện chỉ có `TimeoutFailed=7`
  /// (BR-NEW-MY-LOBBY-TIMEOUT).
  static const _activeStatusFilterExcluded = 'TimeoutFailed';

  /// ─── HISTORY FILTER (terminal statuses) ─────────────────────────────
  /// BR-NEW-MY-LOBBY-HISTORY (2026-10-02): player cần xem lại lobby đã
  /// kết thúc — cùng pattern filter như active nhưng nhắm vào 5 status
  /// terminal trong `LobbyStatus.isTerminal`:
  ///   Closed=5, TimeoutFailed=7, HostCancelled=8, RejectedByCafe=12,
  ///   ExpiredByCafe=13, Dissolved=15.
  ///
  /// Trong đó TimeoutFailed=7 đã được active filter "mượn" (status này
  /// vừa có giá trị xem lịch sử vừa là active đối với một số flow như
  /// BR-NEW-MY-LOBBY-TIMEOUT). Vì vậy history filter chỉ chứa 4 status
  /// còn lại trong int whitelist.
  static const _terminalStatusInts = [
    5,  // Closed — game đã đóng, rating cross được phép
    12, // RejectedByCafe — quán từ chối duyệt
    13, // ExpiredByCafe — quán không duyệt trong 24h
    15, // Dissolved — soft-delete sau khi host gọi DELETE
  ];

  /// CSV enum names cho status terminal bị loại khỏi whitelist int
  /// (BR-NEW-MY-LOBBY-HISTORY). Hiện chỉ có `HostCancelled=8` — host
  /// chủ động hủy khi lobby còn open. Vẫn có giá trị xem lịch sử nên
  /// đưa vào history filter qua `statusFilter` string.
  static const _terminalStatusFilterExcluded = 'HostCancelled';

  /// Load song song 2 nhóm lobby: active (7 statuses) và history
  /// (5 statuses). Mỗi nhóm BE trả về list đã sort, client chỉ cần
  /// phân loại hosted/joined dựa trên `hostId == currentUserId`.
  Future<void> load(ProfileEntity? currentUser) async {
    if (isClosed) return;
    emit(const MyLobbiesLoading());

    try {
      // BR-NEW-MY-LOBBY-HISTORY (2026-10-02): 2 API calls song song —
      // UI segmented control cần render cả 2 nhóm cùng lúc. Nếu lần
      // đầu chỉ fetch active rồi lazy fetch sau, segmented bị "nhảy"
      // data → UX khó chịu. Dùng Future.wait để chờ cả 2.
      final results = await Future.wait([
        repository.getMyLobbies(
          statuses: _activeStatusInts,
          statusFilter: _activeStatusFilterExcluded,
        ),
        repository.getMyLobbies(
          statuses: _terminalStatusInts,
          statusFilter: _terminalStatusFilterExcluded,
        ),
      ]);

      if (isClosed) return;

      final activeList = results[0].fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );
      final historyList = results[1].fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );

      final activeSplit = _splitHostedAndJoined(
        activeList,
        currentUser?.userId,
      );
      final historySplit = _splitHostedAndJoined(
        historyList,
        currentUser?.userId,
      );

      emit(MyLobbiesLoaded(
        activeHosted: activeSplit.hosted,
        activeJoined: activeSplit.joined,
        historyHosted: historySplit.hosted,
        historyJoined: historySplit.joined,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(MyLobbiesFailure(message: 'Không tải được phòng chờ: $e'));
    }
  }

  /// Tách lobby list thành hosted/joined dựa trên hostId.
  ///
  /// Backend đã filter + sort theo status priority + scheduledTime desc;
  /// client chỉ thêm 1 bước split theo ownership để UI phân biệt
  /// "phòng tôi tạo" vs "phòng tôi tham gia".
  ({List<LobbyEntity> hosted, List<LobbyEntity> joined})
      _splitHostedAndJoined(List<LobbyEntity> lobbies, String? currentUserId) {
    final hostedIds = <String>{};
    final joinedIds = <String>{};
    for (final l in lobbies) {
      if (l.hostId == currentUserId) {
        hostedIds.add(l.id);
      } else {
        joinedIds.add(l.id);
      }
    }
    return (
      hosted: lobbies.where((l) => hostedIds.contains(l.id)).toList(),
      joined: lobbies.where((l) => joinedIds.contains(l.id)).toList(),
    );
  }

  /// Refresh chỉ phần hosted (dùng sau khi user tạo lobby mới, v.v.).
  Future<void> refresh(ProfileEntity? currentUser) => load(currentUser);
}