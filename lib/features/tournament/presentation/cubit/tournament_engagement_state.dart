import 'package:equatable/equatable.dart';

import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';

/// State chung cho Waitlist + Spectator cubit (T-03 + T-04).
///
/// Cubit được mount ngay khi user mở [TournamentDetailPage] và load
/// đồng thời 3 thứ:
/// 1. Trạng thái waitlist của tôi (`/waitlist/me`)
/// 2. Trạng thái spectator của tôi (`/spectators/me`)
///
/// Danh sách waitlist public và danh sách spectator chỉ load khi user
/// mở detail panel riêng (xem [WaitlistListLoaded], [SpectatorsLoaded]).
sealed class TournamentEngagementState extends Equatable {
  const TournamentEngagementState();

  @override
  List<Object?> get props => [];
}

class TournamentEngagementInitial extends TournamentEngagementState {
  const TournamentEngagementInitial();
}

/// Đang load (refresh / load lần đầu).
class TournamentEngagementLoading extends TournamentEngagementState {
  const TournamentEngagementLoading();
}

/// Loaded thành công. Subset nào còn null là subset chưa được tải lần
/// nào (vd chưa mở panel) hoặc API trả `null`.
class TournamentEngagementLoaded extends TournamentEngagementState {
  final String tournamentId;

  /// Trạng thái waitlist của tôi (luôn được set sau load).
  final MyWaitlistStatus myWaitlist;

  /// Trạng thái spectator của tôi (luôn được set sau load).
  final MySpectatorStatus mySpectator;

  /// Snapshot danh sách waitlist public (optional — chỉ load khi cần).
  final List<TournamentWaitlistEntry>? waitlist;

  /// Snapshot danh sách spectators (optional — chỉ load khi cần).
  final List<TournamentSpectatorEntry>? spectators;

  const TournamentEngagementLoaded({
    required this.tournamentId,
    required this.myWaitlist,
    required this.mySpectator,
    this.waitlist,
    this.spectators,
  });

  TournamentEngagementLoaded copyWith({
    MyWaitlistStatus? myWaitlist,
    MySpectatorStatus? mySpectator,
    List<TournamentWaitlistEntry>? waitlist,
    List<TournamentSpectatorEntry>? spectators,
    bool clearWaitlist = false,
    bool clearSpectators = false,
  }) {
    return TournamentEngagementLoaded(
      tournamentId: tournamentId,
      myWaitlist: myWaitlist ?? this.myWaitlist,
      mySpectator: mySpectator ?? this.mySpectator,
      waitlist: clearWaitlist ? null : (waitlist ?? this.waitlist),
      spectators:
          clearSpectators ? null : (spectators ?? this.spectators),
    );
  }

  @override
  List<Object?> get props => [
        tournamentId,
        myWaitlist,
        mySpectator,
        waitlist,
        spectators,
      ];
}

/// Khi một action (join waitlist / leave / start spectate / stop) đang
/// pending — UI nên disable button và hiển thị spinner inline.
class TournamentEngagementActionInProgress
    extends TournamentEngagementLoaded {
  final TournamentEngagementAction action;

  const TournamentEngagementActionInProgress({
    required super.tournamentId,
    required super.myWaitlist,
    required super.mySpectator,
    required this.action,
    super.waitlist,
    super.spectators,
  });

  @override
  List<Object?> get props => [...super.props, action];
}

enum TournamentEngagementAction {
  joiningWaitlist,
  leavingWaitlist,
  confirmingWaitlistOffer,
  decliningWaitlistOffer,
  startingSpectate,
  stoppingSpectate,
}

extension TournamentEngagementActionX on TournamentEngagementAction {
  String get label {
    switch (this) {
      case TournamentEngagementAction.joiningWaitlist:
        return 'Đang tham gia waitlist…';
      case TournamentEngagementAction.leavingWaitlist:
        return 'Đang rời waitlist…';
      case TournamentEngagementAction.confirmingWaitlistOffer:
        return 'Đang xác nhận…';
      case TournamentEngagementAction.decliningWaitlistOffer:
        return 'Đang từ chối…';
      case TournamentEngagementAction.startingSpectate:
        return 'Đang theo dõi…';
      case TournamentEngagementAction.stoppingSpectate:
        return 'Đang rời khỏi…';
    }
  }
}

/// State lỗi — khi load hoặc action fail.
class TournamentEngagementError extends TournamentEngagementState {
  final String message;

  /// Snapshot state trước đó (nếu có) để UI vẫn render được data cũ.
  final TournamentEngagementLoaded? previous;

  const TournamentEngagementError({
    required this.message,
    this.previous,
  });

  @override
  List<Object?> get props => [message, previous];
}

/// Snackbar / Toast transient — thông báo action thành công. UI có thể
/// listen [BlocListener] để hiển thị rồi discard.
class TournamentEngagementSuccessNotice extends TournamentEngagementState {
  final String message;
  final TournamentEngagementAction action;

  const TournamentEngagementSuccessNotice({
    required this.message,
    required this.action,
  });

  @override
  List<Object?> get props => [message, action];
}