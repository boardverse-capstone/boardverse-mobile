import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse/features/tournament/domain/entities/tournament_waitlist_entity.dart';
import 'package:boardverse/features/tournament/domain/entities/tournament_spectator_entity.dart';
import 'package:boardverse/features/tournament/domain/repositories/tournament_repository.dart';
import 'tournament_engagement_state.dart';

/// Cubit quản lý Waitlist (T-03) + Spectator (T-04) cho một tournament.
///
/// Lifecycle:
/// - `load()`: gọi `/waitlist/me` + `/spectators/me` song song → emit Loaded.
/// - `loadWaitlistList()`: fetch danh sách waitlist public (lazy).
/// - `loadSpectatorsList()`: fetch danh sách spectators (lazy).
/// - `joinWaitlist()` / `leaveWaitlist()` / `confirmOffer()` / `declineOffer()`:
///   action trên waitlist, refresh state.
/// - `startSpectating()` / `stopSpectating()`: toggle spectate.
///
/// Mỗi action phát ra 3 state liên tiếp:
/// 1. `…ActionInProgress` (UI disable button, show spinner)
/// 2. `…Loaded` (data mới) hoặc `…Error` (giữ previous data)
/// 3. `…SuccessNotice` (optional — listener hiển thị toast rồi emit Loaded
///    lại để clear notice).
class TournamentEngagementCubit extends Cubit<TournamentEngagementState> {
  // ignore: prefer_final_fields
  final TournamentRepository _repository;
  String? _currentTournamentId;
  int _loadVersion = 0;

  TournamentEngagementCubit({required TournamentRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository,
        super(const TournamentEngagementInitial());

  String? get currentTournamentId => _currentTournamentId;

  /// Reset cubit để dùng cho tournament khác (vd navigation).
  void reset() {
    _currentTournamentId = null;
    _loadVersion++;
    emit(const TournamentEngagementInitial());
  }

  /// Load cả 2 status (waitlist + spectator) cho tournament.
  Future<void> load(String tournamentId) async {
    final loadVersion = ++_loadVersion;
    _currentTournamentId = tournamentId;
    if (isClosed) return;
    emit(const TournamentEngagementLoading());

    try {
      final waitlistResult =
          await _repository.getMyWaitlistStatus(tournamentId);
      final spectatorResult =
          await _repository.getMySpectatorStatus(tournamentId);
      if (isClosed || loadVersion != _loadVersion) return;

      final myWaitlist = waitlistResult.fold(
        (failure) => const MyWaitlistStatus(isInWaitlist: false),
        (status) => status,
      );
      final mySpectator = spectatorResult.fold(
        (failure) => const MySpectatorStatus(isSpectating: false),
        (status) => status,
      );

      emit(
        TournamentEngagementLoaded(
          tournamentId: tournamentId,
          myWaitlist: myWaitlist,
          mySpectator: mySpectator,
        ),
      );
    } catch (e) {
      if (isClosed || loadVersion != _loadVersion) return;
      emit(TournamentEngagementError(message: 'Không tải được dữ liệu: $e'));
    }
  }

  /// Lazy load danh sách waitlist public. Set trong state Loaded.
  Future<void> loadWaitlistList({
    int page = 1,
    int pageSize = 50,
  }) async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    try {
      final result = await _repository.getWaitlist(
        tournamentId,
        page: page,
        pageSize: pageSize,
      );
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          TournamentEngagementError(
            message: failure.message,
            previous: snapshot,
          ),
        ),
        (entries) => emit(
          snapshot.copyWith(waitlist: entries),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        TournamentEngagementError(
          message: 'Không tải được danh sách waitlist: $e',
          previous: snapshot,
        ),
      );
    }
  }

  /// Lazy load danh sách spectators public.
  Future<void> loadSpectatorsList() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    try {
      final result = await _repository.getSpectators(tournamentId);
      if (isClosed) return;
      result.fold(
        (failure) => emit(
          TournamentEngagementError(
            message: failure.message,
            previous: snapshot,
          ),
        ),
        (entries) => emit(
          snapshot.copyWith(spectators: entries),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        TournamentEngagementError(
          message: 'Không tải được danh sách spectators: $e',
          previous: snapshot,
        ),
      );
    }
  }

  // ─── Waitlist Actions ─────────────────────────────────────────────────

  Future<void> joinWaitlist() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.joiningWaitlist,
    ));

    final result = await _repository.joinWaitlist(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (entry) async {
        final newStatus = MyWaitlistStatus(
          isInWaitlist: true,
          entryId: entry.waitlistEntryId,
          position: entry.position,
          status: entry.status,
          joinedAt: entry.joinedAt,
          tournamentId: entry.tournamentId,
          tournamentName: entry.tournamentName,
        );
        emit(
          snapshot.copyWith(
            myWaitlist: newStatus,
            clearWaitlist: true,
          ),
        );
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã tham gia danh sách chờ.',
            action: TournamentEngagementAction.joiningWaitlist,
          ),
        );
        // Sau notice, reload để chuyển về Loaded state (UI dùng listenWhen).
        await load(tournamentId);
      },
    );
  }

  Future<void> leaveWaitlist() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.leavingWaitlist,
    ));

    final result = await _repository.leaveWaitlist(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (_) async {
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã rời khỏi danh sách chờ.',
            action: TournamentEngagementAction.leavingWaitlist,
          ),
        );
        await load(tournamentId);
      },
    );
  }

  Future<void> confirmWaitlistOffer() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.confirmingWaitlistOffer,
    ));

    final result = await _repository.confirmWaitlistOffer(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (actionResult) async {
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã xác nhận tham gia từ danh sách chờ.',
            action: TournamentEngagementAction.confirmingWaitlistOffer,
          ),
        );
        // Confirm thành công → user đã thành participant, load lại
        // để parent detail cubit cũng đồng bộ.
        await load(tournamentId);
      },
    );
  }

  Future<void> declineWaitlistOffer() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.decliningWaitlistOffer,
    ));

    final result = await _repository.declineWaitlistOffer(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (_) async {
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã từ chối offer từ danh sách chờ.',
            action: TournamentEngagementAction.decliningWaitlistOffer,
          ),
        );
        await load(tournamentId);
      },
    );
  }

  // ─── Spectator Actions ────────────────────────────────────────────────

  Future<void> startSpectating() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.startingSpectate,
    ));

    final result = await _repository.startSpectating(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (entry) async {
        emit(
          snapshot.copyWith(
            mySpectator: MySpectatorStatus(
              isSpectating: true,
              entry: entry,
            ),
            clearSpectators: true,
          ),
        );
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã bắt đầu theo dõi giải đấu.',
            action: TournamentEngagementAction.startingSpectate,
          ),
        );
      },
    );
  }

  Future<void> stopSpectating() async {
    final tournamentId = _currentTournamentId;
    if (tournamentId == null) return;
    final snapshot = state;
    if (snapshot is! TournamentEngagementLoaded) return;

    emit(_inProgress(
      snapshot,
      TournamentEngagementAction.stoppingSpectate,
    ));

    final result = await _repository.stopSpectating(tournamentId);
    if (isClosed) return;
    await result.fold(
      (failure) async => _emitErrorAfter(snapshot, failure.message),
      (_) async {
        emit(
          snapshot.copyWith(
            mySpectator: const MySpectatorStatus(isSpectating: false),
          ),
        );
        emit(
          const TournamentEngagementSuccessNotice(
            message: 'Đã rời khỏi chế độ theo dõi.',
            action: TournamentEngagementAction.stoppingSpectate,
          ),
        );
      },
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────

  TournamentEngagementActionInProgress _inProgress(
    TournamentEngagementLoaded snapshot,
    TournamentEngagementAction action,
  ) {
    return TournamentEngagementActionInProgress(
      tournamentId: snapshot.tournamentId,
      myWaitlist: snapshot.myWaitlist,
      mySpectator: snapshot.mySpectator,
      waitlist: snapshot.waitlist,
      spectators: snapshot.spectators,
      action: action,
    );
  }

  void _emitErrorAfter(
    TournamentEngagementLoaded previous,
    String message,
  ) {
    if (isClosed) return;
    emit(
      TournamentEngagementError(
        message: message,
        previous: previous,
      ),
    );
  }

  @override
  Future<void> close() {
    _loadVersion++;
    return super.close();
  }
}