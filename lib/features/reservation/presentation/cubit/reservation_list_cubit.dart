import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/reservation_repository.dart';
import 'reservation_list_state.dart';

/// Cubit load danh sách reservation từ `GET /api/v1/reservations`.
/// Hỗ trợ filter `hostedByMe` / `joinedByMe` và refresh.
///
/// Tách ra từ logic inline trong `BookingsPage._loadReservations()` để:
/// 1. Reusable cho các ngữ cảnh khác (vd trang profile, dashboard).
/// 2. Auto refresh khi tab focus (kết hợp với Visibility detector).
/// 3. Cancel-safe thông qua Cubit lifecycle.
class ReservationListCubit extends Cubit<ReservationListState> {
  final ReservationRepository repository;

  bool? _lastHostedByMe;

  ReservationListCubit({required this.repository})
      : super(const ReservationListInitial());

  /// Load danh sách reservation. Nếu đã load trước với cùng filter thì vẫn
  /// emit Loading → Loaded để UI có thể hiển thị spinner refresh.
  Future<void> load({bool? hostedByMe, int pageSize = 50}) async {
    _lastHostedByMe = hostedByMe;
    emit(const ReservationListLoading());

    final result = await repository.getReservations(
      hostedByMe: hostedByMe,
      pageSize: pageSize,
    );

    result.fold(
      (failure) =>
          emit(ReservationListFailure(message: failure.message)),
      (page) => emit(ReservationListLoaded(
        items: page.items,
        hostedByMe: hostedByMe,
      )),
    );
  }

  /// Refresh với filter hiện tại (gọi lại `load`).
  Future<void> refresh() => load(hostedByMe: _lastHostedByMe);
}