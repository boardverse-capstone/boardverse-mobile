# Context Handover — Tiếp quản Plan: Hoàn thiện Booking & Payment

> **Mục đích:** File này lưu lại toàn bộ context, phân tích và kết luận từ đoạn chat trước, để đoạn chat **mới** có thể đọc hiểu và **thực thi plan** ngay lập tức mà không cần phải đào lại codebase.
>
> **Ngày tạo:** 2026-08-01
> **Plan gốc:** `c:\Users\PC\.cursor\plans\hoan-thien-booking-payment_9983f077.plan.md`
> **Workspace:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile`

---

## 1. Tóm tắt dự án

**BoardVerse** là hệ thống đặt chỗ board game cho player mobile, gồm:
- **Frontend:** Flutter Android (iOS có folder nhưng chưa config).
- **Backend:** .NET (swagger đầy đủ tại `.agents/docs/swagger.json`).
- **Spec nghiệp vụ:** `.agents/docs/matchmaking_booking_module/bussiness_rule.md` + `mobile_tasks.md`.

**Module cần sửa:** `lib/features/booking_payment/` — flow Lobby → Booking → Cọc SePay → Check-in → NoShow.

**Trạng thái hiện tại:** Backend đã sẵn sàng cho happy path. Mobile đã wire được ~80% code, nhưng còn **11 tasks** (chia 4 phase) cần xử lý để chạy trọn flow.

---

## 2. Plan gốc (TL;DR)

| Phase | Task | Mô tả ngắn | Priority |
|-------|------|------------|----------|
| 1 | 1.1 | Xóa `confirmBookingPayment` (method không tồn tại ở backend) | Critical |
| 1 | 1.2 | Truyền `cafeTableId` thật cho `BookingSummaryPage` (cần build datasource mới) | Critical |
| 1 | 1.3 | Verify `PaymentPage` gọi SePay flow thật | Critical |
| 2 | 2.1 | Deep-link handler cho SePay return URL (`boardverse://payment/return`) | High |
| 2 | 2.2 | Refactor resume flow ưu tiên `pendingDepositId` | High |
| 2 | 2.3 | NoShow badge + Cancel UX cho booking confirmed | High |
| 3 | 3.1 | Walk-in vs Booking suggestion theo cafe availability | Polish |
| 3 | 3.2 | Schedule end time picker (player chọn khung giờ) | Polish |
| 3 | 3.3 | Refund status UI cho player xem đã hoàn cọc chưa | Polish |
| 4 | 4.1 | `dart analyze` pass | Validate |
| 4 | 4.2 | Smoke test integration end-to-end | Validate |

**Strategy đã chốt với user:** `single_default` — Table UI chỉ 1 bước (sau lobby confirm), KHÔNG làm multi-step search/filter.

**Tổng ước tính:** ~5.5 giờ dev (chưa tính Task 1.2 build datasource mới).

---

## 3. Phát hiện quan trọng từ quá trình research

### 3.1. Code đã có sẵn (KHÔNG cần viết lại)

User đã wire ~80% code. Các file sau **đã đầy đủ**, chỉ cần sửa/tweak:

- `lib/features/booking_payment/data/datasources/remote/booking_remote_datasource_impl.dart` — đã có đầy đủ methods: `getDepositConfig`, `createBooking`, `getBookingById`, `getBookingByLobby`, `cancelBookingByPlayer`, `createDepositPayment`, `createDepositPaymentWithDetails`, `getDepositStatus`, `getDepositByOrder`, `regenerateDepositQr`, `refundDeposit`, `getLobbyBookingSummary`, `getHostedLobbyIds`, `getJoinedLobbyIds`, `noopHistoryShim`.
- `lib/features/booking_payment/data/datasources/remote/payment_remote_datasource.dart` — riêng, có đầy đủ methods + `mockSepayWebhook` cho dev.
- `lib/features/booking_payment/data/datasources/gateway/sepay_payment_gateway.dart` — flow SePay đúng: `openGateway` → `launchUrl` + `watchResult` polling 3s.
- `lib/features/booking_payment/presentation/cubit/payment_cubit.dart` — có `start()`, `cancelByUser()`, `forceRetry()`, `regenerateQr()`, countdown timer, expiration handler (cancel booking khi hết hạn).
- `lib/features/booking_payment/presentation/cubit/booking_summary_cubit.dart` — đã nhận `cafeTableId` parameter (line 58), đang chờ đầu vào thực.
- `lib/features/booking_payment/presentation/cubit/booking_history_cubit.dart` — load all + history.
- `lib/features/booking_payment/data/booking_persistence_service.dart` — `pendingBookingId` + `pendingDepositId` keys.
- `lib/features/booking_payment/domain/enums/booking_status.dart` — đã có `noShow` trong enum.
- `lib/features/booking_payment/domain/entities/booking_entity.dart` — đủ fields cho happy path.
- `lib/features/booking_payment/presentation/pages/booking_detail_page.dart` — đã có UI NoShow detection (`_buildTerminalMessage` switch), nhưng `_isTerminal` logic sai (đang include `pendingDeposit`).
- `lib/features/booking_payment/presentation/pages/booking_history_page.dart` — đã phân 2 tab "Sắp tới" / "Lịch sử".
- `lib/core/navigation/pages/bookings_page.dart` — TAB "Lịch đặt" đã được implement đầy đủ (KHÔNG còn placeholder), có banner resume pending booking.
- `lib/core/di/injection.dart` line 228-276 — DI đã wire đủ: `BookingRemoteDatasource`, `PaymentRemoteDatasource`, `PaymentGateway`, `BookingRepository`, `BookingPersistenceService`, `BookingPersistenceResumeHelper`, và 4 cubits (`BookingSummaryCubit`, `PaymentCubit`, `BookingResultCubit`, `BookingHistoryCubit`).

### 3.2. Vấn đề code-behind đã xác định (cần fix)

| # | File | Line | Vấn đề |
|---|------|------|--------|
| A | `lib/features/lobby_management/presentation/pages/lobby_page.dart` | 334, 365 | `cafeTableId: ''` (rỗng) → backend sẽ 400 |
| B | `lib/features/matchmaking_discovery/presentation/pages/board_game_detail_page.dart` | 189-204, 426-441 | `cafeTableId: ''` (rỗng) tại 2 entry points |
| C | `lib/features/booking_payment/data/booking_repository_impl.dart` | cần grep | `confirmBookingPayment` method (không tồn tại ở backend) |
| D | `lib/features/booking_payment/presentation/pages/booking_detail_page.dart` | 89-92 | `_isTerminal` sai (include `pendingDeposit`) |
| E | `lib/features/booking_payment/presentation/cubit/booking_result_cubit.dart` | — | `tryRestorePending()` chỉ check `pendingBookingId`, chưa ưu tiên `pendingDepositId` |
| F | `lib/features/booking_payment/presentation/pages/booking_detail_page.dart` | 336-341 | `_buildTerminalMessage` switch dùng `status.name` string → không type-safe |

### 3.3. Backend gaps (file docs riêng)

User đã tạo file `.agents/docs/apis_docs/booking-payment-gaps.md` (722 dòng) mô tả 15 backend gaps. **KHÔNG nằm trong scope plan này** — backend team sẽ xử lý sau. Mobile team chỉ cần:

- **Có thể block flow:** Gap #1 (`GET /available-tables`), Gap #6 (AuthZ Player GET deposit), Gap #15 (validate `playerQuantity`).
- **Có fallback OK:** Nếu backend chưa có `GET /available-tables`, mobile vẫn chạy được bằng cách gửi `cafeTableId` từ lobby data (nếu lobby response có). Nếu không có → dùng strategy `single_default` — backend auto-assign (cần backend support).

---

## 4. Quyết định kiến trúc đã chốt

### 4.1. Strategy: `single_default` (table resolution)

Theo câu trả lời của user từ đoạn chat trước (chọn option `single_default` trong AskQuestion):

- Player chỉ chọn 1 bước (sau lobby confirm).
- KHÔNG làm multi-step search/filter.
- **Cách thực hiện ưu tiên:** Backend auto-assign bàn đầu tiên còn trống trong khung giờ. Mobile chỉ cần gửi `cafeTableId` lấy từ `LobbyEntity` (nếu backend lobby response có).
- **Fallback nếu LobbyEntity không có `cafeTableId`:** Build `CafeTableRemoteDatasource` gọi `GET /api/cafes/{cafeId}/available-tables` (gap #1) — nhưng đây là backend gap, có thể defer.

### 4.2. Logic deep-link SePay return

- Backend SePay return URL: `GET /api/payments/sepay/webhook/return?orderId=BV12345678&status=success`.
- App cần deep-link scheme `boardverse://payment/return?orderId=...&status=...`.
- Parse URL → `getDepositByOrder(orderId)` → resolve `bookingId` → navigate `BookingDetailPage`.
- Handlers cho 3 case: success / success-but-refunded / failed.

### 4.3. Refund UI

- `BookingEntity` cần thêm field `depositRefundStatus` (nullable).
- Cập nhật `BookingModel.fromJson` + `BookingRepositoryImpl.getBookingById` (gọi thêm `getDepositStatus` song song).
- UI: badge "Đã hoàn cọc" / "Chờ hoàn cọc" / "Bị tịch thu".

### 4.4. NoShow badge

- `NoShowBadge` widget đã tồn tại (`lib/features/booking_payment/presentation/widgets/no_show_badge.dart`) — wire vào header card khi `status == noShow`.
- `_isTerminal` chỉ check `cancelled/noShow` (bỏ `pendingDeposit`).
- Disable "Huỷ đơn" button khi `status == noShow`.

---

## 5. Files cần thay đổi (theo plan gốc)

### 5.1. Sửa trực tiếp (7 file)

| File | Lý do sửa |
|------|-----------|
| `lib/features/booking_payment/domain/repositories/booking_repository.dart` | Xóa `confirmBookingPayment` |
| `lib/features/booking_payment/data/booking_repository_impl.dart` | Implement lại sau khi xóa method |
| `lib/features/booking_payment/presentation/cubit/booking_result_cubit.dart` | Resume flow ưu tiên `pendingDepositId` |
| `lib/features/booking_payment/presentation/pages/booking_detail_page.dart` | NoShow + Cancel UX + refund badge |
| `lib/features/booking_payment/presentation/pages/booking_summary_page.dart` | Schedule end time picker |
| `lib/features/lobby_management/presentation/pages/lobby_page.dart` | Truyền `cafeTableId` thật (line 334, 365) |
| `lib/features/matchmaking_discovery/presentation/pages/board_game_detail_page.dart` | Truyền `cafeTableId` + walk-in logic (line 189-204, 426-441) |

### 5.2. Tạo mới (4 file)

| File | Mục đích |
|------|---------|
| `lib/features/booking_payment/data/datasources/remote/cafe_table_remote_datasource.dart` | Fetch available tables (Dio impl) |
| `lib/features/booking_payment/data/datasources/base/cafe_table_remote_datasource.dart` | Interface (abstract) |
| `lib/features/booking_payment/presentation/deeplink/sepay_return_handler.dart` | Deep-link handler từ SePay |
| `lib/features/booking_payment/presentation/widgets/deposit_refund_badge.dart` | Badge hiển thị refund status |

### 5.3. Cập nhật DI / Manifest

| File | Lý do |
|------|-------|
| `lib/core/di/injection.dart` | Register `CafeTableRemoteDatasource` (line ~228) |
| `android/app/src/main/AndroidManifest.xml` | Deep-link scheme `boardverse://` |
| `ios/Runner/Info.plist` | Deep-link scheme (iOS — nếu có iOS) |

---

## 6. Câu hỏi đã được user trả lời (KHÔNG hỏi lại)

| Câu hỏi | Trả lời |
|---------|---------|
| Phạm vi plan? | `full_max` — Implement tất cả gaps |
| Strategy table UI? | `single_default` — 1 step datatable sau lobby confirm |

**User KHÔNG chốt:** iOS scheme config (Task 2.1 — chỉ làm Android trước theo risk table).

---

## 7. Những thứ KHÔNG nằm trong plan này (scope defer)

- Backend gaps (file `booking-payment-gaps.md` 722 dòng) — backend team xử lý riêng.
- Lobby auto-create booking (mock `LobbyAutoBookingCreated` state) — discussion riêng.
- Tournament booking integration — module khác.
- In-game session tracking — module `in_game_experience`.
- Push notification về booking status — backend có nhưng FE chưa integrate.
- SignalR/WebSocket realtime thay polling — backend task.
- Currency formatting i18n (defer task 5 §summary_code.md).
- `flutter_secure_storage` web config (chưa có web platform).

---

## 8. Acceptance criteria gộp (để đoạn chat mới check khi xong)

- [ ] Tap "Đặt chỗ" từ LobbyPage → BookingSummaryPage nhận `cafeTableId` thực → `POST /api/bookings` không 400.
- [ ] Tap "Đặt chỗ ngay" từ BoardGameDetailPage → tương tự.
- [ ] Tap "Đặt cọc" → SePay URL mở (external) → polling 3s.
- [ ] Từ SePay quay lại app qua deep-link → navigate tới `BookingDetailPage` status đúng.
- [ ] Kill app giữa PaymentPage → reopen → banner "Tiếp tục thanh toán" → tap → mở `PaymentPage` resumed.
- [ ] Booking NoShow / Cancelled có badge + message phù hợp.
- [ ] Cancel booking confirmed → snackbar "Đã huỷ — staff sẽ hoàn cọc theo policy".
- [ ] BoardGameDetail snackbar gợi ý walk-in vs booking theo availability.
- [ ] BookingSummaryPage cho player chọn khung giờ custom (1-6h).
- [ ] BookingDetailPage hiển thị "Đã hoàn cọc" / "Chờ hoàn cọc" / "Bị tịch thu" theo `depositRefundStatus`.
- [ ] `dart analyze lib/features/booking_payment/` pass.
- [ ] Smoke test 4 case flow (đã liệt kê ở plan §4.2).

---

## 9. Gợi ý thứ tự thực hiện

1. **Đọc file `.agents/docs/apis_docs/booking-payment-gaps.md`** (đã tạo ở đoạn chat trước) — để nắm backend gaps context.
2. **Bắt đầu với Task 1.1** (xóa `confirmBookingPayment`) — 10 min, an toàn.
3. **Task 1.2** (cafeTableId wiring) — lớn nhất, 60 min. Cần check `LobbyEntity` có field `cafeTableId` không trước. Nếu không có → dùng fallback datasource mới.
4. **Task 1.3** (verify SePay) — 10 min, chỉ đọc + confirm.
5. **Task 2.1** (deep-link) — 45 min, cần config AndroidManifest.
6. **Task 2.2** (resume flow) — 30 min, refactor cubit.
7. **Task 2.3** (NoShow + Cancel) — 30 min.
8. **Task 3.1** (walk-in) — 30 min, có thể skip nếu backend không có `GET /availability`.
9. **Task 3.2** (schedule picker) — 30 min.
10. **Task 3.3** (refund UI) — 30 min.
11. **Task 4.1** (dart analyze) — 15 min.
12. **Task 4.2** (smoke test) — 45 min.

---

## 10. Lưu ý quan trọng cho đoạn chat tiếp theo

1. **KHÔNG hỏi lại những câu đã chốt** (xem §6).
2. **KHÔNG cần đọc lại toàn bộ codebase** — các file đã được research kỹ ở đoạn chat trước. Đoạn chat mới chỉ cần đọc file khi chuẩn bị sửa nó.
3. **Có thể tạo các file theo plan** — đã rõ structure, không cần AskQuestion.
4. **Nếu gặp vấn đề mới phát sinh** (không có trong plan), hỏi user trước khi sửa ngoài scope.
5. **Mỗi task nên có 1 commit** — dễ review và rollback nếu cần. (User CHƯA chốt format commit — check khi bắt đầu nếu cần.)
6. **Backup plan cho Task 1.2:** Nếu `LobbyEntity` không có `cafeTableId` VÀ backend chưa có `GET /available-tables` (gap #1 chưa fix) → dùng empty string (giữ nguyên hiện trạng) nhưng COMMENT rõ rằng cần backend hỗ trợ trước khi chạy được flow.

---

## 11. Đường dẫn file hay dùng

- **Plan gốc:** `c:\Users\PC\.cursor\plans\hoan-thien-booking-payment_9983f077.plan.md`
- **Backend gaps docs:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\apis_docs\booking-payment-gaps.md`
- **Backend booking API:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\apis_docs\booking.md`
- **Backend payment API:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\apis_docs\payment.md`
- **Backend cafe API:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\apis_docs\cafe.md`
- **Swagger JSON:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\swagger.json`
- **Spec nghiệp vụ:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\matchmaking_booking_module\bussiness_rule.md`
- **DI setup:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\lib\core\di\injection.dart` (line 228-276 cho booking)
- **Main entry:** `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\lib\main.dart`

---

## 12. Trạng thái todos (snapshot tại thời điểm handover)

```
- [ ] critical-1.1-xoa-confirmBookingPayment
- [ ] critical-1.2-wiring-cafeTableId (cần build cafeTable datasource)
- [ ] critical-1.3-verify-payment-page-flow
- [ ] high-2.1-sepay-deeplink-handler
- [ ] high-2.2-resume-flow-depositId
- [ ] high-2.3-no-show-cancel-ux
- [ ] polish-3.1-walk-in-detection
- [ ] polish-3.2-schedule-endtime-picker
- [ ] polish-3.3-refund-status-ui
- [ ] validate-4.1-dart-analyze
- [ ] validate-4.2-integration-smoke-test
```

**Total: 11 tasks, 0 done.**

---

*Hết context handover. Đoạn chat tiếp theo có thể bắt đầu từ Task 1.1 mà không cần đọc lại hết codebase.*
