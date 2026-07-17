enum NavTab {
  home(0, 'Trang chủ'),
  bookings(1, 'Phòng chờ'),
  discovery(2, 'Khám phá'),
  tournament(3, 'Giải đấu'),
  profile(4, 'Cá nhân');

  final int tabIndex;
  final String label;

  const NavTab(this.tabIndex, this.label);
}