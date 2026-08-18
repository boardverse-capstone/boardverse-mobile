import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/reservation_repository.dart';
import 'reservation_detail_state.dart';

/// Cubit xử lý trang chi tiết reservation.
///
/// Gọi `GET /api/v1/reservations/{id}` để lấy dữ liệu mới nhất từ server.
/// Nếu không thể fetch (offline), fallback về snapshot từ list page.
class ReservationDetailCubit extends Cubit<ReservationDetailState> {
  final ReservationRepository repository;

  ReservationDetailCubit({required this.repository})
      : super(const ReservationDetailInitial());

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
        emit(ReservationDetailLoaded(reservation: reservation));
      },
    );
  }

  /// Refresh dữ liệu chi tiết từ server.
  Future<void> refresh(String reservationId) async {
    await fetchReservation(reservationId: reservationId);
  }
}
