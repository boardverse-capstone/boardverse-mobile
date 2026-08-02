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
  })  : _persistenceService = persistenceService ?? LobbyPersistenceService(),
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

  /// Initialize lobby state: dùng getJoinedLobbies() để lấy lobby đã tham gia.
  /// 
  /// QUAN TRỌNG: Khi user vào lobby từ tab "Lịch sử", user đã là member rồi.
  /// Backend đã lưu user là member của lobby này.
  /// 
  /// - Gọi GET /api/v1/lobbies/joined để lấy thông tin lobby
  /// - KHÔNG gọi joinLobby() vì user đã là member
  /// 
  /// Dùng trong LobbyPage.initState để tránh lỗi 409 khi host vào lobby của mình.
  Future<void> initLobbyState(String lobbyId, String currentUserId) async {
    emit(const LobbyLoading());

    // Gọi getJoinedLobbies - trả lobby user đã tham gia (bao gồm hosted)
    final result = await _repository.getJoinedLobbies();

    if (isClosed) return;

    await result.fold(
      (failure) async {
        if (!isClosed) emit(LobbyFailure(message: failure.message));
      },
      (lobbies) async {
        // Tìm lobby khớp với lobbyId
        final lobby = lobbies.cast<LobbyEntity?>().firstWhere(
          (l) => l?.id == lobbyId,
          orElse: () => null,
        );

        if (lobby == null) {
          if (!isClosed) {
            emit(const LobbyFailure(message: 'Phòng không tồn tại hoặc đã kết thúc'));
          }
          return;
        }

        // User đã là member (vì API /joined đã đảm bảo)
        // Chỉ cần sync state, KHÔNG gọi joinLobby
        _startCountdown(lobby.timeoutAt);
        _watchLobbyRealtime(lobby.id);
        _watchLobbyEvents(lobby.id);
        _persistLobby(lobby);
        
        if (!isClosed) {
          emit(LobbyCreated(lobby: lobby));
        }
      },
    );
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
  ///
  /// **Luồng mới**: sau khi lock, KHÔNG gọi `_triggerAutoBooking`. Host phải
  /// bấm nút "Xác nhận & Đặt cọc" → UI navigate tới BookingSummaryPage.
  Future<void> lockLobby(String lobbyId) async {
    final result = await _repository.lockLobby(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        // CHỉ emit lobby update — KHÔNG tự động tạo booking.
        // Booking sẽ được tạo khi Host bấm "Xác nhận & Đặt cọc" ở UI.
        emit(LobbyUpdatedRealtime(lobby: lobby));
      },
    );
  }

  /// Host xác nhận đặt cọc thủ công (Luồng nghiệp vụ mới).
  ///
  /// Flow:
  /// 1. Host bấm nút "Xác nhận & Đặt cọc" trên UI.
  /// 2. Client gọi `lockLobby` để chuyển status Open → Full (server broadcast
  ///    `LobbyFull` qua SignalR).
  /// 3. Sau khi lock thành công → emit `LobbyReady` để UI navigate tới
  ///    `BookingSummaryPage` (host xác nhận & thanh toán cọc).
  /// 4. UI listener `LobbyReady` → `_openBookingSummary()` → navigate.
  ///
  /// Lưu ý: Backend vẫn là nơi tạo booking (`/api/Bookings` được gọi từ
  /// BookingSummaryPage), KHÔNG tự động từ client.
  Future<void> hostConfirmAndBook(String lobbyId) async {
    final currentState = state;
    LobbyEntity? current;
    if (currentState is LobbyCreated) current = currentState.lobby;
    if (currentState is LobbyUpdatedRealtime) current = currentState.lobby;
    if (currentState is LobbyReady) current = currentState.lobby;
    if (current == null) return;

    final isFull = current.currentPlayers >= current.maxPlayers &&
        current.status == LobbyStatus.full;

    if (isFull && current.bookingId == null) {
      // Lobby đã Full sẵn (do realtime event) → emit LobbyReady trực tiếp.
      emit(LobbyReady(lobby: current));
      return;
    }

    // Lobby chưa Full → lockLobby để backend broadcast Full event.
    final result = await _repository.lockLobby(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        // Emit LobbyReady → UI listener navigate tới BookingSummaryPage.
        emit(LobbyReady(lobby: lobby));
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
    // Lấy lobby (nếu có) từ current state — dùng cho `LobbyFriendsLoaded`
    // payload để sheet có thể dùng sau. Nếu cubit chưa ở state có lobby
    // (vd: user vừa mở sheet ngay khi `initLobbyState` đang chạy, hoặc
    // realtime fail), ta vẫn load friends — không cần block.
    final currentState = state;
    final lobby = currentState is LobbyCreated
        ? currentState.lobby
        : (currentState is LobbyUpdatedRealtime)
            ? currentState.lobby
            : null;

    final result = await _repository.getOnlineFriends();
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (friends) => emit(
        lobby != null
            ? LobbyFriendsLoaded(friends: friends, lobby: lobby)
            : LobbyFriendsLoaded(friends: friends, lobby: null),
      ),
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

  /// Xử lý lobby cập nhật realtime:
  ///
  /// **Luồng nghiệp vụ mới**: Host PHẢI bấm nút "Xác nhận & Đặt cọc" thủ công
  /// thì lobby mới chuyển sang booking. KHÔNG tự động chuyển khi lobby đầy.
  ///
  /// - Khi lobby đầy (`status == Full`): KHÔNG emit `LobbyReady`, chỉ emit
  ///   `LobbyUpdatedRealtime` để UI cập nhật trạng thái & hiển thị nút bấm.
  /// - Host bấm nút → `confirmAndBook()` → gọi `lockLobby` → sau đó UI
  ///   navigate tới `BookingSummaryPage`.
  /// - `BookingConfirmedEvent` (realtime, server-side push) vẫn được xử lý
  ///   ở handler riêng — dùng làm fallback nếu server tự tạo booking.
  ///
  /// Lưu ý: Backend KHÔNG expose `/api/v1/lobbies/{id}/auto-booking` —
  /// phải dùng `/api/v1/lobbies/{id}/lock` + client-side flow.
  void _onLobbyUpdate(LobbyEntity lobby) {
    // Chỉ emit update realtime, KHÔNG auto-navigate.
    // Nút "Xác nhận & Đặt cọc" trên UI sẽ được enable khi lobby đầy +
    // user là host → bấm để trigger booking flow.
    emit(LobbyUpdatedRealtime(lobby: lobby));
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

  // ─── Host Actions ─────────────────────────────────────────────────────

  /// Host chuyển quyền host cho thành viên khác.
  Future<void> transferHost(String lobbyId, String newHostId) async {
    final result = await _repository.transferHost(
      lobbyId: lobbyId,
      newHostId: newHostId,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) => emit(LobbyHostTransferred(
        lobby: lobby,
        newHostId: newHostId,
      )),
    );
  }

  /// Host kick thành viên khỏi lobby.
  Future<void> kickMember(String lobbyId, String memberId) async {
    final result = await _repository.kickMember(
      lobbyId: lobbyId,
      memberId: memberId,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) => emit(LobbyMemberKicked(
        lobby: lobby,
        kickedMemberId: memberId,
      )),
    );
  }

  /// Member bấm Ready/Unready khi lobby FULL.
  Future<void> setReady(String lobbyId) async {
    final result = await _repository.setReady(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        // Tìm current user và emit ready status changed
        emit(LobbyReadyStatusChanged(
          lobby: lobby,
          memberId: '', // Caller nên pass thêm currentUserId
          isReady: true,
        ));
      },
    );
  }

  /// Report lobby vi phạm.
  Future<void> reportLobby({
    required String lobbyId,
    required String reason,
    String? description,
  }) async {
    final result = await _repository.reportLobby(
      lobbyId: lobbyId,
      reason: reason,
      description: description,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) => emit(const LobbyReportSubmitted()),
    );
  }

  // ─── Restore Lobby ────────────────────────────────────────────────────

  /// Khôi phục lobby đã lưu (khi app restart hoặc user out rồi vào lại).
  /// 
  /// QUAN TRỌNG: Backend đã tự động lưu user vào lobby khi:
  /// - User tạo lobby (host)
  /// - User join lobby thành công
  /// 
  /// Khi user mở app lại:
  /// 1. Gọi GET /api/v1/lobbies/joined - trả danh sách lobby user đã tham gia (bao gồm hosted)
  /// 2. Tìm lobby khớp với lobbyId đã lưu
  /// 3. Emit LobbyCreated với dữ liệu lobby
  /// 
  /// KHÔNG gọi joinLobby() vì:
  /// - User đã là member rồi → sẽ bị 409
  /// - API /joined đã đảm bảo user là member
  Future<void> restoreActiveLobby() async {
    final hasActiveLobby = await _persistenceService.hasActiveLobby();
    if (!hasActiveLobby) return;

    final lobbyId = await _persistenceService.getActiveLobbyId();
    if (lobbyId == null) return;

    emit(const LobbyLoading());

    // Gọi getJoinedLobbies - API này trả lobby user đã tham gia (bao gồm hosted)
    // Backend đảm bảo user là member của các lobby này
    final result = await _repository.getJoinedLobbies();

    if (isClosed) return;

    await result.fold(
      (failure) async {
        if (!isClosed) {
          emit(LobbyFailure(message: failure.message));
        }
      },
      (lobbies) async {
        // Tìm lobby khớp với lobbyId đã lưu
        final lobby = lobbies.cast<LobbyEntity?>().firstWhere(
          (l) => l?.id == lobbyId,
          orElse: () => null,
        );

        if (lobby == null) {
          // Không tìm thấy lobby → có thể đã bị xóa hoặc hết hạn
          await _persistenceService.clearAll();
          if (!isClosed) {
            emit(const LobbyFailure(message: 'Phòng không tồn tại hoặc đã kết thúc'));
          }
          return;
        }

        // Lobby tìm thấy → user đã là member (vì API /joined đã đảm bảo)
        // Chỉ cần sync state, KHÔNG gọi joinLobby
        _startCountdown(lobby.timeoutAt);
        _watchLobbyRealtime(lobby.id);
        _watchLobbyEvents(lobby.id);
        _persistLobby(lobby);
        
        if (!isClosed) {
          emit(LobbyCreated(lobby: lobby));
        }
      },
    );
  }

  // ─── Chat Messages ─────────────────────────────────────────────────

  /// Load chat messages cho lobby.
  Future<void> loadChatMessages(String lobbyId) async {
    final result = await _repository.getChatMessages(lobbyId: lobbyId);

    await result.fold(
      (failure) async {
        // Chat load fail không ảnh hưởng lobby state
      },
      (messages) async {
        if (!isClosed) {
          emit(LobbyChatLoaded(messages: messages));
        }
      },
    );
  }

  /// Send chat message.
  Future<void> sendChatMessage(String lobbyId, String content) async {
    if (content.trim().isEmpty) return;

    final result = await _repository.sendChatMessage(
      lobbyId: lobbyId,
      content: content.trim(),
    );

    await result.fold(
      (failure) async {
        if (!isClosed) {
          // Emit error nhưng vẫn giữ state hiện tại
          emit(LobbyChatError(message: failure.message));
        }
      },
      (message) async {
        if (!isClosed) {
          // Reload messages để cập nhật UI
          await loadChatMessages(lobbyId);
        }
      },
    );
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
