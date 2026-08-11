import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
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
  // Legacy `createLobby` / `createLobbyFromBooking` đã bị xoá theo plan
  // migrate Lobby sang Reservation/BVC. Tạo lobby giờ đi qua
  // `ReservationCubit.confirmReservation()` (đặt cọc từ
  // `LobbyConfigPage` → `LobbyQuotePage` — `LobbyCreateSetupPage` đã
  // bị xoá vì bị chồng với `LobbyConfigPage`).

  Future<void> _persistLobby(LobbyEntity lobby) async {
    await _persistenceService.saveActiveLobbyId(lobby.id);
    await _persistenceService.saveLobbyDetails({
      'id': lobby.id,
      'gameId': lobby.gameId,
      'gameName': lobby.gameName,
      'cafeId': lobby.cafeId,
      'cafeName': lobby.cafeName,
      'hostId': lobby.hostId,
      'hostName': lobby.hostName,
      'status': lobby.status.name,
      'scheduledTime': lobby.scheduledTime.toIso8601String(),
      'timeoutAt': lobby.timeoutAt.toIso8601String(),
      'expiresAt': lobby.timeoutAt.toIso8601String(),
      'createdAt': lobby.createdAt.toIso8601String(),
      'currentPlayers': lobby.currentPlayers,
      'maxPlayers': lobby.maxPlayers,
      'minPlayers': lobby.minPlayers,
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
        // Lưu persistence ngay khi join — để nếu response `/lobbies/{id}`
        // không trả `hostName`/`cafeName`, các lần load sau vẫn có data
        // cached (vd: reload, restoreActiveLobby, initLobbyState merge).
        _persistLobby(lobby);
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

    // Load cached lobby trước (nếu có) — dùng làm fallback khi response
    // backend mới (`/lobbies/{id}`) không trả `hostName`, `cafeName`,
    // `inviteCode` (chỉ trả id). UI cần tên hiển thị nên merge 2 nguồn.
    await _persistenceService.loadCachedDetails();
    final cachedLobby = _persistenceService.getCachedLobbyEntity();

    // Dùng `GET /api/v1/lobbies/{lobbyId}` (chi tiết) làm nguồn chính —
    // endpoint này trả về lobby **bất kể status** (kể cả `Closed`,
    // `TimeoutFailed`, `HostCancelled`). Nhờ đó player có thể mở
    // được lobby đã hết hạn để xem chi tiết, giải tán, hoặc tạo lại.
    final result = await _repository.getLobbyById(lobbyId);

    if (isClosed) return;

    await result.fold(
      (failure) async {
        if (!isClosed) emit(LobbyFailure(message: failure.message));
      },
      (lobby) async {
        if (lobby == null) {
          if (!isClosed) {
            emit(const LobbyFailure(
              message: 'Phòng không tồn tại hoặc đã bị xoá vĩnh viễn.',
            ));
          }
          return;
        }

        // Merge field bị thiếu từ cached lobby (response `/lobbies/{id}`
        // mới không trả `hostName`, `cafeName`, `inviteCode`).
        final mergedLobby = _mergeWithCached(lobby, cachedLobby);

        if (mergedLobby.status.isTerminal) {
          // Lobby đã kết thúc — KHÔNG start realtime (server không còn
          // push event cho lobby này). Chỉ emit ended state + persist
          // để UI có thể show action bar (giải tán / tạo lại / xem chi tiết).
          await _persistenceService.saveLobbyDetails({
            'id': mergedLobby.id,
            'gameId': mergedLobby.gameId,
            'gameName': mergedLobby.gameName,
            'cafeId': mergedLobby.cafeId,
            'cafeName': mergedLobby.cafeName,
            'hostId': mergedLobby.hostId,
            'hostName': mergedLobby.hostName,
            'status': mergedLobby.status.name,
            'scheduledTime': mergedLobby.scheduledTime.toIso8601String(),
            'expiresAt': mergedLobby.timeoutAt.toIso8601String(),
            'createdAt': mergedLobby.createdAt.toIso8601String(),
            'currentPlayers': mergedLobby.currentPlayers,
            'maxPlayers': mergedLobby.maxPlayers,
            'minPlayers': mergedLobby.minPlayers,
            'isPublic': mergedLobby.isPublic,
            'inviteCode': mergedLobby.inviteCode,
          });
          if (!isClosed) emit(LobbyEnded(lobby: mergedLobby));
          return;
        }

        // Lobby còn active — sync realtime + persistence như cũ.
        _startCountdown(mergedLobby.timeoutAt);
        _watchLobbyRealtime(mergedLobby.id);
        _watchLobbyEvents(mergedLobby.id);
        _persistLobby(mergedLobby);

        if (!isClosed) {
          emit(LobbyCreated(lobby: mergedLobby));
        }
      },
    );
  }

  /// Merge field bị thiếu từ cached lobby. Response backend mới
  /// (`/lobbies/{id}`) chỉ trả id chứ không trả `hostName`, `cafeName`,
  /// `inviteCode` — fill in từ cache để UI render đúng tên.
  LobbyEntity _mergeWithCached(
    LobbyEntity fresh,
    LobbyEntity? cached,
  ) {
    if (cached == null) return fresh;
    return fresh.copyWith(
      hostName: fresh.hostName.isEmpty ? cached.hostName : fresh.hostName,
      cafeName: fresh.cafeName.isEmpty ? cached.cafeName : fresh.cafeName,
      inviteCode: fresh.inviteCode ?? cached.inviteCode,
      gameName: fresh.gameName.isEmpty ? cached.gameName : fresh.gameName,
      // scheduledTime fallback nếu response trả null/invalid (rare).
      scheduledTime: fresh.scheduledTime,
      timeoutAt: fresh.timeoutAt,
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

  /// Gửi lời mời tham gia lobby tới 1 friend.
  ///
  /// Trả về [Either<Failure, void>] để caller (UI) tự xử lý:
  /// - Success → show snackbar "Đã gửi lời mời".
  /// - Failure → show snackbar với message lỗi từ backend.
  ///
  /// QUAN TRỌNG: method này KHÔNG emit [LobbyFailure] — invite là action
  /// phụ, không được phá lobby UI hiện tại. Trước đây emit LobbyFailure
  /// khiến BlocConsumer trong LobbyPage render _LobbyFailureScaffold,
  /// lobby content biến mất → user cảm giác "bị văng khỏi phòng".
  Future<Either<Failure, void>> inviteFriend(
    String lobbyId,
    String friendId,
  ) async {
    final result = await _repository.inviteFriend(lobbyId, friendId);
    if (isClosed) {
      return const Left<Failure, void>(
        ServerFailure(message: 'Lobby cubit đã đóng'),
      );
    }
    return result;
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

  /// Host giải tán lobby (hard delete).
  /// `DELETE /api/v1/lobbies/{lobbyId}`.
  ///
  /// Khác với `closeLobby` (chỉ set Closed): endpoint này xoá vĩnh viễn
  /// lobby khỏi DB. Chỉ gọi được khi lobby chưa booking thành công.
  /// Backend trả 409 nếu lobby đã đặt cọc / đang trong phiên chơi /
  /// đã đóng — trong trường hợp đó emit `LobbyFailure` để UI hiển thị
  /// message cho player biết không thể giải tán.
  Future<void> dissolveLobby(String lobbyId, {String? reason}) async {
    _stopCountdown();
    await _lobbySubscription?.cancel();
    await _eventSubscription?.cancel();
    await _persistenceService.clearAll();

    final result = await _repository.dissolveLobby(
      lobbyId: lobbyId,
      reason: reason,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // 409: lobby đã booking / đang phiên chơi / đã đóng.
        // Hiển thị message cho player biết không thể giải tán.
        emit(LobbyFailure(message: failure.message));
      },
      (_) {
        emit(LobbyDissolved(lobbyId: lobbyId));
      },
    );
  }

  /// Host khoá phòng để chuyển sang booking flow.
  /// Spec `lobby.md:188-207`: Open → Full, broadcast `LobbyFull`.
  ///
  /// **Luồng mới (Reservation/BVC)**: Tạo booking/đặt cọc giờ đi qua
  /// `ReservationCubit` chứ không qua booking-payment cũ. Method này chỉ
  /// chuyển trạng thái lobby Open → Full, không navigate tới booking page.
  Future<void> lockLobby(String lobbyId) async {
    final result = await _repository.lockLobby(lobbyId);
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        emit(LobbyUpdatedRealtime(lobby: lobby));
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

    // Phát loading state TRƯỚC khi gọi API để UI hiển thị shimmer skeleton
    // thay cho spinner cũ — đỡ "flash" trắng khi mở FriendsSheet.
    emit(const LobbyFriendsLoading());

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
            // Realtime stream errors KHÔNG được phá lobby UI.
            //
            // Trước đây emit `LobbyFailure` ở đây khiến BlocConsumer của
            // LobbyPage render `_LobbyFailureScaffold` → toàn bộ lobby
            // content bị thay bằng màn hình lỗi, user cảm giác "bị văng
            // khỏi phòng". Nguyên nhân phổ biến:
            //   - SignalR hub bị đóng bởi server khi lobby chuyển state.
            //   - Token hết hạn trong phiên realtime dài.
            //   - Một polling async nội bộ throw.
            //
            // Hành vi đúng: log + im lặng. Nếu realtime thực sự hỏng,
            // cubit vẫn giữ state LobbyCreated/UpdatedRealtime hiện tại
            // để user tiếp tục thao tác (mời bạn, đọc thông tin...). Khi
            // user reload/refresh thủ công mới reset.
            debugPrint(
              '[LobbyCubit] watchLobbyRealtime stream error (ignored): $error',
            );
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
            debugPrint(
              '[LobbyCubit] watchLobbyEvents stream error (ignored): $error',
            );
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
      case BookingConfirmedEvent _:
        // Reservation flow mới: server push `BookingConfirmed` chỉ để UI
        // tự reload state lobby. Việc điều hướng tới booking/quote page do
        // `ReservationCubit` xử lý — không cần state trung gian từ cubit này.
        // Hiện tại bỏ qua; UI sẽ refresh qua `watchLobbyRealtime`.
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
  Future<void> kickMember(String lobbyId, String targetUserId, {String? reason}) async {
    final result = await _repository.kickMember(
      lobbyId: lobbyId,
      targetUserId: targetUserId,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) => emit(LobbyMemberKicked(
        lobby: lobby,
        kickedMemberId: targetUserId,
      )),
    );
  }

  /// Member bấm Ready/Unready khi lobby FULL.
  Future<void> setReady(String lobbyId, {required bool isReady}) async {
    final result = await _repository.setReady(
      lobbyId: lobbyId,
      isReady: isReady,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) {
        emit(LobbyReadyStatusChanged(
          lobby: lobby,
          memberId: '',
          isReady: isReady,
        ));
      },
    );
  }

  /// Report lobby vi phạm.
  Future<void> reportLobby({
    required String lobbyId,
    required String category,
    required String reason,
  }) async {
    final result = await _repository.reportLobby(
      lobbyId: lobbyId,
      category: category,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (_) => emit(const LobbyReportSubmitted()),
    );
  }

  /// Host cập nhật thông tin lobby (description, maxMembers, isPrivate, minKarmaScore).
  Future<void> updateLobby({
    required String lobbyId,
    String? description,
    int? maxMembers,
    bool? isPrivate,
    int? minKarmaScore,
  }) async {
    final result = await _repository.updateLobby(
      lobbyId: lobbyId,
      description: description,
      maxMembers: maxMembers,
      isPrivate: isPrivate,
      minKarmaScore: minKarmaScore,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(LobbyFailure(message: failure.message)),
      (lobby) => emit(LobbyUpdatedRealtime(lobby: lobby)),
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

  // ─── Cafe Approval polling (BR §5.3 + Reservation/BVC plan) ──────────

  /// Polling ngắn kết hợp realtime: lấy state mới nhất của lobby sau khi
  /// cafe duyệt / từ chối. Polling 5s/lần, dừng khi lobby không còn ở
  /// trạng thái pending.
  Future<void> loadPendingApproval(String reservationId) async {
    emit(const LobbyLoading());
    late final Timer timer;
    timer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final result = await _repository.getHostedLobbies();
      await result.fold(
        (failure) async {
          // ignore network errors — try again next tick
        },
        (lobbies) async {
          final match = lobbies.cast<LobbyEntity?>().firstWhere(
                (l) => l?.reservationId == reservationId,
                orElse: () => null,
              );
          if (match != null) {
            timer.cancel();
            _startCountdown(match.timeoutAt);
            _watchLobbyRealtime(match.id);
            _watchLobbyEvents(match.id);
            _persistLobby(match);
            if (!isClosed) emit(LobbyCreated(lobby: match));
          }
        },
      );
    });
    // Auto-cancel sau 5 phút để tránh polling vô tận.
    Future.delayed(const Duration(minutes: 5), () => timer.cancel());
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
