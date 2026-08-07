# Plan triển khai Phase B → E: Vòng đời Lobby sau khi đầy (Full / Confirmed / Check-in / Completed / Karma)

> **Mục đích tài liệu**
>
> Đây là plan **gộp Phase B, C, D, E** cho việc triển khai tiếp theo module `lobby_management` trên Flutter mobile. Phase A (Status badge + Countdown + Check-in section + Poll reservation) đã hoàn thành. Tài liệu này giả định người đọc **chưa có context** về codebase, nhưng có quyền truy cập tất cả file dưới đây.
>
> **Nguyên tắc chốt (BR §1.3):**
> 1. **KHÔNG thay đổi nghiệp vụ / logic / flow xử lý của hệ thống.** Tất cả thay đổi chỉ là UI/UX, animation, polling, hiển thị thêm state, navigation, thông báo.
> 2. **Backend là source of truth** — mọi tính toán (cọc, deadline, status, refund) do backend xác nhận. Frontend chỉ hiển thị.
> 3. **Server-authoritative + Idempotency** — mọi API quan trọng (`confirm`, `cancel`, `topup`) cần `idempotencyKey` random (8–128 ký tự), đã có helper `generateIdempotencyKey()` tại `lib/core/utils/uuid_generator.dart`.

---

## 1. Bối cảnh dự án

### 1.1. Sản phẩm
**BoardVerse** — nền tảng vận hành board game: Mobile App (player) + Web POS & Management (quán) + Web Admin. Mobile App là app Flutter, focus vào player.

### 1.2. Stack kỹ thuật (FE)
- **Flutter** (Dart ^3) + **flutter_bloc** cho state management.
- **Cubit pattern** (không dùng full BLoC events), mỗi feature có cubit riêng.
- **Dio** cho HTTP, **get_it** cho DI, **flutter_secure_storage** cho JWT/secure storage.
- **qr_flutter** đã có sẵn, **signalr_netcore** đã xoá (FE dùng mock realtime + polling).
- **Architecture**: Feature-First Clean Architecture (data / domain / presentation).

### 1.3. Quy tắc tổ chức module
- `lib/features/<feature>/data/datasources/{base,remote,mock}/`: datasource interfaces + impls.
- `lib/features/<feature>/data/models/`: JSON DTOs.
- `lib/features/<feature>/data/<feature>_repository_impl.dart`: repo impl.
- `lib/features/<feature>/domain/entities/`: pure Dart entities (Equatable).
- `lib/features/<feature>/domain/repositories/`: repo interfaces.
- `lib/features/<feature>/presentation/{cubit,pages,widgets}/`: UI.
- Mỗi cubit được register trong `lib/core/di/injection.dart` (`sl.registerFactory<...>()`).
- Routes cho feature được mount qua `lobbyRouteGenerator()` trong `lib/features/lobby_management/lobby_routes.dart`.

### 1.4. Design system
Đọc `@.agents/docs/design_system.md` trước khi code UI. Bắt buộc dùng:
- `AppColors`, `AppColorsDark`
- `AppSpacing.{xxs,xs,sm,md,lg,xl,xxl,xxxl,huge,massive}`
- `AppRadius.{radiusXsAll, radiusSmAll, radiusMdAll, radiusLgAll, radiusFullAll}`
- `AppIcons.{check, cancelBooking, lock, qrCode, qrScan, copy, ...}`
- `LobbyCountdownTimer`, `LobbyStatusBadge`, `ScheduledTimeCountdown`, `LobbyCheckInSection` (Phase A đã có).
- `AppElevation`, `top_snack_bar.dart`, `current_user_resolver.dart` (helper resolve userId từ JWT).

### 1.5. Nguyên tắc code (BR §15 + kiến trúc)
- **SOLID, DRY** — không hardcode logic; tách widget, helper, model.
- **Đừng double-tap** — các nút quan trọng (confirm, cancel, send invite) phải có debounce 500ms (xem pattern `LobbyConfigBottomButton`).
- **Idempotency key random** — dùng `generateIdempotencyKey()` từ `core/utils/uuid_generator.dart` cho tất cả `confirm`, `topup`, `cancel`, `resendInvite`.
- **Server authoritative** — không tính `finalDeposit` ở FE; `expectedFinalDeposit` gửi lên phải lấy từ quote response.

---

## 2. Phase A đã hoàn thành (để agent mới nắm baseline)

Phase A (vừa xong) đã cài:
- `LobbyStatus` enum mở rộng 12 state (`pendingActivation`, `pendingCafeApproval`, `open`, `viable`, `full`, `inProgress`, `closed`, `ratingOpen`, `timeoutFailed`, `hostCancelled`, `rejectedByCafe`, `expiredByCafe`).
- `LobbyReservationCubit` — poll `GET /api/v1/reservations/{reservationId}` mỗi 15s, tự stop khi reservation ở terminal state.
- `LobbyStatusBadge` — chip badge 14 variant, helper `resolveBadgeVariant(lobbyStatus, reservationStatus)`.
- `ScheduledTimeCountdown` — đếm "Còn X ngày Y giờ Z phút" tới `lobby.scheduledTime`.
- `LobbyCheckInSection` — QR encode `reservation.id` + mã text + nút "Sao chép" / "Hiện QR full-screen". Chỉ hiện khi `reservation.status == confirmed` VÀ `lobby.status.canCheckIn`.
- `_LobbyStatusStrip` private widget trong `lobby_page.dart` — render badge + countdown + check-in section theo BlocBuilder<LobbyReservationCubit>.

Các file mới Phase A:
- `lib/features/lobby_management/domain/entities/lobby_entity.dart` (đã extend enum).
- `lib/features/lobby_management/data/models/lobby_model.dart` (đã extend `LobbyStatusModel`).
- `lib/features/lobby_management/presentation/cubit/lobby_reservation_cubit.dart`.
- `lib/features/lobby_management/presentation/widgets/lobby_status_badge.dart`.
- `lib/features/lobby_management/presentation/widgets/scheduled_time_countdown.dart`.
- `lib/features/lobby_management/presentation/widgets/lobby_check_in_section.dart`.
- `lib/core/di/injection.dart` (đã register `LobbyReservationCubit`).
- `lib/features/lobby_management/presentation/pages/lobby_page.dart` (đã wrap `MultiBlocProvider` + listener hook startWatching reservation).

`dart analyze` sạch 0 issues.

---

## 3. Phase B → E: Phạm vi triển khai tiếp theo

### 3.1. Tóm tắt các Phase

| Phase | Tên | Mục tiêu chính |
|-------|-----|-----------------|
| **B** | **Cafe Approval Flow** | UI cho host chờ cafe duyệt + poll status (BR-NEW-11) |
| **C** | **"Đến quán" UX (Check-in journey)** | Từ lobby "Confirmed" → đến quán → POS scan → "Đang chơi" realtime. Bao gồm QR handling + "Hôm nay bạn chơi ở ..." page. |
| **D** | **Lobby End States (Closed/TimeoutFailed/HostCancelled)** | UI chi tiết cho từng loại terminal state + action "Tạo lại" / "Gia hạn" / "Hoàn cọc". |
| **E** | **Post-session: Karma Rating** | Sau khi POS kết thúc phiên → mở UI đánh giá Karma cho member, host bấm "Hoàn tất phiên". |

Mỗi phase đều **BẮT BUỘC** theo các nguyên tắc:
- Không phá vỡ flow / logic nghiệp vụ đã chốt.
- `dart analyze` phải sạch (0 issues) trước khi commit.
- Tận dụng `LobbyStatusBadge` + `LobbyReservationCubit` đã có.

### 3.2. Cấu trúc dữ liệu liên quan (đã có sẵn)

**`LobbyEntity`** (`lib/features/lobby_management/domain/entities/lobby_entity.dart`):
```dart
class LobbyEntity extends Equatable {
  final String id;
  final String gameId, gameName, gameImageUrl;
  final String cafeId, cafeName, cafeTableId;
  final String hostId, hostName;
  final DateTime scheduledTime;       // = playDate + timeSlot.startTime
  final int currentPlayers, maxPlayers, minPlayers;
  final bool isPublic;
  final String? inviteCode;            // = shareCode từ backend
  final LobbyStatus status;
  final List<LobbyPlayer> players;
  final DateTime createdAt, timeoutAt; // timeoutAt = scheduledTime - leadTimeMinutes
  final String? bookingId, reservationId;
  final double minimumKarma, searchRadiusKm, distanceKm;
  final DateTime? closedAt;
  final String? closedReason;
  final int? cancellationLeadTimeMinutes;
  int get slotsRemaining;
  Duration get remainingTime;
  bool get isExpired;
}
```

**`LobbyStatus` enum** (đã extend 12 state ở Phase A):
```dart
enum LobbyStatus {
  pendingActivation, pendingCafeApproval, open, viable, full,
  inProgress, closed, ratingOpen,
  timeoutFailed, hostCancelled, rejectedByCafe, expiredByCafe,
}
extension LobbyStatusX {
  bool get isTerminal;            // closed/timeoutFailed/hostCancelled/rejectedByCafe/expiredByCafe
  bool get canDissolve;           // open/viable/full/timeoutFailed/hostCancelled
  bool get canCheckIn;            // viable/full/inProgress
  bool get isPendingCafeApproval; // == pendingCafeApproval
  bool get isRecruiting;          // open || viable
}
```

**`ReservationEntity`** (`lib/features/reservation/domain/entities/reservation_entity.dart`):
```dart
class ReservationEntity extends Equatable {
  final String id, hostId, hostDisplayName;
  final String cafeId, cafeName;
  final String gameId, gameName;
  final DateTime playDate;
  final TimeSlot timeSlot;              // morning/afternoon/evening/night
  final String? preferredStartTime;
  final DateTime scheduledTime, recruitmentDeadline;
  final int minPlayers, maxPlayers;
  final int depositRatePerPerson, baseDeposit, minDepositApplied, finalDeposit;
  final double riskMultiplier;
  final ReservationStatus status;       // 12 state
  final int currentPlayers;
  final String? lobbyId, lobbyShareCode;
  final LobbyStatus? lobbyStatus;
  final bool isPrivate, requiresCafeApproval;
  final DateTime? cafeApprovalDeadline, approvedAt;
  final String? cafeRejectionReason, refundPolicyApplied;
  final DateTime createdAt, updatedAt;
  final bool? isHost, isCafeApproved;
  final int? remainingApprovalHours, remainingApprovalMinutes;
}
```

**`ReservationStatus` enum**:
```dart
enum ReservationStatus {
  draft, awaitingDeposit, holding, confirmed, checkedIn, completed,
  expired, cancelledByPlayer, cancelledByCafe, noShow,
  cancelledByHost, rejectedByCafe;
  bool get isActive;  // holding/confirmed/checkedIn
  bool get isTerminal; // completed/expired/cancelledByPlayer/cancelledByCafe/cancelledByHost/noShow/rejectedByCafe
}
```

**`LobbyReservationCubit`** (đã có): poll `GET /api/v1/reservations/{id}` mỗi 15s, tự stop khi terminal.

**`LobbyCubit`** (`lib/features/lobby_management/presentation/cubit/lobby_cubit.dart`): chứa `LobbyUpdatedRealtime` state, host actions (`closeLobby`, `dissolveLobby`, `cancelInvite`, ...). Đã inject `LobbyRepository`.

**`LobbyRemoteDatasource`** (`lib/features/lobby_management/data/datasources/remote/real_lobby_remote_datasource.dart`): gọi tất cả endpoints lobby + reservation.

---

## 4. Phase B — Cafe Approval Flow

### 4.1. Bối cảnh
BR-NEW-11: Public lobby có `playDate` cách `now` ≥ 2 ngày phải được cafe duyệt trước khi publish. Flow:
1. Host confirm reservation → `lobby.status = pendingCafeApproval`, `reservation.status = holding`.
2. Backend set `reservation.cafeApprovalDeadline = now + 24h`.
3. Trong 24h: cafe duyệt → `lobby.status = open`; cafe từ chối → `lobby.status = rejectedByCafe` + hoàn 100% BVC; quá 24h → `lobby.status = expiredByCafe` + hoàn 100% BVC.

### 4.2. API liên quan (đã có sẵn)
- `GET /api/v1/reservations/{reservationId}` (đã dùng cho `LobbyReservationCubit`) → trả về `requiresCafeApproval`, `cafeApprovalDeadline`, `remainingApprovalHours/Minutes`, `cafeRejectionReason`.
- `POST /api/v1/reservations/{reservationId}/cancel` (host hủy) — refund theo BR-REFUND-02/03.

### 4.3. UI cần làm
File: `lib/features/lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart` (đã có stub? kiểm tra).

**Mục tiêu UI**: Khi `lobby.status == pendingCafeApproval`, host thấy page riêng (không phải `LobbyPage` chính) với:
1. **Hero card** (icon đồng hồ + màu warning):
   - Title: "Đang chờ quán duyệt".
   - Subtitle: "Lobby sẽ được công khai sau khi quán `{cafeName}` duyệt. Thời hạn duyệt: còn `{remainingApprovalHours}h`."
2. **Reservation summary** (lấy từ `ReservationEntity`):
   - Cafe, Game, playDate + timeSlot + preferredStartTime, currentPlayers/maxPlayers, deposit (finalDeposit + baseDeposit + riskMultiplier).
3. **Countdown tới `cafeApprovalDeadline`** (dùng pattern của `ScheduledTimeCountdown` Phase A, cần tạo `CountdownToDeadline` widget dùng chung).
4. **Action**:
   - "Hủy đặt chỗ" → gọi `POST /reservations/{id}/cancel` (refund theo BR-REFUND-02/03 — UI hiển thị mức hoàn dự kiến theo `cancel-info` cộng thêm BR-REFUND-03 grace 15p nếu chưa có member).
   - "Mời bạn bè qua mã chia sẻ" → copy share code (giống Phase A, share section trong lobby).

### 4.4. Files cần tạo / sửa
- **Mới**: `lib/features/lobby_management/presentation/widgets/countdown_to_deadline.dart` — countdown dùng chung cho `recruitmentDeadline` và `cafeApprovalDeadline`. Tái sử dụng pattern `ScheduledTimeCountdown` nhưng generic DateTime input.
- **Mới** (nếu chưa có): `lib/features/lobby_management/presentation/pages/lobby_pending_cafe_approval_page.dart`.
- **Sửa**: `lib/features/lobby_management/lobby_routes.dart` — register route `LobbyRoutes.lobbyPendingCafeApproval` đã có → trỏ tới page trên.
- **Sửa**: `lib/features/lobby_management/presentation/cubit/lobby_cubit.dart` — thêm method `cancelReservation(reservationId, reason)`:
  - Gọi `repository.cancelReservation(reservationId, reason)` (cần check `LobbyRepository` đã có method này chưa; nếu chưa → thêm vào interface + impl).
  - Nếu 200 → emit `LobbyReservationCancelled` state mới; MainScaffold lắng nghe + navigate về LobbyHubPage.
  - Nếu 409 (e.g. cafe đã duyệt) → emit `LobbyFailure` với message tiếng Việt.

### 4.5. Edge cases
- User mở app sau khi cafe từ chối → `LobbyReservationCubit` poll trả về `lobbyStatus = rejectedByCafe` + `cafeRejectionReason` → cần handle: navigate từ `LobbyPendingCafeApprovalPage` sang `LobbyEndedView` với subtitle "Quán từ chối: {reason}" + CTA "Tạo lobby mới".
- User mở app sau khi hết 24h → `lobbyStatus = expiredByCafe` → tương tự, navigate sang `LobbyEndedView` với subtitle "Quán không duyệt trong 24 giờ. Đã hoàn 100% BVC.".

### 4.6. Acceptance
- Host tạo lobby public playDate 5 ngày sau → confirm → vào `LobbyPendingCafeApprovalPage` thay vì `LobbyPage`.
- Countdown hiển thị chính xác tới `cafeApprovalDeadline` (24h).
- "Hủy đặt chỗ" → refund theo BR-REFUND-02 (trong grace 15p + chưa member = 100%).
- Cafe duyệt / từ chối / hết hạn → tự động navigate tới `LobbyPage` (mở) hoặc `LobbyEndedView` (từ chối/hết hạn).
- `dart analyze` 0 issues.

---

## 5. Phase C — "Đến quán" UX (Check-in journey)

### 5.1. Bối cảnh
Sau khi lobby full + minPlayers đạt → `lobby.status = viable` (hoặc `full`) + `reservation.status = confirmed`. Tới giờ chơi, host đến quán, nhân viên POS scan QR (encode `reservation.id`) → `POST /api/cafes/{cafeId}/pos/check-in` → `lobby.status = inProgress` + `reservation.status = checkedIn`.

### 5.2. API liên quan
- `GET /api/v1/reservations/{id}` (đang dùng) → trả `lobbyStatus`, `status`, `cafeName`, `cafeId`, `scheduledTime`.
- `GET /api/v1/lobbies/{id}` (đã có) → trả `members[]`, `cafeName`, `cafeTableId`.
- `GET /api/cafes/{cafeId}/pos/bookings/{bookingCode}` (POS preview) — dành cho POS Web, mobile KHÔNG gọi.
- `POST /api/cafes/{cafeId}/pos/check-in` (POS scan) — dành cho POS Web, mobile KHÔNG gọi. Mobile chỉ cần **hiển thị QR** để POS scan.
- `GET /api/cafes/{id}` (Cafe info, optional) — lấy thêm `address`, `phone`, `latitude/longitude` để hiển thị bản đồ / nút "Mở Google Maps".

### 5.3. UI cần làm
**Mở rộng `LobbyCheckInSection` (đã có từ Phase A)**:
- Hiện tại chỉ hiển thị QR + mã. Cần thêm:
  - **Địa chỉ quán** (từ `LobbyEntity.cafeName` + từ `GET /cafes/{id}` nếu có address).
  - **Giờ mở cửa** / số điện thoại quán (nếu có).
  - **Nút "Mở chỉ đường"** → dùng `url_launcher` (đã có) mở `https://www.google.com/maps/search/?api=1&query={lat},{lng}`.
  - **Nút "Gọi quán"** → `tel:` scheme.
  - **"Hôm nay bạn chơi ở {cafeName} lúc {HH:mm}"** — banner nổi bật.

**Mở rộng `LobbyPage` khi `lobby.status == inProgress`**:
- Check-in section ẩn QR (vì đã check-in rồi), thay bằng banner "Đang chơi tại quán" + countdown tới `timeSlot.endTime` (giờ kết thúc dự kiến theo `timeSlot.endTime` của `ReservationEntity`).
- Action button "Xem bàn của mình" → mở bottom sheet hiển thị `cafeTableId` + nút mở bản đồ.

**Mở rộng `LobbyStatusStrip` (Phase A)**: thêm case `inProgress` đã có trong `LobbyStatusBadge` nhưng chưa có countdown kết thúc → cần thêm `ScheduledTimeCountdown` với caption "Giờ kết thúc dự kiến" và `scheduledTime = scheduledTime + durationDefault` (4 tiếng mặc định, hoặc lấy từ cafe config nếu API trả về).

### 5.4. Files cần tạo / sửa
- **Sửa**: `lib/features/lobby_management/presentation/widgets/lobby_check_in_section.dart` — thêm:
  - Cafe address (fetch qua `LobbyRemoteDatasource.getCafeById` — cần check đã có chưa; nếu chưa → dùng `CafeRepository` từ `features/cafe`).
  - Nút "Mở chỉ đường" + "Gọi quán".
- **Mới**: `lib/features/lobby_management/presentation/widgets/session_end_countdown.dart` — countdown tới giờ kết thúc dự kiến (dùng khi `inProgress`).
- **Sửa**: `lib/features/lobby_management/presentation/pages/lobby_page.dart` — thêm:
  - Trong `_LobbyStatusStrip`, khi `lobby.status == inProgress` → thay `ScheduledTimeCountdown` bằng `SessionEndCountdown`.
  - Khi host bấm "Xem bàn" → mở bottom sheet (dùng `LobbyDetailsSheet` có sẵn hoặc tạo mới).
- **Kiểm tra**: `LobbyEntity` có field `cafeTableId` (đã có). Nếu `null` → hiển thị "Quán sẽ gán bàn khi bạn đến" thay vì tên bàn.

### 5.5. Edge cases
- Host chưa tới quán nhưng đã qua `scheduledTime` → countdown hiển thị "Đã tới giờ chơi" (đã có ở `ScheduledTimeCountdown`).
- Member (không phải host) cũng phải thấy QR check-in section (đã làm ở Phase A — `LobbyCheckInSection` hiển thị cho mọi member khi `reservation.status == confirmed`).
- Quán thay đổi cafe config (BR-NEW-12) → không ảnh hưởng tới lobby đã tạo (deposit snapshot). Mobile không cần handle.

### 5.6. Acceptance
- Lobby `viable` hoặc `full` + `reservation.status == confirmed` → hiển thị check-in section (đã có Phase A) + nút "Mở chỉ đường" + "Gọi quán".
- Lobby `inProgress` → ẩn QR, thay bằng banner "Đang chơi" + countdown tới giờ kết thúc dự kiến.
- "Mở chỉ đường" mở Google Maps app (nếu có) hoặc browser.
- "Gọi quán" mở dialer với SĐT prefilled.
- `dart analyze` 0 issues.

---

## 6. Phase D — Lobby End States (Closed / TimeoutFailed / HostCancelled / RejectedByCafe / ExpiredByCafe)

### 6.1. Bối cảnh
Khi lobby đạt terminal state, FE cần hiển thị UX rõ ràng cho user, **KHÔNG** chỉ là "Lobby đã kết thúc" chung chung. Mỗi state có:
- **Title + icon + màu** riêng.
- **Subtitle**: lấy từ `lobby.closedReason` (server trả) hoặc fallback message.
- **Action CTA** riêng (tạo lại, gia hạn, hoàn cọc, khiếu nại).
- **Animation / illustration** (optional, polish cuối).

### 6.2. State → UX mapping (BR §6.1, §4.10, §4.12)

| State | Title | Icon | Màu | Subtitle | Primary CTA |
|-------|-------|------|-----|----------|-------------|
| `closed` | "Phòng đã đóng" | `AppIcons.lock` | error | "Phòng đã được host đóng lại." | "Tạo phòng mới" → LobbyConfigPage |
| `timeoutFailed` | "Phòng hết hạn tuyển" | `Icons.timer_off_outlined` | error | "Không đủ người tham gia trước deadline. Đã hoàn 100% BVC." | "Tạo phòng mới" + "Xem chi tiết hoàn cọc" |
| `hostCancelled` | "Phòng đã bị hủy" | `AppIcons.cancelBooking` | error | "Host đã rời phòng và không còn thành viên nào." (từ `closedReason`) | "Tạo phòng mới" |
| `rejectedByCafe` | "Quán từ chối duyệt" | `AppIcons.cancelBooking` | error | "{cafeRejectionReason}" | "Tạo phòng khác" + "Đổi quán" |
| `expiredByCafe` | "Quán không duyệt trong 24 giờ" | `Icons.timer_off_outlined` | error | "Đã hoàn 100% BVC về ví của bạn." | "Tạo phòng mới" |
| `ratingOpen` | "Đang đánh giá Karma" | `Icons.star_outline` | warning | "Hãy đánh giá đồng đội để cải thiện cộng đồng." | "Đánh giá ngay" → RatingPage |

### 6.3. UI cần làm
**Mở rộng `LobbyEndedView` (đã có stub)**:
- Hiện tại đã có `_statusInfo(colors)` trả về `(title, icon, color, subtitle)`. Cần:
  1. Thêm case `rejectedByCafe` và `expiredByCafe` (chưa có).
  2. Thêm `ratingOpen` state riêng (chưa xử lý) → navigate sang `RatingPage` (Phase E).
  3. Thêm 2 secondary CTA: "Xem chi tiết hoàn cọc" + "Khiếu nại" (optional, mở mailto).
  4. Thêm `LobbyEntity.cafeName` + `cafeRejectionReason` (từ `ReservationEntity`) vào subtitle khi `rejectedByCafe`.

### 6.4. Files cần tạo / sửa
- **Sửa**: `lib/features/lobby_management/presentation/widgets/lobby_ended_view.dart`:
  - Thêm 2 case mới trong `_statusInfo`.
  - Thêm secondary CTA row (4 nút: Tạo lại / Gia hạn / Hoàn cọc / Khiếu nại) theo state.
  - Logic `_onRecreateEndedLobby` đã có → dùng `LobbyFlowNavigator.pushAndKeepRootOnly` (helper đã có) navigate tới `LobbyConfigPage` (xem `lobby_quote_page.dart`).
  - Logic `_onExtendEndedLobby` → hiện tại chỉ navigate back; cần check xem có API extend slot chưa (BR-NEW-15 chỉ có 4 slot cố định, không extend được — UI phải ẩn nút này).
  - Logic `_onShowDetails` → mở `LobbyDetailsSheet` (đã có).
  - Thêm method `_onShowRefundDetail` → mở bottom sheet hiển thị ledger (Phase D' optional, hoặc chỉ snackbar "Đã hoàn X BVC về ví").

### 6.5. Edge cases
- User mở lobby từ notification khi đã terminal → vào `LobbyPage` → `_LobbyStatusStrip` không hiển thị badge countdown (vì `isTerminal == true`) → builder trả empty Column. Tốt. Nhưng cần đảm bảo `LobbyCubit` emit `LobbyEnded` state (không phải `LobbyCreated` / `LobbyUpdatedRealtime`) cho terminal lobby — check `initLobbyState` đã handle chưa.
- User mở từ "Phòng của tôi" tab → đã vào `LobbyEndedView` rồi. Không cần thêm navigation.

### 6.6. Acceptance
- Lobby `timeoutFailed` → `LobbyEndedView` với title "Phòng hết hạn tuyển", subtitle "Không đủ người trước deadline. Đã hoàn 100% BVC." + CTA "Tạo phòng mới".
- Lobby `rejectedByCafe` → subtitle chứa `cafeRejectionReason` từ reservation.
- Lobby `ratingOpen` → CTA "Đánh giá ngay" (Phase E sẽ implement destination).
- `dart analyze` 0 issues.

---

## 7. Phase E — Post-session: Karma Rating

### 7.1. Bối cảnh
Sau khi POS kết thúc phiên (`POST /pos/sessions/{id}/end` → `POST /pos/sessions/{id}/checkout` → `POST /pos/sessions/{id}/pay`) → backend cập nhật:
- `reservation.status = completed`, `lobby.status = ratingOpen` (mở cửa sổ đánh giá).
- Sau khi mọi member đánh giá xong (hoặc timeout 7 ngày) → `lobby.status = closed`.

### 7.2. API liên quan
Đọc `@.agents/docs/apis_docs/booking-rating.md` (file này **BẮT BUỘC** đọc trước khi code). API sẽ có:
- `GET /api/v1/lobbies/{id}/rating-window` — kiểm tra rating window có mở không, deadline.
- `GET /api/v1/lobbies/{id}/members-to-rate` — danh sách member cần đánh giá (chưa đánh giá).
- `POST /api/v1/lobbies/{id}/ratings` — submit đánh giá 1 member.
- (Optional) `POST /api/v1/lobbies/{id}/rating-window/close` — host bấm "Hoàn tất phiên" (chỉ khi tất cả member đã đánh giá).

**Chưa chốt API exact — Phase E cần check swagger.json + booking-rating.md trước khi code.** Stub endpoint paths ở trên là dự đoán dựa trên docs hiện có.

### 7.3. UI cần làm
**`LobbyRatingPage`** (`lib/features/lobby_management/presentation/pages/lobby_rating_page.dart`) — mới:
- Mở từ:
  - `LobbyPage` khi `lobby.status == ratingOpen` → CTA "Đánh giá ngay".
  - `LobbyEndedView` (Phase D) khi `ratingOpen`.
  - Notification khi user tap "Đánh giá phiên chơi".
- Layout:
  1. **Header**: icon sao + title "Đánh giá đồng đội" + subtitle "Giúp cộng đồng BoardVerse phát triển.".
  2. **Member list** (lấy từ `LobbyEntity.players` loại trừ current user):
     - Mỗi tile: avatar + tên + 5 sao + optional text "Đồng đội tốt / Fair / Thất vọng".
     - Tile có 2 trạng thái: chưa đánh giá (full controls) / đã đánh giá (chip "Đã đánh giá" + read-only).
  3. **Bottom action bar**:
     - "Lưu & tiếp tục sau" → snackbar + back.
     - "Gửi đánh giá" → gọi `POST /ratings` cho từng member → snackbar "Đã gửi đánh giá! Cảm ơn bạn." → navigate về LobbyHubPage.

**LobbyStatusStrip extension** (Phase A):
- Khi `lobby.status == ratingOpen` → show badge + banner nổi bật "Đánh giá Karma đang mở" + CTA "Đánh giá ngay" → navigate `LobbyRatingPage`.

### 7.4. Files cần tạo / sửa
- **Mới**: `lib/features/lobby_management/presentation/pages/lobby_rating_page.dart`.
- **Mới**: `lib/features/lobby_management/presentation/cubit/lobby_rating_cubit.dart` — state: `LobbyRatingInitial`, `LobbyRatingLoaded(membersToRate, submittedIds)`, `LobbyRatingSubmitting`, `LobbyRatingSuccess`, `LobbyRatingError`. Methods: `load()`, `submitRating(memberId, stars, comment)`.
- **Mới**: `lib/features/lobby_management/domain/entities/lobby_rating_entity.dart` — `LobbyRatingEntity { id, lobbyId, raterId, rateeId, stars (1-5), comment, createdAt }`.
- **Mới**: `lib/features/lobby_management/data/models/lobby_rating_model.dart` — JSON DTO.
- **Sửa**: `lib/features/lobby_management/data/datasources/base/lobby_remote_datasource.dart` + `real_lobby_remote_datasource.dart` — thêm `getRatingWindow`, `getMembersToRate`, `submitRating`.
- **Sửa**: `lib/features/lobby_management/domain/repositories/lobby_repository.dart` + `lobby_repository_impl.dart` — thêm 3 method trên.
- **Sửa**: `lib/core/constants/api_endpoints.dart` — thêm:
  ```dart
  static String lobbyRatingWindow(String lobbyId) => '/api/v1/lobbies/$lobbyId/rating-window';
  static String lobbyMembersToRate(String lobbyId) => '/api/v1/lobbies/$lobbyId/members-to-rate';
  static String lobbySubmitRatings(String lobbyId) => '/api/v1/lobbies/$lobbyId/ratings';
  ```
- **Sửa**: `lib/features/lobby_management/lobby_routes.dart` — thêm route `LobbyRoutes.lobbyRating` → `LobbyRatingPage`.
- **Sửa**: `lib/features/lobby_management/presentation/widgets/lobby_status_badge.dart` — thêm variant `ratingOpen` (đã có).
- **Sửa**: `lib/features/lobby_management/presentation/pages/lobby_page.dart` — trong `_LobbyStatusStrip`, khi `lobby.status == ratingOpen` → show CTA button "Đánh giá ngay".
- **Sửa**: `lib/features/lobby_management/presentation/widgets/lobby_ended_view.dart` (Phase D) — khi `ratingOpen` → CTA "Đánh giá ngay" navigate `LobbyRatingPage`.

### 7.5. Edge cases
- Member đã đánh giá tất cả → `LobbyRatingCubit.load()` trả về list rỗng → UI hiển thị "Bạn đã đánh giá tất cả. Cảm ơn!" + auto-pop sau 3s.
- Host bấm "Hoàn tất phiên" khi chưa tất cả member đánh giá → 409 → snackbar "Mọi thành viên cần đánh giá trước khi đóng phiên." (nếu API này tồn tại).
- `ratingOpen` > 7 ngày → backend tự đóng → lobby chuyển `closed` → UI `LobbyEndedView` tự reload.
- User truy cập `LobbyRatingPage` từ notification khi lobby đã `closed` → snackbar "Phiên đánh giá đã đóng" + back.

### 7.6. Acceptance
- Lobby `ratingOpen` → badge "Đang đánh giá" + CTA "Đánh giá ngay" → mở `LobbyRatingPage`.
- Member list load từ API, mỗi tile có 5 sao + textarea.
- "Gửi đánh giá" → POST 1 lần cho tất cả member chưa đánh giá (hoặc nhiều POST tuỳ API) → snackbar thành công.
- Reload page → tile chuyển sang "Đã đánh giá" (read-only).
- `dart analyze` 0 issues.

---

## 8. Cross-cutting Concerns (áp dụng cho cả 4 phase)

### 8.1. Polling strategy
- **Phase B (cafe approval)**: `LobbyReservationCubit` đã poll `GET /reservations/{id}` mỗi 15s. Đủ nhanh cho cafe approval flow.
- **Phase C (in-progress)**: Cần thêm poll `GET /lobbies/{id}` mỗi 30s để catch `lobby.status = inProgress` và `cafeTableId` mới (POS scan → backend update). Có thể thêm method vào `LobbyCubit` hoặc tạo cubit mới `LobbyRealtimeCubit` (tương tự `LobbyReservationCubit`).
- **Phase D (terminal)**: Khi `lobby.status` chuyển sang terminal → `LobbyReservationCubit` stop poll; `LobbyCubit` emit `LobbyEnded` (đã có) → `LobbyPage` tự render `LobbyEndedView`.
- **Phase E (rating)**: `LobbyRatingCubit` poll nhẹ mỗi 60s (chỉ cần update `submittedIds`), hoặc skip poll vì user thường ở trong page.

### 8.2. Navigation
- Sau mỗi phase, **đảm bảo navigation stack sạch**: dùng `LobbyFlowNavigator.pushAndKeepRootOnly` (helper đã có trong `lib/features/lobby_management/presentation/pages/lobby_quote_page.dart` — kiểm tra file). Mục tiêu: user back từ `LobbyPage` / `LobbyPendingCafeApprovalPage` / `LobbyEndedView` / `LobbyRatingPage` về thẳng `MainScaffold` (root), không quay lại các page trung gian (LobbyConfigPage, LobbyQuotePage cũ với data stale).
- Pattern (xem `lobby_quote_page.dart._openCreatedLobby`):
  ```dart
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => LobbyPage(...)),
    (route) => route.isFirst,
  );
  ```

### 8.3. State management
- **KHÔNG** thêm state vào `LobbyCubit` (đã quá nhiều). Mỗi phase nên tạo cubit riêng:
  - Phase B: tái sử dụng `LobbyReservationCubit` (đã có). Có thể thêm `cancelReservation` method vào `LobbyCubit` (vì là host action).
  - Phase C: cubit mới `LobbySessionCubit` (optional, có thể bỏ nếu `LobbyReservationCubit` đủ).
  - Phase D: dùng `LobbyCubit.LobbyEnded` state (đã có).
  - Phase E: cubit mới `LobbyRatingCubit`.
- Mỗi cubit phải `registerFactory<...>()` trong `injection.dart`.

### 8.4. Reuse existing widgets
- `LobbyStatusBadge` (Phase A) — dùng cho mọi state, không tạo badge mới.
- `ScheduledTimeCountdown` (Phase A) — dùng cho deadline cafe approval, recruitment, scheduledTime.
- `LobbyCheckInSection` (Phase A) — mở rộng thêm địa chỉ + nút bản đồ.
- `TopSnackBar` (Phase 0) — `context.showTopSnackBar('msg', isError: true)`.
- `LobbyDetailsSheet` (đã có) — dùng cho "Xem chi tiết" trong terminal state.

### 8.5. Error handling
- Mọi API call phải có try/catch + emit error state + hiển thị `TopSnackBar` (isError: true).
- 401 → logout + navigate về LoginPage (xem `AuthInterceptor`).
- 403 user suspended/banned → hiển thị page "Tài khoản bị hạn chế" (BR-RISK-04) — kiểm tra đã có chưa.
- 409 conflict → snackbar tiếng Việt diễn giải lỗi (vd: "Lobby đã đầy", "Bạn đang là member của lobby khác").

### 8.6. Logging
- Dùng `debugPrint('[Lobby][PhaseB] message')` pattern, có prefix theo phase.
- KHÔNG log PII (JWT, password, SĐT).

### 8.7. Test checklist (manual, sau mỗi phase)
1. Happy path: tạo lobby → confirm → vào đúng page theo state.
2. Realtime: poll cập nhật state đúng (vd: cafe duyệt → `pendingCafeApproval` → `open`).
3. Edge case: app kill + reopen → state restore từ cache (xem `LobbyPersistenceService`).
4. Edge case: navigate back stack đúng.
5. Edge case: error API → snackbar + retry button.
6. `dart analyze` 0 issues.
7. Build APK: `flutter build apk --debug` thành công.

---

## 9. Tài liệu BẮT BUỘC đọc trước khi code

Agent thực hiện phase nào thì đọc docs tương ứng (theo thứ tự):

### 9.1. Tài liệu nghiệp vụ (BR)
- `@.agents/docs/lobby_booking_deposit_business_rules.md` — toàn bộ BR §1–18, đặc biệt §4.10 (BR-REFUND-02/03), §4.17 (BR-NEW-10/11), §5.1 (Reservation state), §5.3 (Lobby state), §6 (Flows), §17 (Recruitment Window), §18 (Risk Alert).
- `@.agents/docs/infomation_project.md` — bối cảnh đồ án.
- `@.agents/docs/mobile_architeture.md` — kiến trúc tổng thể Flutter.
- `@.agents/docs/design_system.md` — design tokens + components.

### 9.2. API docs (theo phase)
- **Phase B**: `@.agents/docs/apis_docs/reservation.md` (đã đọc).
- **Phase C**: `@.agents/docs/apis_docs/cafe-pos.md` (đã đọc), `@.agents/docs/apis_docs/lobby.md`.
- **Phase D**: `@.agents/docs/apis_docs/lobby.md` (state machine), `@.agents/docs/apis_docs/reservation.md`.
- **Phase E**: `@.agents/docs/apis_docs/booking-rating.md` (PHẢI ĐỌC trước khi code), `@.agents/docs/apis_docs/lobby.md`.
- Chung: `@.agents/docs/apis_docs/lobby-hub.md` (SignalR — note: hiện tại FE dùng polling, không dùng SignalR), `@.agents/docs/apis_docs/wallet.md`.
- Swagger toàn project: `@.agents/docs/swagger.json`.

### 9.3. Codebase liên quan
- `lib/features/lobby_management/` — toàn bộ (đã có stub cho invite, share, check-in).
- `lib/features/reservation/` — `ReservationCubit`, `ReservationRepository`, `ReservationModel`.
- `lib/features/matchmaking_discovery/` — flow tạo lobby + deposit (cũ, có thể refactor trong tương lai).
- `lib/features/booking_payment/` — flow thanh toán cũ (legacy, có thể bỏ).
- `lib/features/cafe/` — cafe info nếu cần lấy address/phone.
- `lib/core/` — DI, theme, helpers.

### 9.4. Skill files
- `@.agents/skills/dart-add-unit-test/SKILL.md` — viết unit test cho cubit / repository.
- `@.agents/skills/dart-run-static-analysis/SKILL.md` — chạy `dart analyze` + `dart fix --apply`.
- `@.agents/skills/flutter-apply-architecture-best-practices/SKILL.md` — Clean Architecture.
- `@.agents/skills/flutter-use-http-package/SKILL.md` — Dio patterns.
- `@.agents/skills/flutter-implement-json-serialization/SKILL.md` — `fromJson` / `toJson` chuẩn.

---

## 10. Thứ tự triển khai khuyến nghị

1. **Phase B trước** — quan trọng nhất vì blocking flow tạo lobby public > 2 ngày. Cần để user không bị stuck ở `LobbyConfigPage` khi confirm xong.
2. **Phase C** — UX tốt cho check-in, dễ test (chỉ cần 1 lobby `confirmed` để verify).
3. **Phase D** — extension của `LobbyEndedView` có sẵn, ít rủi ro.
4. **Phase E** — phức tạp nhất vì cần check API `booking-rating.md` (có thể chưa implement backend). Nên làm sau khi backend xác nhận endpoint.

Mỗi phase:
1. Đọc docs liên quan.
2. Khảo sát code hiện tại (cubit, page, route).
3. Tạo TodoWrite với các bước nhỏ.
4. Code + test manual.
5. `dart analyze` → fix hết.
6. Báo cáo user review → commit.

---

## 11. Câu hỏi thường gặp (FAQ)

**Q: Có cần thay đổi gì trong `matchmaking_discovery` không?**
A: Có thể cần thêm navigation guard trong `LobbyConfigPage` — sau khi confirm thành công + lobby ở `pendingCafeApproval`, navigate tới `LobbyPendingCafeApprovalPage` thay vì `LobbyPage`. Check `lobby_quote_page.dart._openCreatedLobby` (đã làm theo pattern này) để biết cách navigate.

**Q: `LobbyPersistenceService` cache lobby state — cần cập nhật gì?**
A: Kiểm tra service này (`lib/features/lobby_management/data/services/lobby_persistence_service.dart`) đã lưu các field mới chưa (`reservationId`, `cafeTableId`, `closedAt`, `closedReason`, `cancellationLeadTimeMinutes`). Nếu thiếu → thêm vào để app restore state khi offline/kill.

**Q: Có cần handle offline mode không?**
A: MVP không cần. Nếu mất mạng → API fail → snackbar + retry. Cache `LobbyEntity` + `ReservationEntity` đã có trong `LobbyPersistenceService` đủ để hiển thị UI offline cơ bản.

**Q: Realtime hay polling?**
A: Hiện tại FE dùng polling (BR §16.1: "SignalR cho MVP+1"). Realtime qua SignalR sẽ là task tương lai. Đừng implement SignalR trong 4 phase này.

**Q: Localization?**
A: MVP chỉ tiếng Việt. Hardcode strings trong widget. Phase sau sẽ tích hợp `intl` + `flutter_localizations`.

**Q: Có cần viết unit test không?**
A: Có cho cubit (test state transition). Widget test optional. Integration test (Flutter Driver) chỉ khi user yêu cầu.

---

## 12. Tóm tắt deliverables

| Phase | File mới | File sửa | Ước tính |
|-------|---------|----------|----------|
| **B** | `countdown_to_deadline.dart`, `lobby_pending_cafe_approval_page.dart` | `lobby_routes.dart`, `lobby_cubit.dart` (cancelReservation), `lobby_ended_view.dart` (navigate từ rejectedByCafe/expiredByCafe) | 1–2 ngày |
| **C** | `session_end_countdown.dart` (optional) | `lobby_check_in_section.dart` (cafe address, maps, call), `lobby_page.dart` (inProgress case) | 0.5–1 ngày |
| **D** | — | `lobby_ended_view.dart` (4 state mới: rejectedByCafe, expiredByCafe, ratingOpen + secondary CTA) | 0.5 ngày |
| **E** | `lobby_rating_page.dart`, `lobby_rating_cubit.dart`, `lobby_rating_entity.dart`, `lobby_rating_model.dart` | `lobby_remote_datasource.dart`, `lobby_repository.dart`, `api_endpoints.dart`, `lobby_routes.dart`, `lobby_page.dart` (ratingOpen CTA), `lobby_ended_view.dart` (CTA) | 1–2 ngày |

**Tổng**: ~4–6 ngày làm việc cho 1 dev Flutter senior.

---

## 13. Liên hệ

Nếu gặp vấn đề khi triển khai:
1. Check `@.agents/docs/lobby_docs/lobby-lifecycle-presentation.md` — design intent.
2. Check `@.agents/docs/matchmaking_booking_module/state.md` — state machine canonical.
3. Check `@.agents/docs/matchmaking_booking_module/mobile_tasks.md` — task breakdown cũ (có thể tham khảo).
4. Hỏi user qua `@` mention trong chat.

Tài liệu này sống tại: `d:\FPT\Major\major9\SEP490_CP.SU26\code\boardverse_mobile\.agents\docs\lobby_docs\Lobby_Lifecycle_Phase_B_to_E_Plan.md`. Cập nhật khi có thay đổi phase hoặc phát hiện requirement mới.
