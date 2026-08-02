# Booking & Payment — APIs cần bổ sung cho Player Mobile

> **Phiên bản:** 1.0 — 2026-08-01
> **Phạm vi:** Tài liệu kỹ thuật cho team Backend .NET, mô tả chi tiết 14 endpoint mới + 2 field bổ sung trong DTO + 1 cấu hình mới cho nghiệp vụ Player mobile app theo spec dự án BoardVerse.
> **Liên quan:** [`booking.md`](./booking.md), [`payment.md`](./payment.md), [`sepay-webhook.md`](./sepay-webhook.md), [`cafe.md`](./cafe.md).

---

## Tổng quan

Các API hiện tại (`booking.md` + `payment.md`) đã đủ cho happy path Player: tạo booking → cọc SePay → staff check-in → check-out. Tuy nhiên khi đối chiếu với [`infomation_project.md`](./../infomation_project.md), [`matchmaking_booking_module/mobile_tasks.md`](./../matchmaking_booking_module/mobile_tasks.md) và [`matchmaking_booking_module/bussiness_rule.md`](./../matchmaking_booking_module/bussiness_rule.md), phát hiện **14 endpoint mới + 2 schema DTO bổ sung + 1 policy config** cần Backend bổ sung để mobile app xử lý đầy đủ các tình huống nghiệp vụ thực tế (kiểm tra capacity theo khung giờ, xử lý khi member về sớm, vote no-show, chấm điểm Karma, nhận realtime event).

---

## Mục lục

### Nhóm 1: Bắt buộc (block flow mobile hiện tại)

1. [`GET /api/cafes/{cafeId}/available-tables`](#1-get-apicafescafeidavailable-tables)
2. [`GET /api/cafes/{cafeId}/availability`](#2-get-apicafescafeidavailability)
3. [`POST /api/bookings/walk-in` hoặc cho phép `lobbyId=null`](#3-post-apibookingswalk-in-hoặc-cho-phép-lobbyidnull)
4. [`POST /api/bookings/{bookingId}/no-show-votes`](#4-post-apibookingsbookingidno-show-votes)
5. [`POST /api/bookings/{bookingId}/ratings` + `GET .../ratings/status`](#5-post-apibookingsbookingidratings--get-ratingsstatus)
6. [AuthZ: Player được GET `/api/payments/booking-deposit/{id}`](#6-authz-player-được-get-apipaymentsbooking-depositid)

### Nhóm 2: Nên có (cải thiện UX quan trọng)

7. [SignalR/WebSocket events cho booking status](#7-signalrwebsocket-events-cho-booking-status)
8. [`GET /api/bookings/{bookingId}/session-status`](#8-get-apibookingsbookingidsession-status)
9. [Push notification khi Lobby auto-cancel](#9-push-notification-khi-lobby-auto-cancel)
10. [Bổ sung field vào `BookingResponseDto`](#10-bổ sung-field-vào-bookingresponsedto)
11. [Bổ sung field vào `BookingDepositResponseDto`](#11-bổ sung-field-vào-bookingdepositresponsedto)

### Nhóm 3: Nice-to-have (defer)

12. [`PATCH /api/cafes/{cafeId}/deposit-refund-policy`](#12-patch-apicafescafeiddeposit-refund-policy)
13. [Push notification khi Manager đổi giá](#13-push-notification-khi-manager-đổi-giá)
14. [`GET /api/bookings/cafe/{cafeId}` mở rộng cho Player](#14-get-apibookingscafecafeid-mở-rộng-cho-player)

### Nhóm 4: Validation nghiệp vụ bắt buộc sửa trong endpoint hiện tại

15. [`PATCH /api/bookings/{id}` cần check `playerQuantity ≤ lobby.currentMembers`](#15-patch-apibookingsid-cần-check-playerquantity--lobbycurrentmembers)

---

## Nhóm 1: Bắt buộc

### 1. `GET /api/cafes/{cafeId}/available-tables`

**Role:** Player đã đăng nhập.

**Mục đích:** Mobile app `BookingSummaryPage` (`lib/features/booking_payment/presentation/pages/booking_summary_page.dart`) BẮT BUỘC truyền `cafeTableId` cho `POST /api/bookings` (xem `booking.md` §3.1). Hiện tại `lib/features/lobby_management/presentation/pages/lobby_page.dart` đang truyền `cafeTableId: ''` (rỗng) — backend sẽ trả 400 ngay. Player không thể tự nhập UUID của bàn, cần backend trả sẵn danh sách bàn phù hợp với khung giờ + số ghế.

**Tại sao không thể dùng endpoint hiện tại:**
- `/api/cafes/{cafeId}/pos/tables` (xem `cafe-pos.md`) — role **CafeStaff/Manager**, không truy cập được từ Player token.

**Query:**

| Param | Required | Mô tả |
|-------|----------|-------|
| `scheduledStartTime` | ✅ | ISO 8601 UTC, giờ bắt đầu dự kiến |
| `scheduleEndTime` | ✅ | ISO 8601 UTC, giờ kết thúc dự kiến |
| `seatCount` | ✅ | Số ghế tối thiểu (≥1) |

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "message": "Lấy danh sách bàn trống thành công.",
  "data": [
    {
      "id": "uuid",
      "name": "Bàn 3 - Cửa sổ",
      "seatCount": 6,
      "isAvailable": true,
      "pricePerHour": 80000
    },
    {
      "id": "uuid",
      "name": "Bàn 5 - Ban công",
      "seatCount": 8,
      "isAvailable": true,
      "pricePerHour": 100000
    }
  ]
}
```

**Logic backend:** Lọc `CafeTable` thuộc cafe → `seatCount >= requestedSeatCount` → loại bỏ bàn có `Booking` overlap khung giờ (status != Cancelled, status != Expired) hoặc `ActiveSession` đang mở.

**Lỗi:**
- `400` thiếu query param hoặc giờ không hợp lệ.
- `404` cafe không tồn tại.
- `500` lỗi hệ thống.

---

### 2. `GET /api/cafes/{cafeId}/availability`

**Role:** Player đã đăng nhập.

**Mục đích:** Mobile `BoardGameDetailPage` cần biết "quán còn bao nhiêu ghế trống trong khung giờ player muốn đặt" TRƯỚC khi vào luồng BookingSummary. Hiện `GET /api/cafes/nearby` (xem `cafe.md` §1) chỉ trả `availableTableCount`/`totalTableCount` tại thời điểm hiện tại — không xét theo khung giờ dự kiến. Mobile UI không có cách nào hiển thị "Quán này 19h-21h đã hết chỗ" trước khi cho player bấm "Đặt cọc".

**Tại sao endpoint hiện tại không đủ:**
- `GET /nearby` là cho discovery list, không truyền được time slot cụ thể.
- `availableTableCount` chỉ snapshot hiện tại, không tính reservation tương lai.

**Query:**

| Param | Required | Mô tả |
|-------|----------|-------|
| `startTime` | ✅ | ISO 8601 UTC, giờ bắt đầu muốn đặt |
| `endTime` | ✅ | ISO 8601 UTC, giờ kết thúc muốn đặt |
| `seatCount` | ❌ | Số ghế player cần (default 1) |
| `gameTemplateId` | ❌ | Game đang chọn (để check game box có sẵn không) |

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "data": {
    "cafeId": "uuid",
    "cafeName": "Cờ Cá Nhà Bà Tám",
    "requestedStartTime": "2026-08-01T19:00:00Z",
    "requestedEndTime": "2026-08-01T21:00:00Z",
    "hasCapacity": true,
    "availableSeats": 4,
    "totalSeats": 12,
    "availableGameBoxCount": 2,
    "selectedGameAvailabilityStatus": "GameAvailable",
    "alternativeSlots": [
      { "startTime": "2026-08-01T19:30:00Z", "endTime": "2026-08-01T21:30:00Z", "availableSeats": 6 },
      { "startTime": "2026-08-01T20:00:00Z", "endTime": "2026-08-01T22:00:00Z", "availableSeats": 8 }
    ]
  }
}
```

**Logic backend:**
1. `totalSeats` = tổng `CafeTable.seatCount` của cafe.
2. `availableSeats` = `totalSeats - Σ(Booking.seatCount where overlap khung giờ AND status != Cancelled/Expired) - Σ(ActiveSession.assignedSeats where overlap)`.
3. `hasCapacity` = `availableSeats >= seatCount`.
4. `alternativeSlots`: khảo sát 4 slot kế tiếp (mỗi slot cách 30 phút, cùng độ dài) → trả về slot gần nhất còn `>= seatCount` ghế.
5. `selectedGameAvailabilityStatus`: mirror logic của `GET /nearby` (xem `cafe.md` §97).

**Lỗi:** `400`, `404`, `500`.

---

### 3. `POST /api/bookings/walk-in` hoặc cho phép `lobbyId=null`

**Role:** Player đã đăng nhập.

**Mục đích:** Theo spec `mobile_tasks.md` Task 1: *"Suggests 'Walk-in' if tables/games are available immediately, or 'Booking' if the cafe is currently at full capacity."* Hiện `POST /api/bookings` yêu cầu `lobbyId` bắt buộc (xem `booking.md` §3.1) — player muốn đặt nhanh không qua Lobby thì không có cách.

**Tại sao cần thiết:** Mobile `BoardGameDetailPage` cần 2 nút: "Đến ngay" (walk-in) và "Đặt cọc trước" (lobby flow). Nút "Đến ngay" không cần tạo lobby → backend cần accept booking walk-in.

**Phương án A (khuyến nghị):** Cho phép `lobbyId = null` trong `CreateBookingRequestDto` hiện tại.

**Request body (bổ sung):**
```json
{
  "lobbyId": null,
  "cafeId": "uuid",
  "cafeTableId": "uuid",
  "scheduledStartTime": "2026-08-01T19:00:00Z",
  "scheduleEndTime": "2026-08-01T21:00:00Z",
  "playerQuantity": 4
}
```

**Phương án B:** Tạo endpoint riêng `POST /api/bookings/walk-in` (không truyền lobbyId).

**Validation bổ sung:**
- Nếu `lobbyId == null`: chỉ áp dụng rule BR-05 (seats capacity + payment success), bỏ qua rule BR-07 (lobby member bound).
- `BR-09` vẫn áp dụng: deposit chỉ cấn trừ khi có session kết thúc.

**Lỗi:** `400`, `409` (bàn trùng giờ — vẫn check).

---

### 4. `POST /api/bookings/{bookingId}/no-show-votes`

**Role:** Player — chỉ thành viên trong lobby của booking đã `CheckedIn`.

**Mục đích:** Theo spec `mobile_tasks.md` Task 5: *"Khi nhân viên tại quầy POS thực hiện check-in với số lượng người thực tế đi thiếu tại quán (Ví dụ: Đơn đặt 4 nhưng thực tế chỉ đi 3), Backend tiến hành đóng băng khoản cọc của thành viên vắng mặt. Hệ thống sẽ không xử phạt ngay. Khi phiên chơi tổng đóng lại, Backend thu thập dữ liệu biểu quyết từ các thành viên có mặt."*

Mobile app cần endpoint này để:
1. Sau khi Staff check-in xong, mobile của các member hiển thị form vote "Ai vắng mặt thực tế?".
2. Backend aggregate vote → nếu đa số confirm → trừ cọc thành viên đó + giảm Karma.
3. Mobile app KHÔNG CÓ cách nào khác để trigger logic nghiệp vụ này nếu thiếu endpoint.

**Tại sao không thể reuse endpoint khác:**
- `POST /api/bookings/{id}/check-out` chỉ dành cho Staff/Manager (booking.md §3.8), không phục vụ voting.

**Request body:**
```json
{
  "bookingId": "uuid",
  "absentMemberIds": ["user-uuid-1", "user-uuid-2"],
  "votedAt": "2026-08-01T20:30:00Z"
}
```

| Field | Required | Mô tả |
|-------|----------|-------|
| `bookingId` | ✅ | Path + body (để idempotent check) |
| `absentMemberIds` | ✅ | Danh sách userId bị vote vắng mặt |
| `votedAt` | ✅ | Thời điểm vote (UTC) |

**Validation:**
- Booking phải ở status `CheckedIn`.
- VotedAt > `booking.checkedInAt` + 30 phút (tránh vote tức thì sau check-in).
- VotedAt < `booking.scheduleEndTime` + 24 giờ (sau 24h hết quyền vote).
- User gọi API phải là member của lobby (host hoặc player), không được vote chính mình vắng mặt.
- Mỗi user chỉ vote được 1 lần — gọi lần 2 = update vote cũ.

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "data": {
    "bookingId": "uuid",
    "voterId": "uuid",
    "absentMemberIds": ["user-uuid-1"],
    "currentVoteCounts": {
      "user-uuid-1": { "absentVotes": 2, "presentVotes": 0, "totalMembers": 4 },
      "user-uuid-2": { "absentVotes": 0, "presentVotes": 3, "totalMembers": 4 }
    },
    "noShowConfirmedMembers": ["user-uuid-1"],
    "processedAt": null
  }
}
```

**Side effects:**
- Lưu vote vào `BookingNoShowVotes` table.
- Nếu `absentVotes > totalMembers / 2` cho 1 userId → thêm userId vào `noShowConfirmedMembers`.
- Khi Staff `POST /api/bookings/{id}/check-out` → aggregate `noShowConfirmedMembers` → tính tiền phạt + trừ Karma + trừ cọc (theo rule trong `bussiness_rule.md` §III.2).

**Lỗi:** `400`, `403` (không phải member), `404`, `409` (đã vote quá số lần).

---

### 5. `POST /api/bookings/{bookingId}/ratings` + `GET .../ratings/status`

**Role:** Player — chỉ member lobby đã check-in.

**Mục đích:** Theo spec `mobile_tasks.md` Task 5: *"Biểu mẫu chấm điểm thái độ. Hệ thống sẽ... tự động kích hoạt hiển thị ngay khi phiên chơi tại quầy POS được nhân viên bấm đóng."*

Mobile app cần:
1. Sau khi Staff check-out, mobile các member hiển thị form chấm điểm chéo (attitude, sportsmanship, comment) cho từng member khác.
2. Backend aggregate điểm → cập nhật `User.Karma` của từng user được chấm.
3. Mobile cần `GET /status` để biết "mình đã chấm hết các thành viên chưa" để ẩn form.

**Tại sao không thể reuse endpoint khác:**
- `/api/userprofile/me/karma` (xem `user-profile.md`) — chỉ đọc, không có cơ chế nhập điểm từ chấm chéo.

**`POST /api/bookings/{bookingId}/ratings`**

**Request body:**
```json
{
  "bookingId": "uuid",
  "ratings": [
    {
      "ratedUserId": "user-uuid-2",
      "attitude": 5,
      "sportsmanship": 4,
      "punctuality": 5,
      "comment": "Vui tính, chơi fair"
    },
    {
      "ratedUserId": "user-uuid-3",
      "attitude": 4,
      "sportsmanship": 5,
      "punctuality": 3,
      "comment": "Hay trễ giờ"
    }
  ]
}
```

| Field | Range | Required | Mô tả |
|-------|-------|----------|-------|
| `attitude` | 1-5 | ✅ | Thái độ chơi (toxic / fair-play) |
| `sportsmanship` | 1-5 | ✅ | Tinh thần thể thao |
| `punctuality` | 1-5 | ✅ | Đúng giờ |
| `comment` | max 500 chars | ❌ | Nhận xét |

**Validation:**
- Booking phải ở status `CheckedIn` hoặc `Confirmed` (sau check-out vẫn rate được trong 24h).
- User gọi API không được rate chính mình.
- Mỗi ratedUserId chỉ xuất hiện 1 lần trong `ratings`.
- Mỗi voter chỉ submit 1 lần (idempotent qua bookingId + voterId).

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "data": {
    "bookingId": "uuid",
    "voterId": "uuid",
    "submittedAt": "2026-08-01T21:30:00Z",
    "ratedCount": 2
  }
}
```

**Side effects:**
- Lưu vào `BookingRatings` table.
- Chờ Staff `POST /check-out` hoặc 24h sau `checkOutTime` → aggregate:
  - Tính delta `Karma` cho mỗi rated user = `(avg(allRatings) - 3.0) * 10`.
  - Cộng vào `User.Karma` của rated user.
  - Lưu `KarmaHistoryLog` để audit.

**Lỗi:** `400`, `403`, `404`, `409` (đã submit rồi).

**`GET /api/bookings/{bookingId}/ratings/status`**

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "data": {
    "bookingId": "uuid",
    "canRate": true,
    "rateDeadline": "2026-08-02T21:30:00Z",
    "alreadyRated": false,
    "ratedUserIds": [],
    "missingMemberIds": ["user-uuid-2", "user-uuid-3", "user-uuid-4"]
  }
}
```

**Lỗi:** `403`, `404`.

---

### 6. AuthZ: Player được GET `/api/payments/booking-deposit/{id}`

**Mục đích:** Theo `payment.md` §176 (lưu ý cuối): *"Cả hai endpoint GET đều không xác thực quyền sở hữu Player trong controller hiện tại... Khi mobile Player flow cần xem đơn của mình, cần bổ sung logic check deposit.UserId == currentUserId."*

Swagger hiện tại (xem swagger.json §7629) ghi `[Role: Manager — chỉ xem được đơn thuộc quán của mình; Admin — xem tất cả.]` — **Player bị từ chối**.

**Tại sao quan trọng:** Mobile app `SepayPaymentGateway.watchResult()` (`lib/features/booking_payment/data/datasources/gateway/sepay_payment_gateway.dart` line 72) đang gọi `paymentRemote.getDepositStatus(transactionRef)` — dùng `depositId`. Nếu backend 403 Player → polling fail ngay từ đầu → user không bao giờ biết thanh toán thành công.

**Giải pháp:** Sửa `PaymentController.GetBookingDeposit(Guid depositId)` để:
- Nếu user là `Manager` của cafe đó → cho phép (như cũ).
- Nếu user là `Player` VÀ `deposit.UserId == currentUserId` → cho phép.
- Nếu user là `Admin` → cho phép.
- Ngược lại → 403.

**Phương án thay thế (nếu không muốn sửa controller):** Mobile chỉ dùng `/by-order/{orderId}` để polling. Tuy nhiên cần đảm bảo mobile app biết `orderId` ngay sau khi tạo deposit — hiện `DepositPaymentEntity` có field `orderId` (xem `payment.md` §3.1) nên OK.

**Khuyến nghị:** Sửa controller để support Player (giải pháp gốc từ `payment.md`).

---

## Nhóm 2: Nên có

### 7. SignalR/WebSocket events cho booking status

**Mục đích:** Hiện `lib/features/booking_payment/presentation/cubit/booking_result_cubit.dart` dùng `startPollingStatus()` mỗi 5 giây — tốn bandwidth, có độ trễ 5s. Spec `mobile_tasks.md` Task 4 yêu cầu realtime: *"Ngay khi nhân viên tại quầy POS quét mã thành công, ứng dụng di động của toàn bộ thành viên thuộc phòng chờ đó phải lập tức tự động cập nhật trạng thái đơn hàng sang [Booking: Checked-In]."*

**Phương án A (khuyến nghị):** Tái sử dụng hub `/hubs/lobby` (đã có cho Lobby module, xem `lobby_docs/lobby.md`) — bổ sung 4 events mới.

**Phương án B:** Tạo hub riêng `/hubs/booking`.

**Events cần broadcast:**

| Event | Trigger | Payload |
|-------|---------|---------|
| `BookingCheckedIn` | Sau `POST /bookings/{id}/check-in` | `{ bookingId, checkedInAt, checkedInBy }` |
| `BookingCheckedOut` | Sau `POST /bookings/{id}/check-out` | `{ bookingId, checkedOutAt, totalAmount }` |
| `BookingCancelled` | Sau `DELETE /bookings/{id}` hoặc manager cancel | `{ bookingId, cancelledBy, reason, refundStatus }` |
| `BookingNoShowMarked` | Sau khi Staff check-out + aggregate votes | `{ bookingId, noShowMemberIds, karmaDeltas }` |

**Logic broadcast:**
- Client subscribe bằng SignalR group `booking-{bookingId}` (join khi mở BookingDetailPage).
- Server: sau khi xử lý 1 trong 4 triggers trên → broadcast vào group tương ứng.
- Mobile app dùng `signalr_netcore` (đã có sẵn trong Lobby module).

**Tại sao không thể dùng polling:**
- Polling 5s = user nhìn thấy status cũ tối đa 5s — UX kém.
- Push notification qua FCM có độ trỉ 1-2 phút và đòi hỏi user cho phép notification.
- SignalR realtime là giải pháp đúng cho "single check-in" flow (spec §Task 4).

---

### 8. `GET /api/bookings/{bookingId}/session-status`

**Role:** Player — chỉ member lobby.

**Mục đích:** Theo `bussiness_rule.md` §III.2 (Exception Path): Khi 1-2 member về sớm, Staff thực hiện partial checkout. Các thành viên còn lại cần biết:
- Ai đã về sớm?
- Hóa đơn partial của người về sớm có bao nhiêu?
- Phiên chơi của họ còn bao nhiêu thời gian?
- Hóa đơn cuối cùng dự kiến của họ là bao nhiêu?

Mobile hiện (`BookingDetailPage`) chỉ hiển thị `BookingEntity` — không biết `ActiveSession` status.

**Tại sao không thể reuse:**
- `/api/cafes/{cafeId}/pos/sessions/active` (xem `cafe-pos.md`) — role Staff/Manager, Player không access.

**Response 200:**
```json
{
  "statusCode": 200,
  "isSuccess": true,
  "data": {
    "bookingId": "uuid",
    "activeSessionId": "uuid",
    "sessionStatus": "Active",
    "startedAt": "2026-08-01T19:00:00Z",
    "currentDurationMinutes": 75,
    "members": [
      {
        "userId": "user-uuid-1",
        "username": "alice",
        "status": "LeftEarly",
        "leftAt": "2026-08-01T20:00:00Z",
        "partialBillAmount": 85000,
        "partialBillPaid": true,
        "mergedIntoSessionId": null
      },
      {
        "userId": "user-uuid-2",
        "username": "bob",
        "status": "Active",
        "leftAt": null,
        "partialBillAmount": 0,
        "partialBillPaid": false,
        "mergedIntoSessionId": null
      },
      {
        "userId": "user-uuid-3",
        "username": "carol",
        "status": "Active",
        "leftAt": null,
        "partialBillAmount": 0,
        "partialBillPaid": false,
        "mergedIntoSessionId": "other-session-uuid"
      }
    ],
    "estimatedFinalBill": {
      "subtotal": 250000,
      "penalty": 0,
      "depositApplied": 50000,
      "total": 200000
    }
  }
}
```

**Lỗi:** `403`, `404`, `500`.

---

### 9. Push notification khi Lobby auto-cancel

**Mục đích:** Theo spec `bussiness_rule.md` §2.5: *"Nếu đến mốc giờ hẹn chơi trừ đi khối thời gian thông báo (Lead-time) do quán cấu hình mà phòng chờ chưa đạt đủ số lượng thành viên tối thiểu của tựa game board game đã chọn, hệ thống thực hiện hủy phòng chờ ([Lobby: Failed]) để giải phóng ghế."*

Hiện Backend chỉ đổi `Lobby.Status = Failed` + giải phóng ghế — **không thông báo cho các Player đang chờ trong lobby**. Mobile app sẽ không biết lobby đã bị hủy cho tới khi user mở app thủ công → trải nghiệm rất tệ.

**Cần:** Sau khi cron auto-cancel lobby:
1. Push notification (FCM) cho từng member: *"Lobby của bạn đã bị hủy do không đủ người trước giờ hẹn."*
2. Hoặc broadcast SignalR event `LobbyAutoCancelled` qua `/hubs/lobby` (xem option B của gap #7).

**Payload push notification:**
```json
{
  "type": "LobbyAutoCancelled",
  "lobbyId": "uuid",
  "cafeName": "Cờ Cá Nhà Bà Tám",
  "scheduledTime": "2026-08-01T19:00:00Z",
  "reason": "NotEnoughMembers"
}
```

**Lỗi:** N/A — internal job.

---

### 10. Bổ sung field vào `BookingResponseDto`

**Hiện tại** (swagger.json `BookingResponseDto`):
```json
{
  "id": "uuid",
  "lobbyId": "uuid",
  "cafeId": "uuid",
  "cafeName": "string",
  "cafeTableId": "uuid",
  "cafeTableName": "string",
  "scheduledStartTime": "datetime",
  "scheduleEndTime": "datetime",
  "status": 0,
  "statusText": "string",
  "verificationQRCode": "string",
  "playerQuantity": 4
}
```

**Thiếu các field Mobile app cần** (xem `lib/features/booking_payment/domain/entities/booking_entity.dart`):

| Field cần thêm | Type | Lý do |
|----------------|------|-------|
| `gameId` | UUID | `BookingDetailPage._buildHeaderCard` cần hiển thị game (line 200) |
| `gameName` | string | UI title card |
| `depositAmount` | double | `BookingDetailPage` line 264 hiển thị "Đã cọc: X VNĐ" |
| `depositDeadline` | datetime | Countdown timer trên `BookingSuccessPage` |
| `paymentRef` | string? | Hiển thị mã giao dịch SePay sau khi thanh toán |
| `hostId` | UUID | Check ownership cho UI (nút Cancel chỉ hiện cho host) |
| `memberIds` | UUID[] | Hiển thị avatar member trong nhóm |
| `createdAt` | datetime | Audit trail |
| `updatedAt` | datetime | Audit trail + cache invalidation |

**DTO bổ sung:**
```json
{
  // ... existing fields ...
  "gameId": "uuid",
  "gameName": "Catan",
  "depositAmount": 50000,
  "depositDeadline": "2026-08-01T19:30:00Z",
  "paymentRef": "BV12345678",
  "hostId": "uuid",
  "memberIds": ["uuid", "uuid", "uuid", "uuid"],
  "createdAt": "2026-08-01T18:55:00Z",
  "updatedAt": "2026-08-01T18:58:00Z"
}
```

**Phương án tối thiểu:** Thêm vào DTO hiện tại, dùng `Include` hoặc `ProjectTo` trong EF Core query.

---

### 11. Bổ sung field vào `BookingDepositResponseDto`

**Hiện tại** (xem `payment.md` §3.1):
```json
{
  "depositId": "uuid",
  "orderId": "BV12345678",
  "qrUrl": "https://...",
  "paymentUrl": "https://...",
  "qrExpiresAt": "datetime",
  "amount": 20000,
  "requiresManualConfirmation": false
}
```

**Thiếu các field Mobile cần:**

| Field cần thêm | Type | Lý do |
|----------------|------|-------|
| `status` | string | "Pending" / "Paid" / "Expired" / "Refunded" / "Forfeited" — Mobile polling cần để biết khi nào chuyển state |
| `bookingId` | UUID | Sau khi thanh toán xong, Mobile cần resolve bookingId từ depositId để navigate |
| `cafeName` | string | Hiển thị trên PaymentPage |
| `refundedAmount` | double? | UI thông báo "Đã hoàn X VNĐ" sau khi Staff refund |
| `paidAt` | datetime? | Hiển thị "Thanh toán lúc X" |
| `transferContent` | string | Hiển thị "Nội dung CK: BV12345678" cho user nhập thủ công |
| `currency` | string | Default "VND" |

**DTO bổ sung:**
```json
{
  // ... existing fields ...
  "status": "Paid",
  "bookingId": "uuid",
  "cafeName": "Cờ Cá Nhà Bà Tám",
  "refundedAmount": null,
  "paidAt": "2026-08-01T19:02:00Z",
  "transferContent": "BV12345678",
  "currency": "VND"
}
```

---

## Nhóm 3: Nice-to-have

### 12. `PATCH /api/cafes/{cafeId}/deposit-refund-policy`

**Role:** Manager — chủ quán.

**Mục đích:** Theo `payment.md` §Refund BR-18, có 3 policy:
- `Full`: 100% refund.
- `Partial`: 50% / 25% / 0% theo elapsed hours.
- `None`: 0% refund, status chuyển `Forfeited`.

Hiện swagger không thấy endpoint để Manager cấu hình policy cho cafe → backend đang hard-code default policy. Manager không thể customize theo nhu cầu kinh doanh.

**Request body:**
```json
{
  "policy": "Partial",
  "partialTiers": [
    { "minHoursBeforeScheduled": 24, "refundPercent": 50 },
    { "minHoursBeforeScheduled": 12, "refundPercent": 25 },
    { "minHoursBeforeScheduled": 0, "refundPercent": 0 }
  ]
}
```

| Field | Required | Range |
|-------|----------|-------|
| `policy` | ✅ | "Full" \| "Partial" \| "None" |
| `partialTiers` | ✅ nếu policy=Partial | 1-5 tiers, sắp xếp giảm dần theo minHours |

**Lỗi:** `400` (tiers không hợp lệ), `403`, `404`.

---

### 13. Push notification khi Manager đổi giá

**Mục đích:** Theo `bussiness_rule.md` §1.4: *"Hệ thống chặn toàn bộ thao tác chỉnh sửa biểu phí giờ chơi của Quản lý quán trong suốt khung giờ quán đang hoạt động. Tính năng cập nhật giá chỉ được mở khóa khi trạng thái của quán là đóng cửa. Mọi thay đổi giá phải được hệ thống tự động lên lịch gửi thông báo Push đến toàn bộ người chơi đã có lịch hẹn Booking trong tuần."*

**Cần:**
1. Endpoint `PUT /api/cafes/{cafeId}/pricing-config` (chưa có — swagger hiện chỉ có `PUT /api/cafes/{id}` cho info chung).
2. Sau khi update → schedule background job push notification cho tất cả booking trong tuần của cafe đó.

**Push payload:**
```json
{
  "type": "CafePricingChanged",
  "cafeId": "uuid",
  "cafeName": "Cờ Cá Nhà Bà Tám",
  "oldFirstHourPrice": 80000,
  "newFirstHourPrice": 100000,
  "effectiveDate": "2026-08-05",
  "affectedBookingsCount": 12
}
```

---

### 14. `GET /api/bookings/cafe/{cafeId}` mở rộng cho Player

**Hiện tại:** Role = Manager/CafeStaff/Admin. Player không thể xem "timeline booking của cafe" để biết khung giờ nào đang bận.

**Mục đích:** Mobile Discovery page có thể hiển thị "Quán X đã có 3 booking từ 18h-22h hôm nay — khả năng còn chỗ thấp".

**Cần:** Sửa auth check để Player có thể GET, nhưng chỉ trả về "summary" (không trả `verificationQRCode`, `paymentRef`, `memberIds`).

**Response 200 (Player view, rút gọn):**
```json
{
  "data": [
    {
      "id": "uuid",
      "scheduledStartTime": "datetime",
      "scheduleEndTime": "datetime",
      "playerQuantity": 4,
      "status": "Confirmed"
    }
  ]
}
```

---

## Nhóm 4: Validation nghiệp vụ cần sửa trong endpoint hiện tại

### 15. `PATCH /api/bookings/{id}` cần check `playerQuantity ≤ lobby.currentMembers`

**Mục đích:** Swagger §2931 cho phép Player update `playerQuantity` qua PATCH. Hiện không thấy backend validate:
- Nếu `playerQuantity > lobby.currentMembers` → user đặt nhiều ghế hơn số người thực tế trong lobby → phá vỡ rule "không ghế thừa".

**Cần thêm validation trong `UpdateBookingRequestDto`:**
```csharp
if (request.PlayerQuantity.HasValue)
{
    var lobby = await _context.Lobbies.FindAsync(booking.LobbyId);
    if (request.PlayerQuantity.Value > lobby.CurrentMembers)
        throw new ConflictException("Số lượng người chơi vượt quá số thành viên trong lobby.");
    
    if (request.PlayerQuantity.Value < lobby.CurrentMembers)
        // Có thể cho phép nếu đã cọc đủ — hoặc bắt buộc refund phần cọc dư
        // → nghiệp vụ cần xác nhận với PM trước khi implement
}
```

**Lỗi trả về:** `409 Conflict`.

---

## Phụ lục A: Bảng tóm tắt

| # | Endpoint / Task | Method | Role | Phân loại | Block flow mobile? |
|---|----------------|--------|------|-----------|---------------------|
| 1 | `/api/cafes/{cafeId}/available-tables` | GET | Player | Bắt buộc | ✅ Có |
| 2 | `/api/cafes/{cafeId}/availability` | GET | Player | Bắt buộc | ✅ Có |
| 3 | `POST /api/bookings` allow `lobbyId=null` (walk-in) | POST | Player | Bắt buộc | ✅ Có |
| 4 | `POST /api/bookings/{id}/no-show-votes` | POST | Player | Bắt buộc | ✅ Có |
| 5 | `POST /api/bookings/{id}/ratings` + `GET /ratings/status` | POST / GET | Player | Bắt buộc | ✅ Có |
| 6 | Sửa authz cho Player GET `/payments/booking-deposit/{id}` | GET | Player | Bắt buộc | ✅ Có |
| 7 | SignalR events cho booking status | — | — | Nên có | ⚠️ UX kém |
| 8 | `GET /api/bookings/{id}/session-status` | GET | Player | Nên có | ⚠️ UX kém |
| 9 | Push khi lobby auto-cancel | — | — | Nên có | ⚠️ UX kém |
| 10 | Bổ sung field `BookingResponseDto` | — | — | Nên có | ⚠️ UX thiếu |
| 11 | Bổ sung field `BookingDepositResponseDto` | — | — | Nên có | ⚠️ UX thiếu |
| 12 | `PATCH /api/cafes/{id}/deposit-refund-policy` | PATCH | Manager | Nice-to-have | ❌ Không |
| 13 | Push khi Manager đổi giá | — | — | Nice-to-have | ❌ Không |
| 14 | `/api/bookings/cafe/{id}` cho Player | GET | Player | Nice-to-have | ❌ Không |
| 15 | Validate `playerQuantity` trong `PATCH /bookings/{id}` | PATCH | Player | Bắt buộc sửa | ⚠️ Edge case |

## Phụ lục B: Liên kết

- [Booking API](./booking.md) — endpoint booking hiện tại
- [Payment API](./payment.md) — endpoint payment + SePay
- [SePay Webhook](./sepay-webhook.md) — xử lý webhook
- [Cafe API](./cafe.md) — endpoint cafe (nearby, staff)
- [User Profile API](./user-profile.md) — Karma score
- [Spec nghiệp vụ](./../matchmaking_booking_module/bussiness_rule.md) — BR rules
- [Mobile tasks](./../matchmaking_booking_module/mobile_tasks.md) — yêu cầu từ phía mobile