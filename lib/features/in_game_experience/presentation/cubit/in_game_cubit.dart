import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/mock_in_game_datasource.dart';
import '../../domain/entities/in_game_session_entity.dart';
import '../../domain/repositories/in_game_repository.dart';
import 'in_game_state.dart';

class InGameCubit extends Cubit<InGameState> {
  final InGameRepository _repository;
  Timer? _durationTimer;
  StreamSubscription? _sessionSubscription;

  InGameCubit({required this._repository}) : super(const InGameInitial());

  // ─── Check In ─────────────────────────────────────────────────────────

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

  // ─── Request Checkout ─────────────────────────────────────────────────

  Future<void> requestCheckout(String sessionId) async {
    final currentState = state;
    if (currentState is! InGameSessionActive) return;

    emit(InGameCheckingInventory(session: currentState.session));
    _durationTimer?.cancel();
  }

  // ─── Watch Session Realtime ───────────────────────────────────────────

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

  // ─── Duration Timer ──────────────────────────────────────────────────

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

  // ─── Complete Checkout ───────────────────────────────────────────────

  void completeCheckout() {
    emit(
      const InGameCheckoutComplete(
        totalAmount: 250000,
        depositPaid: 250000,
        remainingAmount: 0,
      ),
    );
  }

  // ─── End Session (Mock POS) ─────────────────────────────────────────

  void endSession() {
    _durationTimer?.cancel();
    final currentState = state;
    DateTime startTime = DateTime.now().subtract(const Duration(hours: 1));
    Duration duration = const Duration(hours: 1);

    if (currentState is InGameSessionActive) {
      startTime = currentState.session.startTime;
      duration = currentState.currentDuration;
    }

    emit(InGameSessionEnded(
      totalDuration: duration,
      startTime: startTime,
      endTime: DateTime.now(),
    ));
  }

  // ─── Load Mock Session (for development) ─────────────────────────────

  void loadMockSession() {
    final mockSession = MockInGameDatasource.mockActiveSessionDetails;
    _startDurationTimer(mockSession.toEntity());
    emit(
      InGameSessionActive(
        session: mockSession.toEntity(),
        currentDuration: mockSession.playDuration,
      ),
    );
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _sessionSubscription?.cancel();
    return super.close();
  }
}
