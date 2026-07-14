enum NavTab {
  discovery(0, 'Khám phá'),
  bookings(1, 'Lịch hẹn'),
  home(2, 'Trang chủ'),
  tournament(3, 'Giải đấu'),
  profile(4, 'Cá nhân');

  final int tabIndex;
  final String label;

  const NavTab(this.tabIndex, this.label);
}