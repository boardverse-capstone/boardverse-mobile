/// Domain entities cho realtime SignalR events (booking + cafe + lobby).
///
/// Mirror `.agents/docs/apis_docs/lobby-hub.md` §37-60 + booking.md §84-120
/// + cafe-booking.md §65-72.
library;

sealed class BookingRealtimeEvent {
  final DateTime timestamp;

  /// Constructor mặc định — không có timestamp = `DateTime.now()`.
  BookingRealtimeEvent({DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '${runtimeType.toString()}($timestamp)';
}

// ─── Booking events (gap #7) ─────────────────────────────────────────

/// POS Staff scan QR → server set `Booking.status = CheckedIn`.
class BookingCheckedInRealtimeEvent extends BookingRealtimeEvent {
  final String bookingId;
  final DateTime? checkedInAt;
  final String? checkedInByUserId;
  BookingCheckedInRealtimeEvent({
    required this.bookingId,
    this.checkedInAt,
    this.checkedInByUserId,
    super.timestamp,
  });
}

/// POS Staff checkout xong → server set `Booking.status = Paid/Cancelled`
/// + deposit refund flow.
class BookingCheckedOutRealtimeEvent extends BookingRealtimeEvent {
  final String bookingId;
  final String? activeSessionId;
  BookingCheckedOutRealtimeEvent({
    required this.bookingId,
    this.activeSessionId,
    super.timestamp,
  });
}

/// Player hoặc Manager cancel booking (realtime).
class BookingCancelledRealtimeEvent extends BookingRealtimeEvent {
  final String bookingId;
  final String reason;
  BookingCancelledRealtimeEvent({
    required this.bookingId,
    required this.reason,
    super.timestamp,
  });
}

/// Server đánh dấu 1+ members là No-show sau khi tổng hợp vote.
class BookingNoShowMarkedRealtimeEvent extends BookingRealtimeEvent {
  final String bookingId;
  final List<String> noShowMemberIds;
  BookingNoShowMarkedRealtimeEvent({
    required this.bookingId,
    required this.noShowMemberIds,
    super.timestamp,
  });
}

// ─── Cafe pricing (gap #13) ─────────────────────────────────────────

class CafePricingChangedRealtimeEvent extends BookingRealtimeEvent {
  final String cafeId;

  /// Pricing config mới (JSON-like Map để linh hoạt với schema backend).
  final Map<String, dynamic> pricing;
  CafePricingChangedRealtimeEvent({
    required this.cafeId,
    required this.pricing,
    super.timestamp,
  });
}

// ─── Lobby realtime (Bonus — track auto-cancel cho lobby) ──────────

class LobbyAutoCancelledRealtimeEvent extends BookingRealtimeEvent {
  final String lobbyId;
  final String reason;
  LobbyAutoCancelledRealtimeEvent({
    required this.lobbyId,
    required this.reason,
    super.timestamp,
  });
}