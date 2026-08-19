/// Feature flag cho InGameSessionPage.
///
/// Khi backend triển khai API `/api/v1/sessions/active` thật (xem
/// `in_game_repository_impl.dart` hiện đang return mock data từ
/// `MockInGameDatasource.mockActiveSessionDetails` — danh sách player
/// "Minh Player / Thu Hà / Anh Khoa / ..."), set giá trị này thành
/// `true` để bật lại navigation từ lobby detail tới InGameSessionPage
/// (sticky banner + auto-redirect + nút "Vào phiên chơi" trong check-in
/// section).
///
/// Trong thời gian chờ backend, set `false`:
/// - Sticky banner "Mở màn hình đang chơi" bị ẩn hoàn toàn.
/// - Auto-redirect khi reservation chuyển sang `checkedIn` bị no-op.
/// - Nút "Vào phiên chơi" trong LobbyCheckInSection bị ẩn.
///
/// Lobby detail vẫn hiển thị status badge "Đang chơi" + strip "inProgress"
/// bình thường — chỉ tạm tắt đường vào màn hình in-game đang hiển thị
/// mock data.
const bool kInGameSessionEnabled = false;