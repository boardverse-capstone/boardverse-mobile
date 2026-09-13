/// Feature flag cho InGameSessionPage.
///
/// Bật = true để cho phép player truy cập màn hình in-game sau khi
/// staff check-in / mở phiên tính tiền. Backend API `GET /api/v1/
/// sessions/me/current` (xem `.agents/docs/apis_docs/player-session.md`
/// §1) đã triển khai thật và trả về:
///
/// - `costEstimate`: { baseMinutes, subtotal, penaltyAmount,
///   depositApplied, totalDue, currency }
/// - `canPay`: true khi staff đã mở phiên tính tiền từ POS
///   (`ActiveSession.Status = Unpaid`)
/// - `sessionStatus`: Active | Checking | Unpaid | Paid
///
/// UI sẽ render card "CHI PHÍ ƯỚC TÍNH" + button "Thanh toán X BVC"
/// khi `canBePaid = canPay && sessionStatus == Unpaid && !isPaid`.
/// Player có thể thanh toán qua `POST /api/v1/sessions/me/pay`.
///
/// **Auto-poll:** Cubit poll `me/current` mỗi 15s (background) để
/// nhận update khi staff thay đổi status từ POS (vd: tạo QR thanh
/// toán phiên → session chuyển sang `Unpaid` → player thấy card
/// "TỔNG CỘNG" + button thanh toán ngay trên màn hình in-game mà
/// không cần out/vào page).
const bool kInGameSessionEnabled = true;