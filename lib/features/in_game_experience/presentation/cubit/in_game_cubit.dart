import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/in_game_session_entity.dart';
import '../../domain/entities/player_session_entity.dart';
import '../../domain/repositories/in_game_repository.dart';
import 'in_game_state.dart';

class InGameCubit extends Cubit<InGameState> {
  final InGameRepository _repository;
  Timer? _durationTimer;
  StreamSubscription? _sessionSubscription;
  Timer? _pollingTimer;

  InGameCubit({required this._repository}) : super(const InGameInitial());

  // ─── Load Current Session (API) ─────────────────────────────────────────

  /// Load phiên chơi hiện tại từ API
  Future<void> loadCurrentSession() async {
    emit(const InGameLoading());

    final result = await _repository.getCurrentSession();

    result.fold(
      (failure) {
        if (failure.message.contains('Không có phiên chơi')) {
          emit(const InGameNoActiveSession());
        } else {
          emit(InGameFailure(message: failure.message));
        }
      },
      (session) {
        // Lưu session để dùng cho timer
        _lastLoadedSession = session;
        // Dùng `totalMinutesPlayed` thay vì `elapsedMinutes` để phản
        // ánh đúng thời gian thực chơi. `elapsedMinutes` bao gồm cả
        // thời gian bị tạm dừng (suspended/paused) — vd: staff kiểm
        // kê linh kiện → session bị pause → elapsed tăng nhưng played không.
        // Player thấy timer chạy đúng thời gian họ ngồi chơi.
        _startPlayerSessionTimer(session.totalMinutesPlayed);
        // Chỉ watch session khi cần refresh data (không cần polling duration nữa)
        // _watchPlayerSession();
        emit(
          InGamePlayerSessionLoaded(
            session: session,
            currentDuration: Duration(minutes: session.totalMinutesPlayed),
          ),
        );
      },
    );
  }

  // ─── Extend Session ─────────────────────────────────────────────────────

  /// Yêu cầu gia hạn thêm thời gian
  Future<void> extendSession(int minutes) async {
    final currentState = state;
    if (currentState is! InGamePlayerSessionLoaded) return;

    emit(
      InGameExtending(
        session: currentState.session,
        currentDuration: currentState.currentDuration,
        requestedMinutes: minutes,
      ),
    );

    final result = await _repository.requestExtension(minutes);

    result.fold(
      (failure) {
        // Quay lại state trước đó khi có lỗi
        emit(
          InGamePlayerSessionLoaded(
            session: currentState.session,
            currentDuration: currentState.currentDuration,
          ),
        );
        // Có thể emit một state lỗi riêng để hiển thị
        emit(InGameFailure(message: failure.message));
      },
      (extensionRequest) {
        // Reload session để lấy thông tin mới nhất
        loadCurrentSession();
      },
    );
  }

  // ─── Pay with BVC ───────────────────────────────────────────────────────

  /// Thanh toán phiên chơi bằng BVC
  Future<void> payWithBvc() async {
    final currentState = state;
    if (currentState is! InGamePlayerSessionLoaded) return;
    if (!currentState.session.canBePaid) return;

    emit(
      InGamePaymentProcessing(
        session: currentState.session,
        currentDuration: currentState.currentDuration,
      ),
    );

    final result = await _repository.payWithBvc(currentState.session.sessionId);

    result.fold(
      (failure) {
        emit(
          InGamePaymentFailure(
            session: currentState.session,
            currentDuration: currentState.currentDuration,
            message: failure.message,
            requiredBvc: _extractRequiredBvc(failure.message),
          ),
        );
      },
      (paymentResult) {
        // Reload session để lấy thông tin thanh toán mới
        loadCurrentSession();
      },
    );
  }

  int? _extractRequiredBvc(String message) {
    // Try to extract BVC number from message
    final match = RegExp(r'(\d+)\s*BVC').firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '');
    }
    return null;
  }

  // ─── Refresh Session Manually ───────────────────────────────────────────

  /// Refresh session data when needed (e.g., after extension/payment)
  Future<void> refreshSession() async {
    await _refreshSession();
  }

  Future<void> _refreshSession() async {
    final result = await _repository.getCurrentSession();

    result.fold(
      (failure) {
        // Ignore refresh failures, just keep current state
      },
      (session) {
        final currentState = state;
        if (currentState is InGamePlayerSessionLoaded) {
          emit(
            InGamePlayerSessionLoaded(
              session: session,
              currentDuration: Duration(minutes: session.elapsedMinutes),
            ),
          );
        }
      },
    );
  }

  // ─── Check In (Legacy) ──────────────────────────────────────────────────

  Future<void> checkIn(String bookingId) async {
    emit(const InGameLoading());

    final result = await _repository.checkIn(bookingId: bookingId);

    result.fold((failure) => emit(InGameFailure(message: failure.message)), (
      session,
    ) {
      _startDurationTimer(session);
      _watchSession(session.sessionId);
      emit(
        InGameSessionActive(
          session: session,
          currentDuration: session.playDuration,
        ),
      );
    });
  }

  // ─── Request Checkout (Legacy) ─────────────────────────────────────────

  Future<void> requestCheckout(String sessionId) async {
    final currentState = state;
    if (currentState is! InGameSessionActive) return;

    emit(InGameCheckingInventory(session: currentState.session));
    _durationTimer?.cancel();
  }

  // ─── Watch Session Realtime (Legacy) ────────────────────────────────────

  void _watchSession(String sessionId) {
    _sessionSubscription?.cancel();
    _sessionSubscription = _repository
        .watchSession(sessionId)
        .listen(
          (session) {
            final currentState = state;
            if (currentState is InGameSessionActive) {
              emit(
                InGameSessionActive(
                  session: session,
                  currentDuration: currentState.currentDuration,
                ),
              );
            }
          },
          onError: (error) {
            emit(InGameFailure(message: error.toString()));
          },
        );
  }

  // ─── Duration Timer (Legacy) ────────────────────────────────────────────

  void _startDurationTimer(InGameSessionEntity session) {
    _durationTimer?.cancel();
    var duration = session.playDuration;

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      duration += const Duration(seconds: 1);
      final currentState = state;
      if (currentState is InGameSessionActive) {
        emit(
          InGameSessionActive(
            session: currentState.session,
            currentDuration: duration,
          ),
        );
      }
    });
  }

  // ─── Duration Timer (Player Session) ────────────────────────────────────

  void _startPlayerSessionTimer(int initialMinutes) {
    _durationTimer?.cancel();
    // joinedAtOffset là thời điểm player bắt đầu chơi (có timezone)
    final startTime = _lastLoadedSession?.joinedAtOffset ?? DateTime.now();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentState = state;
      if (currentState is InGamePlayerSessionLoaded) {
        // Tính duration từ joinedAtOffset đến hiện tại
        final duration = DateTime.now().difference(startTime);
        emit(
          InGamePlayerSessionLoaded(
            session: currentState.session,
            currentDuration: duration,
          ),
        );
      }
    });
  }

  /// Lưu session cuối cùng được load để dùng cho timer
  PlayerSessionEntity? _lastLoadedSession;

  // ─── Complete Checkout (Legacy) ─────────────────────────────────────────

  void completeCheckout() {
    emit(
      const InGameCheckoutComplete(
        totalAmount: 250000,
        depositPaid: 250000,
        remainingAmount: 0,
      ),
    );
  }

  // ─── End Session (Legacy) ───────────────────────────────────────────────

  void endSession() {
    _durationTimer?.cancel();
    final currentState = state;
    DateTime startTime = DateTime.now().subtract(const Duration(hours: 1));
    Duration duration = const Duration(hours: 1);

    if (currentState is InGameSessionActive) {
      startTime = currentState.session.startTime;
      duration = currentState.currentDuration;
    }

    emit(
      InGameSessionEnded(
        totalDuration: duration,
        startTime: startTime,
        endTime: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _sessionSubscription?.cancel();
    _pollingTimer?.cancel();
    _splitBillPollingTimer?.cancel();
    return super.close();
  }

  // ─── Split Bill Methods ────────────────────────────────────────────────────

  /// Timer cho việc polling payment status
  Timer? _splitBillPollingTimer;
  static const int _maxPollAttempts = 60; // Poll tối đa 60 lần (~5 phút với 5s interval)
  static const Duration _pollInterval = Duration(seconds: 5);

  /// Lưu state session trước khi mở split bill để khôi phục lại
  PlayerSessionEntity? _savedSessionForSplitBill;
  Duration _savedDurationForSplitBill = Duration.zero;

  /// Mở màn hình Split Bill - lấy thông tin chia bill
  Future<void> openSplitBill() async {
    // Lưu lại state hiện tại để khôi phục
    final currentState = state;
    if (currentState is InGamePlayerSessionLoaded) {
      _savedSessionForSplitBill = currentState.session;
      _savedDurationForSplitBill = currentState.currentDuration;
    }

    PlayerSessionEntity? session;
    Duration currentDuration = Duration.zero;

    if (currentState is InGamePlayerSessionLoaded) {
      session = currentState.session;
      currentDuration = currentState.currentDuration;
    } else {
      // Load session nếu chưa có
      final result = await _repository.getCurrentSession();
      result.fold(
        (failure) {
          emit(InGameFailure(message: failure.message));
        },
        (loadedSession) {
          session = loadedSession;
          currentDuration = Duration(minutes: loadedSession.elapsedMinutes);
        },
      );
    }

    if (session == null) return;

    emit(const InGameSplitBillLoading());

    final result = await _repository.getSplitBillMembers();

    result.fold(
      (failure) {
        if (failure.message.contains('Không tìm thấy')) {
          emit(InGameSplitBillNotFound(
            session: session!,
            currentDuration: currentDuration,
            message: failure.message,
          ));
        } else {
          emit(InGameSplitBillError(
            session: session!,
            currentDuration: currentDuration,
            message: failure.message,
          ));
        }
      },
      (members) {
        final currentUserPayment = members.where((m) => m.isCurrentUser).firstOrNull;
        emit(InGameSplitBillLoaded(
          session: session!,
          currentDuration: currentDuration,
          members: members,
          currentUserPayment: currentUserPayment,
        ));
      },
    );
  }

  /// Khôi phục lại state session sau khi đóng split bill
  void restoreSessionAfterSplitBill() {
    if (_savedSessionForSplitBill != null) {
      emit(InGamePlayerSessionLoaded(
        session: _savedSessionForSplitBill!,
        currentDuration: _savedDurationForSplitBill,
      ));
      _savedSessionForSplitBill = null;
    }
  }

  /// Bắt đầu polling để kiểm tra thanh toán QR
  void startQrPaymentPolling(MemberPaymentInfo paymentInfo) {
    final currentState = state;
    if (currentState is! InGameSplitBillLoaded) return;
    if (paymentInfo.isPaid) {
      // Đã thanh toán rồi
      emit(InGameSplitBillPaymentSuccess(
        session: currentState.session,
        currentDuration: currentState.currentDuration,
        paymentInfo: paymentInfo,
      ));
      return;
    }

    emit(InGameSplitBillPolling(
      session: currentState.session,
      currentDuration: currentState.currentDuration,
      currentUserPayment: paymentInfo,
      pollCount: 0,
    ));

    _performQrPoll();
  }

  /// Thực hiện một lần poll
  Future<void> _performQrPoll() async {
    final currentState = state;
    if (currentState is! InGameSplitBillPolling) return;

    // Tăng số lần poll
    final newPollCount = currentState.pollCount + 1;

    // Kiểm tra nếu đã quá số lần poll tối đa
    if (newPollCount > _maxPollAttempts) {
      emit(InGameSplitBillError(
        session: currentState.session,
        currentDuration: currentState.currentDuration,
        message: 'Đã hết thời gian chờ thanh toán. Vui lòng thử lại.',
      ));
      return;
    }

    // Gọi API để lấy thông tin thanh toán mới nhất
    final result = await _repository.getMyMemberPaymentInfo();

    result.fold(
      (failure) {
        // Tiếp tục poll nếu có lỗi tạm thời
        _scheduleNextPoll(newPollCount);
      },
      (paymentInfo) {
        if (paymentInfo.isPaid) {
          // Thanh toán thành công!
          emit(InGameSplitBillPaymentSuccess(
            session: currentState.session,
            currentDuration: currentState.currentDuration,
            paymentInfo: paymentInfo,
          ));
          _splitBillPollingTimer?.cancel();
        } else {
          // Tiếp tục poll
          emit(InGameSplitBillPolling(
            session: currentState.session,
            currentDuration: currentState.currentDuration,
            currentUserPayment: paymentInfo,
            pollCount: newPollCount,
          ));
          _scheduleNextPoll(newPollCount);
        }
      },
    );
  }

  void _scheduleNextPoll(int pollCount) {
    _splitBillPollingTimer?.cancel();
    _splitBillPollingTimer = Timer(_pollInterval, () {
      _performQrPoll();
    });
  }

  /// Dừng polling
  void stopQrPaymentPolling() {
    _splitBillPollingTimer?.cancel();
    // Quay lại state loaded
    final currentState = state;
    if (currentState is InGameSplitBillPolling) {
      emit(InGameSplitBillLoaded(
        session: currentState.session,
        currentDuration: currentState.currentDuration,
        members: const [],
        currentUserPayment: currentState.currentUserPayment,
      ));
    }
  }

  /// Refresh thông tin Split Bill
  Future<void> refreshSplitBill() async {
    await openSplitBill();
  }

  // ─── Session Polling (Background refresh) ───────────────────────────────

  /// Bật polling định kỳ gọi `GET /api/v1/sessions/me/current` (mỗi 15s)
  /// để nhận update từ POS — quan trọng khi staff:
  ///
  ///   1. Check-in: `memberStatus: SuspendedMutation → Playing`.
  ///   2. Mở phiên tính tiền: `sessionStatus: Active → Unpaid`,
  ///      `canPay: false → true` → player thấy card "CHI PHÍ ƯỚC TÍNH"
  ///      + button "Thanh toán X BVC" ngay trên màn hình in-game.
  ///   3. Manual confirm phiên đã thanh toán: `sessionStatus: Unpaid →
  ///      Paid`, `isPaid: false → true` → poll tự dừng.
  ///
  /// Mỗi tick gọi `refreshSession()` (silent — không emit loading).
  /// Polling tự dừng khi:
  ///   - `session.isPaid == true` (UI đã chuyển sang trạng thái Paid).
  ///   - Session không còn tồn tại (404 → NoActiveSession).
  ///
  /// Polling interval 15s là cân bằng giữa:
  ///   - Latency: player nhận update trong ≤ 15s sau khi staff thao tác.
  ///   - Server load: 4 calls/min/user — không quá tải SePay/webhook.
  void startSessionPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      final currentState = state;
      // Stop khi session đã paid (UI đã settle, không cần poll).
      if (currentState is InGamePlayerSessionLoaded &&
          currentState.session.isPaid) {
        stopSessionPolling();
        return;
      }
      // Skip khi đang xử lý các flow khác (extend/payment/split bill).
      if (currentState is InGameExtending ||
          currentState is InGamePaymentProcessing ||
          currentState is InGameSplitBillPolling) {
        return;
      }
      await refreshSession();
    });
  }

  /// Dừng polling session.
  void stopSessionPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }
}
