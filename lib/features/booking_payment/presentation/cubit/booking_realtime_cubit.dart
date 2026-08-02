import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../notification/data/realtime/fcm_service.dart';
import '../../../notification/domain/realtime/fcm_push_event.dart';
import '../../data/realtime/booking_realtime_service.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/realtime/booking_realtime_events.dart';
import '../../domain/repositories/booking_repository.dart';

/// Cubit tổng hợp realtime events từ SignalR + FCM cho BookingDetailPage
/// + LobbyHubPage (gap #7 + #13 + lobby-auto-cancelled).
///
/// - SignalR `BookingRealtimeService`: realtime foreground events (page open).
/// - FCM `FcmService`: background events khi app không ở foreground.
///
/// State chỉ emit khi user-visible event tới (vd: checked-in, cancelled,
/// no-show marked) — không spam widget build cho các raw SignalR events
/// không liên quan.
class BookingRealtimeCubit extends Cubit<BookingRealtimeState> {
  final BookingRealtimeService signalR;
  final FcmService fcm;
  final BookingRepository repository;

  StreamSubscription<BookingRealtimeEvent>? _signalRSub;
  StreamSubscription<FcmPushEvent>? _fcmSub;
  String? _bookingId;
  String? _cafeId;
  String? _lobbyId;

  BookingRealtimeCubit({
    required this.signalR,
    required this.fcm,
    required this.repository,
  }) : super(const BookingRealtimeIdle());

  /// Subscribe realtime cho 1 booking cụ thể. Auto-cleanup khi cubit close.
  Future<void> watchBooking(String bookingId) async {
    _bookingId = bookingId;
    await _connectIfNeeded();
    await signalR.joinBookingGroup(bookingId);
  }

  /// Subscribe realtime cho 1 cafe (giá thay đổi).
  Future<void> watchCafe(String cafeId) async {
    _cafeId = cafeId;
    await _connectIfNeeded();
    await signalR.joinCafeGroup(cafeId);
  }

  /// Subscribe realtime cho 1 lobby (auto-cancel events).
  Future<void> watchLobby(String lobbyId) async {
    _lobbyId = lobbyId;
    await _connectIfNeeded();
    await signalR.joinLobby(lobbyId);
  }

  Future<void> _connectIfNeeded() async {
    if (signalR.isConnected) return;
    await signalR.connect();
    _signalRSub ??= signalR.events.listen(_onSignalREvent);
    _fcmSub ??= fcm.pushEvents.listen(_onFcmEvent);
  }

  void _onSignalREvent(BookingRealtimeEvent event) {
    if (event is BookingCheckedInRealtimeEvent &&
        event.bookingId == _bookingId) {
      _refreshBooking();
    } else if (event is BookingCheckedOutRealtimeEvent &&
        event.bookingId == _bookingId) {
      _refreshBooking();
    } else if (event is BookingCancelledRealtimeEvent &&
        event.bookingId == _bookingId) {
      _refreshBooking();
    } else if (event is BookingNoShowMarkedRealtimeEvent &&
        event.bookingId == _bookingId) {
      _refreshBooking();
    } else if (event is CafePricingChangedRealtimeEvent &&
        event.cafeId == _cafeId) {
      emit(CafePricingChanged(event.cafeId, event.pricing));
    } else if (event is LobbyAutoCancelledRealtimeEvent &&
        event.lobbyId == _lobbyId) {
      emit(LobbyAutoCancelledState(event.lobbyId, event.reason));
    }
  }

  void _onFcmEvent(FcmPushEvent event) {
    if (event is LobbyAutoCancelledFcmEvent) {
      emit(LobbyAutoCancelledState(event.lobbyId, event.reason));
    } else if (event is CafePricingChangedFcmEvent) {
      emit(CafePricingChanged(event.cafeId, event.pricing));
    }
  }

  Future<void> _refreshBooking() async {
    final id = _bookingId;
    if (id == null) return;
    final result = await repository.getBookingById(id);
    if (isClosed) return;
    result.fold(
      (_) {/* silent */},
      (booking) => emit(BookingRealtimeRefreshed(booking)),
    );
  }

  @override
  Future<void> close() async {
    final bid = _bookingId;
    final cid = _cafeId;
    final lid = _lobbyId;
    if (bid != null) {
      try {
        await signalR.leaveBookingGroup(bid);
      } catch (_) {}
    }
    if (cid != null) {
      try {
        await signalR.leaveCafeGroup(cid);
      } catch (_) {}
    }
    if (lid != null) {
      try {
        await signalR.leaveLobby(lid);
      } catch (_) {}
    }
    await _signalRSub?.cancel();
    await _fcmSub?.cancel();
    return super.close();
  }
}

// ─── State ─────────────────────────────────────────────────────────

sealed class BookingRealtimeState extends Equatable {
  const BookingRealtimeState();
  @override
  List<Object?> get props => [];
}

class BookingRealtimeIdle extends BookingRealtimeState {
  const BookingRealtimeIdle();
}

class BookingRealtimeRefreshed extends BookingRealtimeState {
  final BookingEntity booking;
  const BookingRealtimeRefreshed(this.booking);
  @override
  List<Object?> get props => [booking];
}

class CafePricingChanged extends BookingRealtimeState {
  final String cafeId;
  final Map<String, dynamic> pricing;
  const CafePricingChanged(this.cafeId, this.pricing);
  @override
  List<Object?> get props => [cafeId, pricing];
}

class LobbyAutoCancelledState extends BookingRealtimeState {
  final String lobbyId;
  final String reason;
  const LobbyAutoCancelledState(this.lobbyId, this.reason);
  @override
  List<Object?> get props => [lobbyId, reason];
}