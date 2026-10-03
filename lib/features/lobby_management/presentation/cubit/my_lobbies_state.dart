import 'package:equatable/equatable.dart';

import '../../domain/entities/lobby_entity.dart';

/// State cho [MyLobbiesCubit] — dùng ở section "Phòng chờ của tôi" trong
/// Discovery → tab "Phòng chờ".
///
/// Sử dụng real API endpoints:
/// - `GET /api/v1/lobbies/my` — lobby do user host+join (BE filter+sort)
///
/// Chia thành 2 nhóm theo status để UI render trên 2 tab của segmented
/// control (BR-NEW-MY-LOBBY-HISTORY, 2026-10-02):
///
/// - **Active** (status hiện đang tương tác được):
///   InProgress, WaitingCheckIn, Full, Open, RatingOpen, Viable, TimeoutFailed.
///   Hiển thị ở tab "Đang hoạt động" — player cần thấy actions (check-in,
///   ready, chat, …).
///
/// - **History** (status terminal, không thể tương tác):
///   Closed, HostCancelled, RejectedByCafe, ExpiredByCafe, Dissolved.
///   Hiển thị ở tab "Đã kết thúc" — player chỉ cần xem lại "lần trước
///   mình chơi game X ở quán Y với ai, kết quả thế nào".
sealed class MyLobbiesState extends Equatable {
  const MyLobbiesState();

  @override
  List<Object?> get props => [];
}

class MyLobbiesInitial extends MyLobbiesState {
  const MyLobbiesInitial();
}

class MyLobbiesLoading extends MyLobbiesState {
  const MyLobbiesLoading();
}

/// State khi load xong — chứa 2 nhóm lobby (active + history), mỗi nhóm
/// tách riêng hosted/joined dựa trên `hostId == currentUserId`.
class MyLobbiesLoaded extends MyLobbiesState {
  /// Active lobby do current user HOST.
  final List<LobbyEntity> activeHosted;

  /// Active lobby user đã THAM GIA (không phải host).
  final List<LobbyEntity> activeJoined;

  /// Terminal lobby do current user HOST (lịch sử phòng đã tạo).
  final List<LobbyEntity> historyHosted;

  /// Terminal lobby user đã THAM GIA (lịch sử phòng đã chơi).
  final List<LobbyEntity> historyJoined;

  const MyLobbiesLoaded({
    required this.activeHosted,
    required this.activeJoined,
    required this.historyHosted,
    required this.historyJoined,
  });

  /// True khi cả 2 nhóm đều rỗng — dùng cho empty state toàn màn hình.
  bool get isEmpty =>
      activeHosted.isEmpty &&
      activeJoined.isEmpty &&
      historyHosted.isEmpty &&
      historyJoined.isEmpty;

  bool get isActiveEmpty =>
      activeHosted.isEmpty && activeJoined.isEmpty;

  bool get isHistoryEmpty =>
      historyHosted.isEmpty && historyJoined.isEmpty;

  int get activeCount => activeHosted.length + activeJoined.length;
  int get historyCount => historyHosted.length + historyJoined.length;

  /// Copy với một số field thay đổi — giữ nguyên các field còn lại.
  MyLobbiesLoaded copyWith({
    List<LobbyEntity>? activeHosted,
    List<LobbyEntity>? activeJoined,
    List<LobbyEntity>? historyHosted,
    List<LobbyEntity>? historyJoined,
  }) {
    return MyLobbiesLoaded(
      activeHosted: activeHosted ?? this.activeHosted,
      activeJoined: activeJoined ?? this.activeJoined,
      historyHosted: historyHosted ?? this.historyHosted,
      historyJoined: historyJoined ?? this.historyJoined,
    );
  }

  @override
  List<Object?> get props => [
        activeHosted,
        activeJoined,
        historyHosted,
        historyJoined,
      ];
}

class MyLobbiesFailure extends MyLobbiesState {
  final String message;

  const MyLobbiesFailure({required this.message});

  @override
  List<Object?> get props => [message];
}