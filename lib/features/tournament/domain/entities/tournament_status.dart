enum TournamentStatus {
  upcoming,
  registrationOpen,
  ongoing,
  finished;

  String get label {
    switch (this) {
      case TournamentStatus.upcoming:
        return 'Sắp diễn ra';
      case TournamentStatus.registrationOpen:
        return 'Đang mở đăng ký';
      case TournamentStatus.ongoing:
        return 'Đang diễn ra';
      case TournamentStatus.finished:
        return 'Đã kết thúc';
    }
  }
}

extension TournamentStatusX on TournamentStatus {
  bool get isOpen => this == TournamentStatus.registrationOpen;
  bool get isPast => this == TournamentStatus.finished;
  bool get isActive =>
      this == TournamentStatus.ongoing || this == TournamentStatus.registrationOpen;
}
