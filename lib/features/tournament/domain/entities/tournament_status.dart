/// Tournament status enum for Player mobile view.
///
/// Backend has 6 statuses: Draft, RegistrationOpen, RegistrationClosed,
/// OnGoing, Completed, Cancelled. Player mobile maps to 4 view states.
enum TournamentStatus {
  /// Backend: RegistrationOpen, deadline in future
  upcoming,

  /// Backend: RegistrationOpen, deadline not passed, still has slots
  registrationOpen,

  /// Backend: RegistrationClosed (deadline passed or manager closed)
  registrationClosed,

  /// Backend: OnGoing
  ongoing,

  /// Backend: Completed
  completed,

  /// Backend: Cancelled
  cancelled;

  String get label {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Sắp diễn ra';
      case TournamentStatus.registrationOpen:
        return 'Đang mở đăng ký';
      case TournamentStatus.registrationClosed:
        return 'Đã đóng đăng ký';
      case TournamentStatus.ongoing:
        return 'Đang diễn ra';
      case TournamentStatus.completed:
        return 'Đã kết thúc';
      case TournamentStatus.cancelled:
        return 'Đã hủy';
    }
  }

  /// Maps backend status string to this enum.
  static TournamentStatus fromBackendStatus(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return TournamentStatus.upcoming;
      case 'registrationopen':
        return TournamentStatus.registrationOpen;
      case 'registrationclosed':
        return TournamentStatus.registrationClosed;
      case 'ongoing':
        return TournamentStatus.ongoing;
      case 'completed':
        return TournamentStatus.completed;
      case 'cancelled':
        return TournamentStatus.cancelled;
      default:
        return TournamentStatus.upcoming;
    }
  }

  /// Converts to backend status string for API calls.
  String toBackendStatus() {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Draft';
      case TournamentStatus.registrationOpen:
        return 'RegistrationOpen';
      case TournamentStatus.registrationClosed:
        return 'RegistrationClosed';
      case TournamentStatus.ongoing:
        return 'OnGoing';
      case TournamentStatus.completed:
        return 'Completed';
      case TournamentStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension TournamentStatusX on TournamentStatus {
  /// Player can register when status is registrationOpen.
  bool get canRegister => this == TournamentStatus.registrationOpen;

  /// Player can withdraw when status is upcoming or registrationOpen.
  bool get canWithdraw =>
      this == TournamentStatus.upcoming ||
      this == TournamentStatus.registrationOpen;

  /// Tournament is active (open or ongoing).
  bool get isActive =>
      this == TournamentStatus.registrationOpen ||
      this == TournamentStatus.ongoing;

  /// Tournament is in a terminal state (cannot transition further).
  bool get isTerminal =>
      this == TournamentStatus.completed ||
      this == TournamentStatus.cancelled;

  /// Tournament has ended (completed or cancelled).
  bool get isPast =>
      this == TournamentStatus.completed ||
      this == TournamentStatus.cancelled;
}
