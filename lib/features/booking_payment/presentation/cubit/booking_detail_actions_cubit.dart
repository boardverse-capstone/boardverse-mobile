import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rating_status_entity.dart';
import '../../domain/entities/session_status_entity.dart';
import '../../domain/repositories/booking_repository.dart';

/// Cubit phụ cho `BookingDetailPage` — handle polling session-status,
/// load rating-status, NoShow vote result. Tách khỏi `BookingResultCubit`
/// để tránh poll conflict với booking status.
///
/// State chỉ emit khi có update — page tự setState từ listener.
sealed class BookingDetailActionsState extends Equatable {
  const BookingDetailActionsState();
  @override
  List<Object?> get props => [];
}

class ActionsIdle extends BookingDetailActionsState {
  const ActionsIdle();
}

class SessionStatusLoaded extends BookingDetailActionsState {
  final SessionStatusEntity session;
  const SessionStatusLoaded(this.session);
  @override
  List<Object?> get props => [session];
}

class RatingStatusLoaded extends BookingDetailActionsState {
  final RatingStatusEntity status;
  const RatingStatusLoaded(this.status);
  @override
  List<Object?> get props => [status];
}

class ActionsFailed extends BookingDetailActionsState {
  final String message;
  const ActionsFailed(this.message);
  @override
  List<Object?> get props => [message];
}

class BookingDetailActionsCubit extends Cubit<BookingDetailActionsState> {
  final BookingRepository _repository;
  String? _bookingId;
  StreamSubscription<void>? _sessionSub;

  BookingDetailActionsCubit({required BookingRepository repository})
      : _repository = repository,
        super(const ActionsIdle());

  void attach(String bookingId) {
    _bookingId = bookingId;
    _loadRatingStatus();
  }

  void detach() {
    _bookingId = null;
    _sessionSub?.cancel();
    _sessionSub = null;
  }

  /// Poll session-status mỗi 30s khi `CheckedIn`.
  void startSessionPolling() {
    final id = _bookingId;
    if (id == null) return;
    _sessionSub?.cancel();
    _sessionSub = Stream<void>.periodic(const Duration(seconds: 30))
        .asyncMap((_) async => _repository.getSessionStatus(id))
        .listen((result) {
      result.fold(
        (_) {/* silent fail — card ẩn đi */},
        (session) {
          if (!isClosed) emit(SessionStatusLoaded(session));
        },
      );
    });
    // Trigger ngay 1 lần đầu.
    _repository.getSessionStatus(id).then((result) {
      result.fold(
        (_) {/* silent */},
        (session) {
          if (!isClosed) emit(SessionStatusLoaded(session));
        },
      );
    });
  }

  Future<void> _loadRatingStatus() async {
    final id = _bookingId;
    if (id == null) return;
    final result = await _repository.getRatingStatus(id);
    if (isClosed) return;
    result.fold(
      (_) {/* silent */},
      (status) => emit(RatingStatusLoaded(status)),
    );
  }

  void refreshRatingStatus() => _loadRatingStatus();

  @override
  Future<void> close() async {
    await _sessionSub?.cancel();
    return super.close();
  }
}