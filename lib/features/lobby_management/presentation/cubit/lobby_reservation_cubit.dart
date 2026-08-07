import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../reservation/domain/entities/entities.dart';
import '../../../reservation/domain/repositories/reservation_repository.dart';

/// State cho LobbyReservationCubit — sealed cho type-safety.
sealed class LobbyReservationState {
  const LobbyReservationState();
}

class LobbyReservationInitial extends LobbyReservationState {
  const LobbyReservationInitial();
}

class LobbyReservationLoading extends LobbyReservationState {
  const LobbyReservationLoading();
}

class LobbyReservationLoaded extends LobbyReservationState {
  /// Reservation detail mới nhất fetch được từ server.
  final ReservationEntity reservation;

  /// Cờ báo load đầu tiên (initial fetch). UI dùng để hiển thị shimmer.
  final bool isFirstLoad;

  const LobbyReservationLoaded({
    required this.reservation,
    this.isFirstLoad = false,
  });
}

class LobbyReservationError extends LobbyReservationState {
  final String message;
  const LobbyReservationError(this.message);
}

/// Cubit load + poll reservation detail cho LobbyPage.
///
/// Mục tiêu:
/// - Sau khi LobbyPage mount, fetch `GET /reservations/{reservationId}` để lấy
///   `status` chính xác (`holding` / `confirmed` / `checkedIn` / …) — vì
///   `lobby.status` không phản ánh trạng thái POS/check-in.
/// - Poll mỗi 15s (best-effort fallback khi SignalR realtime mock không hoạt
///   động). Khi realtime hoạt động, cubit này vẫn có ích vì server vẫn trả
///   `lobbyStatus` mới nhất mỗi lần poll.
/// - Tự stop poll khi reservation đã ở terminal state (tránh spam API).
class LobbyReservationCubit extends Cubit<LobbyReservationState> {
  final ReservationRepository repository;

  /// Reservation ID cần theo dõi. `null` nếu lobby chưa có reservation
  /// (vd: lobby được tạo trực tiếp, không qua flow BVC).
  String? _reservationId;

  Timer? _pollTimer;
  static const Duration _pollInterval = Duration(seconds: 15);

  LobbyReservationCubit({required this.repository})
      : super(const LobbyReservationInitial());

  /// Bắt đầu load + poll reservation detail.
  ///
  /// - [reservationId]: ID của reservation (lấy từ `LobbyEntity.reservationId`).
  /// - [initialReservation]: optional — nếu cubit cha đã có data thì truyền
  ///   vào để hiển thị ngay, tránh flash "loading".
  void startWatching({
    required String? reservationId,
    ReservationEntity? initialReservation,
  }) {
    if (_reservationId == reservationId &&
        state is LobbyReservationLoaded) {
      // Đã watch ID này rồi — không restart.
      return;
    }
    _stopPolling();

    if (reservationId == null || reservationId.isEmpty) {
      emit(const LobbyReservationError('Lobby chưa liên kết với reservation.'));
      return;
    }

    _reservationId = reservationId;

    if (initialReservation != null) {
      emit(LobbyReservationLoaded(
        reservation: initialReservation,
        isFirstLoad: false,
      ));
    }

    _load(isFirstLoad: initialReservation == null);
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(isFirstLoad: false));
  }

  Future<void> _load({required bool isFirstLoad}) async {
    final id = _reservationId;
    if (id == null) return;

    if (isFirstLoad && state is! LobbyReservationLoaded) {
      emit(const LobbyReservationLoading());
    }

    final result = await repository.getReservationDetail(id);
    if (isClosed) return;

    result.fold(
      (failure) {
        // Giữ state cũ nếu đã có data — chỉ emit error khi chưa có data nào.
        if (state is LobbyReservationLoaded) return;
        emit(LobbyReservationError(failure.message));
      },
      (reservation) {
        emit(LobbyReservationLoaded(
          reservation: reservation,
          isFirstLoad: isFirstLoad,
        ));

        // Reservation ở terminal state → dừng poll, tránh spam API.
        if (reservation.status.isTerminal) {
          _stopPolling();
        }
      },
    );
  }

  /// Manual refresh (vd: pull-to-refresh).
  Future<void> refresh() async {
    await _load(isFirstLoad: false);
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() async {
    _stopPolling();
    return super.close();
  }
}
