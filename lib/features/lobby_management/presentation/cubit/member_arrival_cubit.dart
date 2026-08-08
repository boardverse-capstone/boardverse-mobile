import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Cubit quản lý "Pre-checkin self-report" cho member: bấm nút
/// "Tôi đang trên đường" / "Tôi đã đến" → state emit → host thấy trong
/// `MembersArrivalChecklist`.
///
/// Backend hiện không có endpoint riêng (xem `mobile_gaps.md`); tạm thời
/// persist state trong cubit (in-memory + key theo userId). Khi backend
/// push endpoint (vd: `POST /api/v1/reservations/{id}/arrival`), chỉ cần
/// inject `ReservationRepository` và gọi API.
class MemberArrivalCubit extends Cubit<MemberArrivalState> {
  final String reservationId;
  final String userId;

  MemberArrivalCubit({
    required this.reservationId,
    required this.userId,
  }) : super(const MemberArrivalUnknown());

  Future<void> markEnRoute() async {
    emit(const MemberArrivalEnRoute());
  }

  Future<void> markArrived() async {
    emit(const MemberArrivalArrived());
  }

  Future<void> markCheckedIn() async {
    emit(const MemberArrivalCheckedIn());
  }
}

sealed class MemberArrivalState extends Equatable {
  const MemberArrivalState();
  @override
  List<Object?> get props => [];
}

class MemberArrivalUnknown extends MemberArrivalState {
  const MemberArrivalUnknown();
}

class MemberArrivalEnRoute extends MemberArrivalState {
  const MemberArrivalEnRoute();
}

class MemberArrivalArrived extends MemberArrivalState {
  const MemberArrivalArrived();
}

class MemberArrivalCheckedIn extends MemberArrivalState {
  const MemberArrivalCheckedIn();
}