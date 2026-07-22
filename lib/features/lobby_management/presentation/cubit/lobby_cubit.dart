import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import '../../data/lobby_persistence_service.dart';
import '../../data/realtime/lobby_realtime_service.dart';
import '../../domain/entities/lobby_entity.dart';
import '../../domain/entities/lobby_summary.dart';
import '../../domain/repositories/lobby_repository.dart';
import 'lobby_state.dart';

class LobbyCubit extends Cubit<LobbyState> {
  final LobbyRepository _repository;
  final LobbyPersistenceService _persistenceService;

  StreamSubscription? _lobbySubscription;
  StreamSubscription? _eventSubscription;
  Timer? _countdownTimer;

  /// Khoảng thời gian còn lại (để widget bind nếu cần).
  Duration _remainingTime = const Duration(minutes: 20);

  LobbyCubit({
    required this._repository,
    LobbyPersistenceService? persistenceService,
  }) : _persistenceService = persistenceService ?? LobbyPersistenceService(),
       super(const LobbyInitial());

  // ─── Create Lobby ─────────────────────────────────────────────────────

  /// Tạo lobby mới (Luồng A — lobby trước, booking sau).
  Future<void> createLobby({
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    emit(const LobbyLoading());

    final result = await _repository.createLobby(
      gameId: gameId,
      cafeId: cafeId,
      scheduledTime: scheduledTime,
      additionalSlots: additionalSlots,
      isPublic: isPublic,
      searchRadiusKm: searchRadiusKm,
      minimumKarma: minimumKarma,
      leadTime: leadTime,
    );

    if (isClosed) return;
    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      lobby,
    ) {
      _startCountdown(lobby.timeoutAt);
      _watchLobbyRealtime(lobby.id);
      _watchLobbyEvents(lobby.id);
      _persistLobby(lobby);
      emit(LobbyCreated(lobby: lobby));
    });
  }

  /// Tạo lobby gắn với booking [confirmed] có sẵn (Luồng B).
  /// BR-07: validate maxSlots ≤ bookingSeatCount ở repo; chỗ này pass qua.
  Future<void> createLobbyFromBooking({
    required String bookingId,
    required int bookingSeatCount,
    required String gameId,
    required String cafeId,
    required DateTime scheduledTime,
    required int additionalSlots,
    required bool isPublic,
    double? searchRadiusKm,
    double? minimumKarma,
    Duration? leadTime,
  }) async {
    emit(const LobbyLoading());

    final result = await _repository.createLobbyForExistingBooking(
      bookingId: bookingId,
      bookingSeatCount: bookingSeatCount,
      gameId: gameId,
      cafeId: cafeId,
      scheduledTime: scheduledTime,
      additionalSlots: additionalSlots,
      isPublic: isPublic,
      searchRadiusKm: searchRadiusKm,
      minimumKarma: minimumKarma,
      leadTime: leadTime,
    );

    if (isClosed) return;
    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      lobby,
    ) {
      _startCountdown(lobby.timeoutAt);
      _watchLobbyRealtime(lobby.id);
      _watchLobbyEvents(lobby.id);
      _persistLobby(lobby);
      emit(LobbyCreated(lobby: lobby));
    });
  }

  Future<void> _persistLobby(LobbyEntity lobby) async {
    await _persistenceService.saveActiveLobbyId(lobby.id);
    await _persistenceService.saveLobbyDetails({
      'id': lobby.id,
      'gameId': lobby.gameId,
      'gameName': lobby.gameName,
      'cafeId': lobby.cafeId,
      'cafeName': lobby.cafeName,
      'timeoutAt': lobby.timeoutAt.toIso8601String(),
      'currentPlayers': lobby.currentPlayers,
      'maxPlayers': lobby.maxPlayers,
      'isPublic': lobby.isPublic,
      'inviteCode': lobby.inviteCode,
      'minimumKarma': lobby.minimumKarma,
      'searchRadiusKm': lobby.searchRadiusKm,
    });
  }

  // ─── Join Lobby ───────────────────────────────────────────────────────

  /// Public wrapper cho page; trả `Either<Failure, LobbyEntity?>` để caller
  /// xử lý failure trực tiếp. Khi thành công trả lobby (non-null); khi
  /// failure hoặc không tìm thấy trả null.
  Future<Either<Failure, LobbyEntity?>> joinLobby(
    String lobbyId,
    String? inviteCode,
  ) async {
    emit(const LobbyLoading());

    final joinResult = await _repository.joinLobby(lobbyId, inviteCode ?? '');
    if (joinResult.isLeft()) {
      final failure = joinResult.swap().getOrElse(
        () => throw StateError('unreachable'),
      );
      if (!isClosed) emit(LobbyFailure(message: failure.message));
      return Left<Failure, LobbyEntity?>(failure);
    }

    final lobbyResult = await _repository.getLobbyById(lobbyId);
    if (isClosed) {
      return Left<Failure, LobbyEntity?>(
        const ServerFailure(message: 'Closed'),
      );
    }
    return lobbyResult.fold(
      (failure) {
        emit(LobbyFailure(message: failure.message));
        return Left<Failure, LobbyEntity?>(failure);
      },
      (lobby) {
        if (lobby == null) {
          emit(const LobbyFailure(message: 'Không tìm thấy phòng'));
          return const Right<Failure, LobbyEntity?>(null);
        }
        _startCountdown(lobby.timeoutAt);
        _watchLobbyRealtime(lobby.id);
        _watchLobbyEvents(lobby.id);
        emit(LobbyCreated(lobby: lobby));
        return Right<Failure, LobbyEntity?>(lobby);
      },
    );
  }

  /// GET /api/v1/lobbies/{id} — chỉ fetch chi tiết lobby mà không join.
  /// Dùng cho flow "Browse lobbies": user xem preview trước khi quyết định
  /// tham gia (xem `LobbyPreviewPage`).
  ///
  /// Trả `Either<Failure, LobbyEntity?>` — caller xử lý failure trực tiếp.
  /// Không emit state vì đây là read-only, không liên quan đến join flow.
  Future<Either<Failure, LobbyEntity?>> getLobbyById(String lobbyId) {
    return _repository.getLobbyById(lobbyId);
  }

  // ─── Leave Lobby ──────────────────────────────────────────────────────

  Future<void> leaveLobby(String lobbyId) async {
    _stopCountdown();
    await _lobbySubscription?.cancel();
    await _eventSubscription?.cancel();

    final result = await _repository.leaveLobby(lobbyId);
    await _persistenceService.clearAll();
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) => emit(const LobbyInitial()),
    );
  }

  // ─── Invite Friend ─────────────────────────────────────────────────────

  Future<void> inviteFriend(String lobbyId, String friendId) async {
    final result = await _repository.inviteFriend(lobbyId, friendId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) {},
    );
  }

  // ─── Host-only: close / lock / openKarmaWindow ───────────────────────

  /// Host đóng phòng thủ công (khác với hủy — chỉ set `Closed`).
  /// Spec `lobby.md:175-186`: chỉ Host, response 200.
  Future<void> closeLobby(String lobbyId) async {
    _stopCountdown();
    await _lobbySubscription?.cancel();
    await _eventSubscription?.cancel();
    await _persistenceService.clearAll();

    final result = await _repository.closeLobby(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        emit(LobbyDismissed(
          title: 'Phòng đã đóng',
          message: 'Trưởng phòng đã đóng phòng chờ.',
          reasonCode: 'HOST_CLOSED',
        ));
      },
    );
  }

  /// Host khoá phòng để chuyển sang booking flow.
  /// Spec `lobby.md:188-207`: Open → Full, broadcast `LobbyFull`.
  Future<void> lockLobby(String lobbyId) async {
    final result = await _repository.lockLobby(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        _triggerAutoBooking(lobby);
      },
    );
  }

  /// Host mở cửa sổ đánh giá Karma sau khi POS thanh toán xong.
  Future<void> openKarmaWindow(String lobbyId) async {
    final result = await _repository.openKarmaWindow(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) => emit(LobbyUpdatedRealtime(lobby: lobby)),
    );
  }

  // ─── Load Online Friends ───────────────────────────────────────────────

  Future<void> loadOnlineFriends() async {
    final currentState = state;
    if (currentState is! LobbyCreated &&
        currentState is! LobbyUpdatedRealtime) {
      return;
    }

    final lobby = currentState is LobbyCreated
        ? currentState.lobby
        : (currentState as LobbyUpdatedRealtime).lobby;

    final result = await _repository.getOnlineFriends();
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (friends) => emit(LobbyFriendsLoaded(friends: friends, lobby: lobby)),
    );
  }

  // ─── Load Simulate Friends (dev mode) ────────────────────────────────

  Future<void> loadSimulateFriends() async {
    final currentState = state;
    if (currentState is! LobbyCreated &&
        currentState is! LobbyUpdatedRealtime) {
      return;
    }

    final lobby = currentState is LobbyCreated
        ? currentState.lobby
        : (currentState as LobbyUpdatedRealtime).lobby;

    final result = await _repository.getOnlineFriends();
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (friends) =>
          emit(LobbySimulateFriendsLoaded(friends: friends, lobby: lobby)),
    );
  }

  /// Thêm friend giả lập vào lobby — chỉ dev mode (mock realtime).
  /// Sau khi thêm xong, emit `LobbyUpdatedRealtime` để UI cập nhật.
  Future<void> simulateAddFriend(String lobbyId, String friendId) async {
    final result = await _repository.simulateAddFriend(
      lobbyId: lobbyId,
      friendId: friendId,
    );
    if (isClosed) return;
    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      updatedLobby,
    ) {
      _startCountdown(updatedLobby.timeoutAt);
      emit(LobbyUpdatedRealtime(lobby: updatedLobby));
    });
  }

  // ─── Search Nearby Lobbies (BR-10) ───────────────────────────────────

  /// Tìm lobby khả dụng quanh vị trí của user.
  ///
  /// [currentUserKarma] (BR-10): điểm Karma của user hiện tại để server
  /// filter lobby có `minimumKarma <= currentUserKarma`. Caller nên lấy
  /// từ `ProfileCubit.state.profile.karmaPoints ?? 0`. Mặc định 0.
  Future<void> searchNearbyLobbies({
    required double latitude,
    required double longitude,
    LobbySearchFilter? filter,
    double currentUserKarma = 0,
  }) async {
    emit(const LobbyListLoading());

    final result = await _repository.searchNearbyLobbies(
      latitude: latitude,
      longitude: longitude,
      filter: filter ?? const LobbySearchFilter(),
      currentUserKarma: currentUserKarma,
    );

    if (isClosed) return;

    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (
      list,
    ) {
      if (list.isEmpty) {
        emit(
          const LobbyListEmpty(
            message:
                'Không có phòng nào phù hợp. Hãy thử nới rộng bán kính hoặc giảm ngưỡng Karma.',
          ),
        );
      } else {
        emit(LobbyListLoaded(lobbies: list));
      }
    });
  }

  // ─── Watch Lobby Realtime (state refresh) ────────────────────────────

  void _watchLobbyRealtime(String lobbyId) {
    _lobbySubscription?.cancel();
    _lobbySubscription = _repository
        .watchLobbyRealtime(lobbyId)
        .listen(
          (lobby) {
            _onLobbyUpdate(lobby);
          },
          onError: (error) {
            emit(LobbyFailure(message: error.toString()));
          },
        );
  }

  /// Subscribe raw realtime event để xử lý các tình huống đặc biệt:
  /// timeout / host-cancelled / booking-confirmed.
  /// Khi nhận event → emit state phù hợp (Dismissed / AutoBookingCreated).
  void _watchLobbyEvents(String lobbyId) {
    _eventSubscription?.cancel();
    _eventSubscription = _repository
        .watchLobbyEvents(lobbyId)
        .listen(
          _onLobbyEvent,
          onError: (error) {
            // Event stream errors không crash UI — chỉ ghi log.
            // Realtime state update sẽ tới qua watchLobbyRealtime.
          },
        );
  }

  Future<void> _onLobbyEvent(LobbyRealtimeEvent event) async {
    switch (event) {
      case MemberJoinedEvent _:
        // Đã được xử lý qua watchLobbyRealtime (state refetch).
        break;
      case MemberLeftEvent _:
        break;
      case LobbyFullEvent _:
        // Đã được xử lý qua `watchLobbyRealtime` (state refetch sẽ
        // phát hiện lobby chuyển sang `Full`) — handler `_onLobbyUpdate`
        // bên dưới sẽ trigger auto-booking. KHÔNG gọi `_triggerAutoBooking`
        // tại đây: backend đã tự tạo booking khi broadcast `LobbyFull`
        // và sẽ broadcast tiếp `BookingConfirmed` để navigate.
        break;
      case LobbyTimeoutEvent _:
        if (isClosed) return;
        await _persistenceService.clearAll();
        emit(LobbyDismissed(
          title: 'Hết hạn tuyển người (BR-08)',
          message:
              'Đến giờ hẹn chơi trừ đi lead-time mà phòng vẫn chưa đủ số người tối thiểu. '
              'Hệ thống đã tự động giải tán.',
          reasonCode: 'TIMEOUT_FAILED',
        ));
        break;
      case LobbyCancelledEvent e:
        if (isClosed) return;
        await _persistenceService.clearAll();
        emit(LobbyDismissed(
          title: 'Phòng đã bị huỷ',
          message: 'Lý do: ${e.reason.isEmpty ? "không rõ" : e.reason}',
          reasonCode: e.reason.isEmpty ? 'CANCELLED' : e.reason,
        ));
        break;
      case BookingConfirmedEvent e:
        if (isClosed) return;
        final s = state;
        LobbyEntity? current;
        if (s is LobbyCreated) current = s.lobby;
        if (s is LobbyUpdatedRealtime) current = s.lobby;
        if (current == null) return;
        emit(LobbyAutoBookingCreated(
          lobby: current.copyWith(bookingId: e.bookingId),
          bookingId: e.bookingId,
        ));
        break;
      case LobbyInviteReceivedEvent _:
      case InviteAcceptedEvent _:
      case InviteDeclinedEvent _:
      case InviteCancelledEvent _:
      case MatchResultSubmittedEvent _:
      case EloUpdatedEvent _:
        // Các event invite/match result được xử lý riêng trong UI.
        break;
      case NearbyLobbyCreatedEvent _:
      case NearbyLobbyRemovedEvent _:
      case NearbyLobbyUpdatedEvent _:
        // Browse broadcasts cho group location-based (NearbyLobbiesPage) —
        // không liên quan tới 1 lobby cụ thể, `LobbySearchCubit` đã
        // subscribe và tự reload list. Cubit này ignore.
        break;
    }
  }

  /// Xử lý lobby cập nhật realtime: khi lobby chuyển sang `Full` mà chưa
  /// có `bookingId`, server broadcast `LobbyFull` rồi tới `BookingConfirmed`
  /// (BR-05). Client chỉ cần:
  /// 1. Phát hiện lobby đầy → emit `LobbyReady` để UI chuyển sang booking
  ///    summary page (user sẽ xác nhận & thanh toán cọc).
  /// 2. `BookingConfirmedEvent` handler sẽ navigate sang cafe check-in.
  ///
  /// KHÔNG gọi `_triggerAutoBooking` vì backend `LobbyController` không
  /// expose `/api/v1/lobbies/{id}/auto-booking` — backend tự tạo booking
  /// nội bộ và broadcast qua SignalR.
  void _onLobbyUpdate(LobbyEntity lobby) {
    final isNowFull = lobby.currentPlayers >= lobby.maxPlayers &&
        lobby.status == LobbyStatus.full;

    if (isNowFull && lobby.bookingId == null) {
      // Lobby đầy nhưng booking chưa được tạo (server vẫn đang xử lý) →
      // emit `LobbyReady` để UI chuyển sang booking summary page.
      emit(LobbyReady(lobby: lobby));
      return;
    }

    emit(LobbyUpdatedRealtime(lobby: lobby));
  }

  Future<void> _triggerAutoBooking(LobbyEntity lobby) async {
    emit(LobbyUpdatedRealtime(lobby: lobby));

    final result = await _repository.autoCreateBookingWhenFull(lobby.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        LobbyFailure(
          message: 'Không thể tự động tạo booking: ${failure.message}',
        ),
      ),
      (bookingId) {
        final updated = lobby.copyWith(bookingId: bookingId);
        emit(LobbyAutoBookingCreated(lobby: updated, bookingId: bookingId));
      },
    );
  }

  // ─── Countdown Timer ──────────────────────────────────────────────────

  void _startCountdown(DateTime timeoutAt) {
    _countdownTimer?.cancel();
    _remainingTime = timeoutAt.difference(DateTime.now());

    if (_remainingTime <= Duration.zero) {
      Future.microtask(() => _handleLobbyTimeout());
      return;
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingTime = timeoutAt.difference(DateTime.now());

      if (_remainingTime.isNegative || _remainingTime == Duration.zero) {
        _stopCountdown();
        _handleLobbyTimeout();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  /// BR-08 client-side guard (UX hint). Server vẫn broadcast
  /// `LobbyTimeout` event để phối hợp.
  void _handleLobbyTimeout() {
    final currentState = state;
    LobbyEntity? lobby;
    if (currentState is LobbyCreated) {
      lobby = currentState.lobby;
    } else if (currentState is LobbyUpdatedRealtime) {
      lobby = currentState.lobby;
    }
    if (lobby == null) return;

    if (lobby.status != LobbyStatus.open) return;
    if (lobby.currentPlayers >= lobby.minPlayers) return;

    _repository.updateLobbyStatus(lobby.id, LobbyStatus.timeoutFailed);
    _persistenceService.clearAll();

    const reason = LobbyDismissReason(
      code: 'TIMEOUT_FAILED',
      title: 'Hết hạn tuyển người (BR-08)',
      message:
          'Đến giờ hẹn chơi trừ đi lead-time mà phòng vẫn chưa đủ số người tối thiểu. '
          'Hệ thống đã tự động giải tán để giải phóng ghế.',
    );

    emit(
      LobbyDismissed(
        title: reason.title,
        message: reason.message,
        reasonCode: reason.code,
      ),
    );
  }

  Duration get remainingTime => _remainingTime;

  // ─── Cancel Lobby ─────────────────────────────────────────────────────

  Future<void> cancelLobby(String lobbyId, String reasonCode) async {
    _stopCountdown();
    await _lobbySubscription?.cancel();
    await _eventSubscription?.cancel();
    await _persistenceService.clearAll();

    final result = await _repository.cancelLobby(lobbyId, reasonCode);
    if (isClosed) return;
    result.fold((failure) => emit(LobbyFailure(message: failure.message)), (_) {
      const reason = LobbyDismissReason(
        code: 'HOST_CANCELLED',
        title: 'Chủ phòng đã hủy',
        message: 'Trưởng phòng chờ đã chủ động giải tán phòng.',
      );
      emit(
        LobbyDismissed(
          title: reason.title,
          message: reason.message,
          reasonCode: 'HOST_CANCELLED',
        ),
      );
    });
  }

  // ─── Restore Lobby ────────────────────────────────────────────────────

  Future<void> restoreActiveLobby() async {
    final hasActiveLobby = await _persistenceService.hasActiveLobby();
    if (!hasActiveLobby) return;

    final lobbyId = await _persistenceService.getActiveLobbyId();
    if (lobbyId == null) return;

    await joinLobby(lobbyId, null);
  }

  void loadMockLobby() {
    // Legacy helper — giữ lại để các bài test trước không vỡ.
    // Phase sau sẽ bỏ nếu không cần.
    // ignore: unused_local_variable
    final _ = _repository;
  }

  @override
  Future<void> close() {
    _stopCountdown();
    _lobbySubscription?.cancel();
    _eventSubscription?.cancel();
    return super.close();
  }
}

/// Bridge: tạo Failure từ string (backward compat).
Failure buildFailure(String message) => ServerFailure(message: message);
