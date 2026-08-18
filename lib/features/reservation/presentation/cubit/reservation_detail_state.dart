import '../../domain/entities/entities.dart';

/// States cho ReservationDetailCubit.
sealed class ReservationDetailState {
  const ReservationDetailState();
}

class ReservationDetailInitial extends ReservationDetailState {
  const ReservationDetailInitial();
}

/// Đang fetch chi tiết từ API.
/// [reservation] - snapshot từ list page (nếu có) để hiển thị tạm.
class ReservationDetailLoading extends ReservationDetailState {
  final ReservationEntity? reservation;
  const ReservationDetailLoading({this.reservation});
}

/// Đã load thành công.
/// [reservation] - dữ liệu chi tiết.
/// [isFromCache] - true nếu dùng snapshot từ list page thay vì API.
/// [errorMessage] - thông báo lỗi nếu isFromCache = true.
class ReservationDetailLoaded extends ReservationDetailState {
  final ReservationEntity reservation;
  final bool isFromCache;
  final String? errorMessage;

  const ReservationDetailLoaded({
    required this.reservation,
    this.isFromCache = false,
    this.errorMessage,
  });
}

/// Lỗi khi load chi tiết (không có snapshot để fallback).
class ReservationDetailError extends ReservationDetailState {
  final String message;
  const ReservationDetailError({required this.message});
}
