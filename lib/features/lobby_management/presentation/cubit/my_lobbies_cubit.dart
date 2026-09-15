import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../profile/domain/entities/profile_entity.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'my_lobbies_state.dart';

/// Cubit cho section "Phòng chờ của tôi" trong Discovery → tab "Phòng chờ".
///
/// Sử dụng `GET /api/v1/lobbies/my` với 2 query params:
///   ?statuses=4,16,1,0,6,14&statusFilter=InProgress,WaitingCheckIn,Full,Open,RatingOpen,Viable
///
/// Backend sort kết quả:
///   1. Active: InProgress(4), WaitingCheckIn(16) — đang hoạt động
///   2. Open: Full(1), Open(0), RatingOpen(6), Viable(14) — sẵn sàng
///   3. Mỗi nhóm sắp theo thời gian mới nhất.
/// Client chỉ cần gửi filter → backend sort đúng, không sort thêm.
///
/// Tên quán cafe (`cafeName`) đã có sẵn trong response từ
/// `/api/v1/lobbies/my` nên không cần gọi thêm endpoint `/cafes/{id}`.
class MyLobbiesCubit extends Cubit<MyLobbiesState> {
  final LobbyRepository repository;

  MyLobbiesCubit({
    required this.repository,
  }) : super(const MyLobbiesInitial());

  /// Active statuses — theo backend spec: "Bỏ trống = trả tất cả
  /// active statuses". Spec chỉ liệt kê Open=0, Full=1, InProgress=4,
  /// RatingOpen=6. Gửi đúng 4 giá trị này để backend filter + sort.
  ///
  /// Sort order gửi lên backend (chỉ định hướng, backend quyết sort thực tế):
  ///   InProgress(4) → WaitingCheckIn(16) → Full(1) → Open(0)
  ///   → RatingOpen(6) → Viable(14)
  /// Đảm bảo lobby đang chơi / chờ check-in hiện lên trước lobby mới mở.
  static const _activeStatusInts = [
    4,  // InProgress — đang chơi
    16, // WaitingCheckIn — chờ check-in
    1,  // Full — đã đầy
    0,  // Open — đang mở
    6,  // RatingOpen — đang đánh giá
    14, // Viable — đủ người chơi
  ];

  /// Filter bằng tên enum — backend union với `statuses` nếu cả 2 cùng truyền.
  static const _activeStatusFilter = 'InProgress,WaitingCheckIn,Full,Open,RatingOpen,Viable';

  /// Load danh sách lobby user hosting + lobby đã tham gia.
  ///
  /// Ưu tiên endpoint `/my` với filter active statuses — backend trả
  /// kết quả đã sort đúng thứ tự (active trước → terminal sau,
  /// trong mỗi nhóm theo thời gian mới nhất).
  Future<void> load(ProfileEntity? currentUser) async {
    if (isClosed) return;
    emit(const MyLobbiesLoading());

    try {
      // Gọi `/my` với active statuses filter (cả int lẫn string name).
      // Backend union 2 param nếu cùng truyền → lọc chính xác nhất.
      // Backend tự sort: InProgress/WaitingCheckIn → Full/Open → Viable,
      // trong mỗi nhóm theo thời gian mới nhất.
      final myResult = await repository.getMyLobbies(
        statuses: _activeStatusInts,
        statusFilter: _activeStatusFilter,
      );

      final merged = myResult.fold(
        (_) => <LobbyEntity>[],
        (list) => list,
      );

      if (isClosed) return;

      // Phân loại hosted vs joined dựa trên hostId.
      final hostedIds = <String>{};
      final joinedIds = <String>{};
      for (final l in merged) {
        if (l.hostId == currentUser?.userId) {
          hostedIds.add(l.id);
        } else {
          joinedIds.add(l.id);
        }
      }
      final hosted = merged.where((l) => hostedIds.contains(l.id)).toList();
      final joined = merged.where((l) => joinedIds.contains(l.id)).toList();

      // Backend đã filter và sort đúng — không cần filter thêm
      // client-side. Dữ liệu đã đúng thứ tự ưu tiên.

      emit(MyLobbiesLoaded(
        hosted: hosted,
        joined: joined,
      ));
    } catch (e) {
      if (isClosed) return;
      emit(MyLobbiesFailure(message: 'Không tải được phòng chờ: $e'));
    }
  }

  /// Refresh chỉ phần hosted (dùng sau khi user tạo lobby mới, v.v.).
  Future<void> refresh(ProfileEntity? currentUser) => load(currentUser);
}
