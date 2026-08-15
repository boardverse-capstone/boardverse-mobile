enum NavTab {
  activity(0, 'Hoạt động'),
  bookings(1, 'Lịch hẹn'),
  explore(2, 'Khám phá'),
  lobbies(3, 'Phòng chờ'),
  profile(4, 'Cá nhân');

  final int tabIndex;
  final String label;

  const NavTab(this.tabIndex, this.label);
}