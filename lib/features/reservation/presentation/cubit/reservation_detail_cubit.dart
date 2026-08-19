import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../lobby_management/domain/repositories/lobby_repository.dart';
import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'reservation_detail_state.dart';

/// Cubit xử lý trang chi tiết reservation.
///
/// Gọi `GET /api/v1/reservations/{id}` để lấy dữ liệu mới nhất từ server.
/// Nếu không thể fetch (offline), fallback về snapshot từ list page.
///
/// Sau khi có reservation, nếu `lobbyId` tồn tại sẽ gọi thêm
/// `GET /api/v1/lobbies/{id}` để lấy `currentPlayers` chính xác của lobby
/// (response detail reservation có thể trả `currentPlayers` lệch — chỉ
/// count slot của reservation, không count player tham gia lobby).
class ReservationDetailCubit extends Cubit<ReservationDetailState> {
  final ReservationRepository repository;
  final LobbyRepository lobbyRepository;

  ReservationDetailCubit({
    required this.repository,
    required this.lobbyRepository,
  }) : super(const ReservationDetailInitial());

  /// Fetch chi tiết reservation từ API.
  ///
  /// [reservationId] - ID của reservation cần lấy chi tiết.
  /// [snapshot] - Optional snapshot từ list page để hiển thị tạm trong khi loading.
  Future<void> fetchReservation({
    required String reservationId,
    ReservationEntity? snapshot,
  }) async {
    // Emit snapshot nếu có (để UI không phải chờ)
    if (snapshot != null) {
      emit(ReservationDetailLoading(reservation: snapshot));
    } else {
      emit(const ReservationDetailLoading());
    }

    final result = await repository.getReservation(reservationId);

    await result.fold(
      (failure) async {
        // Nếu có snapshot và không fetch được, vẫn hiển thị snapshot
        if (snapshot != null) {
          emit(ReservationDetailLoaded(
            reservation: snapshot,
            isFromCache: true,
            errorMessage: 'Không thể cập nhật: ${failure.message}',
          ));
        } else {
          emit(ReservationDetailError(message: failure.message));
        }
      },
      (reservation) async {
        // Emit loaded với data reservation trước
        emit(ReservationDetailLoaded(reservation: reservation));

        // Sau đó fetch lobby detail để lấy currentPlayers chính xác
        await _enrichFromLobby(reservation);
      },
    );
  }

  /// Fetch lobby detail để enrich `currentPlayers` cho reservation.
  ///
  /// Backend `/api/v1/reservations/{id}` trả `currentPlayers` đôi khi chỉ
  /// count slot của reservation (host = 1), không phản ánh số thành viên
  /// thực tế trong lobby. Để hiển thị chính xác "X / Y người", ta fetch
  /// thêm `/api/v1/lobbies/{id}` (trả `currentPlayers` = members.length).
  ///
  /// Nếu fetch lobby fail hoặc không có lobbyId, vẫn dùng data reservation.
  Future<void> _enrichFromLobby(ReservationEntity reservation) async {
    final lobbyId = reservation.lobbyId;
    if (lobbyId == null || lobbyId.isEmpty) return;

    final lobbyResult = await lobbyRepository.getLobbyById(lobbyId);
    lobbyResult.fold(
      (failure) {
        // Không fetch được lobby → giữ nguyên currentPlayers từ reservation.
        // UI vẫn dùng r.currentPlayers (có thể không khớp) làm fallback.
      },
      (lobby) {
        if (lobby == null) return;
        // Lobby detail trả currentPlayers = members.length (host + members).
        // Ưu tiên dùng giá trị này thay vì reservation.currentPlayers.
        if (lobby.currentPlayers <= 0) return;
        if (lobby.currentPlayers == reservation.currentPlayers) return;

        // Re-emit với currentPlayers đã cập nhật.
        emit(ReservationDetailLoaded(
          reservation: reservation.copyWith(
            currentPlayers: lobby.currentPlayers,
          ),
        ));
      },
    );
  }

  /// Refresh dữ liệu chi tiết từ server.
  Future<void> refresh(String reservationId) async {
    await fetchReservation(reservationId: reservationId);
  }
}
