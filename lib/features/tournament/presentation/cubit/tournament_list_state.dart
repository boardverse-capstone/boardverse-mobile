import 'package:equatable/equatable.dart';

import 'package:boardverse/features/tournament/domain/entities/tournament_entity.dart';

/// States for TournamentListCubit.
sealed class TournamentListState extends Equatable {
  const TournamentListState();

  @override
  List<Object?> get props => [];
}

/// Initial state.
class TournamentListInitial extends TournamentListState {
  const TournamentListInitial();
}

/// Loading state.
class TournamentListLoading extends TournamentListState {
  const TournamentListLoading();
}

/// Loaded state with tournament lists.
class TournamentListLoaded extends TournamentListState {
  /// Tournaments mở đăng ký từ `/tournaments/open`.
  /// Status = RegistrationOpen + còn slot + deadline chưa qua.
  final List<TournamentEntity> openTournaments;

  /// Reserved (backend không expose `/tournaments/upcoming`). Luôn rỗng,
  /// giữ lại để tránh vỡ các consumer cũ.
  final List<TournamentEntity> upcomingTournaments;

  /// Giải đã đóng form đăng ký (RegistrationClosed) mà player đã đăng ký.
  /// Hiển thị để player có thể xem thông tin / hủy đăng ký trước khi
  /// manager bấm Start (theo BR unregister chỉ act khi chưa OnGoing).
  final List<TournamentEntity> closedTournaments;

  /// Giải đang diễn ra (OnGoing) mà player đã đăng ký.
  final List<TournamentEntity> ongoingTournaments;

  /// Giải đã kết thúc (Completed) mà player đã tham gia.
  final List<TournamentEntity> completedTournaments;

  /// Giải đã bị hủy (Cancelled) mà player đã đăng ký. Vẫn hiển thị để
  /// player xem lại thông tin và lịch sử.
  final List<TournamentEntity> cancelledTournaments;

  final int totalOpenCount;

  const TournamentListLoaded({
    required this.openTournaments,
    required this.upcomingTournaments,
    this.closedTournaments = const [],
    this.ongoingTournaments = const [],
    this.completedTournaments = const [],
    this.cancelledTournaments = const [],
    required this.totalOpenCount,
  });

  @override
  List<Object?> get props => [
        openTournaments,
        upcomingTournaments,
        closedTournaments,
        ongoingTournaments,
        completedTournaments,
        cancelledTournaments,
        totalOpenCount,
      ];
}

/// Error state.
class TournamentListError extends TournamentListState {
  final String message;

  const TournamentListError({required this.message});

  @override
  List<Object?> get props => [message];
}
