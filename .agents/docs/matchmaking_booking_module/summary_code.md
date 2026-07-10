# Boardverse Mobile — Module Documentation

> **Ngày cập nhật:** 2026-07-10  
> **Phiên bản:** 1.0  
> **Project:** Boardverse Mobile (Flutter)  
> **Platform:** Android, iOS (chưa có Web/Desktop)

---

## Mục lục

1. [Tổng quan kiến trúc](#1-tổng-quan-kiến-trúc)
2. [Module Matchmaking Discovery](#2-module-matchmaking-discovery)
3. [Module Lobby Management](#3-module-lobby-management)
4. [Module Booking & Payment](#4-module-booking--payment)
5. [Business Rules](#5-business-rules)
6. [Dependency Injection](#6-dependency-injection)
7. [State Machine](#7-state-machine)
8. [Bugs đã fix & Known Issues](#8-bugs-đã-fix--known-issues)
9. [TODO — Việc cần làm tiếp](#9-todo--việc-cần-làm-tiếp)

---

## 1. Tổng quan kiến trúc

### 1.1 Cấu trúc thư mục

```
lib/
├── core/
│   ├── config/         # AppConfig, environment variables
│   ├── constants/      # API endpoints
│   ├── di/            # Dependency injection (GetIt)
│   ├── navigation/    # Route definitions
│   └── network/        # Dio client, interceptors
├── features/
│   ├── auth/           # Authentication
│   ├── profile/        # User profile
│   ├── matchmaking_discovery/   # Tìm game, cafe, tạo phòng
│   ├── lobby_management/        # Quản lý phòng chờ
│   ├── booking_payment/        # Đặt chỗ & thanh toán cọc
│   ├── in_game_experience/    # Trải nghiệm trong trận
│   └── match_summary_rating/   # Đánh giá sau trận
└── main.dart
```

### 1.2 Tech Stack

| Thành phần | Package | Mục đích |
|------------|---------|-----------|
| State Management | `flutter_bloc` (Cubit) | Quản lý state, sealed classes |
| DI | `get_it` | Dependency injection |
| Network | `dio` + `AuthInterceptor` | Gọi REST API |
| Secure Storage | `flutter_secure_storage` | Lưu token, pending booking |
| QR Code | `qr_flutter` | Hiển thị mã QR booking |
| URL Launcher | `url_launcher` | Mở app thanh toán, maps |
| Formatting | `intl` | Format ngày giờ, tiền tệ |
| Testing | `bloc_test`, `mockito` | Unit tests |

### 1.3 Mock Data

```dart
// lib/core/config/app_config.dart
AppConfig.useMockData = true  // Dùng mock datasource
AppConfig.useMockData = false // Dùng backend thật
```

**Hiện tại:** `useMockData = true` → tất cả features dùng mock data, không cần backend.

---

## 2. Module Matchmaking Discovery

### 2.1 Mục đích

Cho phép user tìm kiếm board game, cafe gần đó, xem chi tiết game, và cấu hình phòng chờ (lobby) để mời bạn bè cùng chơi.

### 2.2 Cấu trúc file

```
lib/features/matchmaking_discovery/
├── data/
│   ├── datasources/
│   │   ├── base/matchmaking_datasource.dart      # Interface
│   │   └── mock_matchmaking_datasource.dart      # Mock impl (535 lines)
│   ├── models/
│   │   ├── board_game_model.dart
│   │   ├── cafe_model.dart
│   │   ├── game_category_model.dart
│   │   └── seat_availability_model.dart
│   └── matchmaking_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── board_game_entity.dart
│   │   ├── cafe_entity.dart
│   │   ├── game_category_entity.dart
│   │   ├── search_filter_entity.dart
│   │   └── seat_availability_entity.dart
│   └── repositories/
│       └── matchmaking_repository.dart           # Interface
└── presentation/
    ├── cubit/
    │   ├── matchmaking_cubit.dart                # 371 lines
    │   └── matchmaking_state.dart
    ├── pages/
    │   ├── search_page.dart                      # Tìm kiếm game/cafe
    │   ├── board_game_detail_page.dart           # Chi tiết game
    │   └── lobby_config_page.dart               # Cấu hình phòng chờ
    └── widgets/
        ├── board_game_card.dart
        ├── cafe_card.dart
        ├── booking_button.dart
        ├── game_filter_chips.dart
        ├── game_search_bar.dart
        ├── seat_availability_indicator.dart
        └── similar_games_carousel.dart
```

### 2.3 Luồng chính

```
SearchPage
  → [Tìm kiếm, filter theo game category]
  → BoardGameDetailPage
      → [Chọn cafe, số ghế]
      → LobbyConfigPage
          → [Chọn ngày, giờ, số người thêm, public/private]
          → Tạo Lobby
              → Chuyển sang LobbyPage (lobby_management)
```

### 2.4 File quan trọng

#### `lobby_config_page.dart`

Trang cấu hình phòng chờ trước khi tạo lobby.

**Tính năng đã implement:**
- DatePicker: chọn ngày hẹn (hôm nay → +30 ngày)
- TimePicker: chọn giờ hẹn
- Slider: chọn số người thêm (minPlayers - 1 → maxPlayers - 1)
- Toggle: công khai (public) / riêng tư (private)
- Validation: thời gian phải trong tương lai

```dart
// Key state
late DateTime _selectedDate;  // Khởi tạo = hôm nay
TimeOfDay _selectedTime;       // Giờ hẹn

// Key method
Future<void> _selectDate() async {
  // showDatePicker với firstDate=hôm nay, lastDate=hôm nay+30 ngày
}

Future<void> _selectTime() async {
  // showTimePicker
}

Future<void> _createLobby() async {
  // Validate: scheduledDateTime > now()
  // Gọi repository tạo lobby
}
```

#### `matchmaking_cubit.dart`

Cubit quản lý state cho toàn bộ luồng matchmaking.

**States:**
- `MatchmakingInitial`
- `MatchmakingLoading`
- `MatchmakingLoaded(games, cafes, filters)`
- `MatchmakingError(message)`

**Methods:**
- `searchGames(query)` — tìm kiếm board game
- `filterByCategory(category)` — lọc theo danh mục
- `loadCafes()` — load danh sách cafe
- `selectGame(game)` — chọn game để xem chi tiết
- `createLobby(config)` — tạo lobby mới

---

## 3. Module Lobby Management

### 3.1 Mục đích

Quản lý phòng chờ (lobby) sau khi được tạo từ Matchmaking Discovery. Host có thể mời bạn bè, xem trạng thái thành viên, và bắt đầu trận đấu.

### 3.2 Cấu trúc file

```
lib/features/lobby_management/
├── data/
│   ├── datasources/
│   │   ├── mock_lobby_datasource.dart          # Mock data
│   │   └── remote/lobby_remote_datasource.dart  # Remote interface
│   ├── lobby_repository_impl.dart
│   └── lobby_persistence_service.dart           # Lưu lobby đang tham gia
├── domain/
│   ├── entities/
│   │   ├── lobby_entity.dart
│   │   └── lobby_summary.dart
│   └── repositories/
│       └── lobby_repository.dart                # Interface
└── presentation/
    ├── cubit/
    │   ├── lobby_cubit.dart                     # Main state machine
    │   ├── lobby_state.dart
    │   └── lobby_search_cubit.dart              # Tìm kiếm lobby
    ├── pages/
    │   ├── lobby_page.dart                      # Chi tiết lobby
    │   └── nearby_lobbies_page.dart             # Lobby gần đó
    └── widgets/
        ├── lobby_countdown_timer.dart           # Đếm ngược bắt đầu
        └── online_friends_list.dart             # Bạn bè online
```

### 3.3 Luồng chính

```
LobbyPage
  → [Host] Chờ thành viên tham gia
  → [Khi đủ người] → Bắt đầu trận → InGameSessionPage
  → [Hết giờ chờ] → Lobby hết hạn
```

### 3.4 Lobby States

```
LobbyStatus:
├── waiting     # Đang chờ thành viên
├── starting    # Đủ người, sắp bắt đầu
├── inProgress  # Trận đấu đang diễn ra
├── completed   # Trận đấu kết thúc
└── cancelled   # Bị hủy
```

---

## 4. Module Booking & Payment

### 4.1 Mục đích

Xử lý luồng đặt chỗ và thanh toán cọc theo mô hình **Single-Payer** (Host thanh toán, các thành viên khác ghi nợ Host).

### 4.2 Cấu trúc file

```
lib/features/booking_payment/
├── data/
│   ├── booking_persistence_service.dart          # Lưu pending booking ID
│   ├── booking_repository_impl.dart             # Repository implementation
│   ├── datasources/
│   │   ├── base/
│   │   │   ├── booking_remote_datasource.dart   # Interface
│   │   │   └── payment_gateway.dart             # Interface gateway
│   │   ├── mock/
│   │   │   ├── mock_booking_remote_datasource.dart  # In-memory store
│   │   │   └── mock_payment_gateway.dart        # Mock payment
│   │   └── remote/
│   │       └── booking_remote_datasource_impl.dart   # Dio implementation
│   └── models/
│       ├── booking_model.dart
│       ├── booking_history_model.dart
│       └── deposit_config_model.dart
├── domain/
│   ├── entities/
│   │   ├── booking_entity.dart
│   │   ├── booking_history_entity.dart
│   │   └── deposit_config_entity.dart
│   ├── enums/
│   │   ├── booking_status.dart
│   │   ├── payment_method.dart
│   │   └── pricing_model.dart
│   └── repositories/
│       └── booking_repository.dart              # Interface
└── presentation/
    ├── cubit/
    │   ├── booking_summary_cubit.dart           # Tạo booking, load config
    │   ├── booking_summary_state.dart
    │   ├── payment_cubit.dart                  # Thanh toán cọc
    │   ├── payment_state.dart
    │   ├── booking_result_cubit.dart           # Xem lịch sử, QR scan
    │   └── booking_result_state.dart
    ├── pages/
    │   ├── booking_summary_page.dart            # Xem tổng kết, confirm
    │   ├── payment_page.dart                    # Mở cổng thanh toán
    │   ├── booking_success_page.dart            # Thành công + QR
    │   ├── booking_history_page.dart            # Lịch sử đặt chỗ
    │   └── booking_detail_page.dart             # Chi tiết booking
    └── widgets/
        ├── booking_qr_card.dart                 # Hiển thị QR code
        ├── cancel_booking_dialog.dart           # Dialog hủy 2 bước
        ├── countdown_banner.dart                # Đếm ngược deadline
        ├── deposit_breakdown_card.dart          # Chi tiết tiền cọc
        ├── no_show_badge.dart                   # Badge vắng mặt
        ├── payment_method_selector.dart         # Chọn phương thức TT
        └── qr_scanner_mock_dialog.dart          # Mock quét QR (dev)
```

### 4.3 Luồng thanh toán (Payment Flow)

```
┌─────────────────────┐
│  BookingSummaryPage  │
│  (Xem tổng kết)      │
└──────────┬──────────┘
           │ Submit
           ▼
┌─────────────────────┐
│   PaymentPage       │
│  (Chọn phương thức) │
└──────────┬──────────┘
           │ Mở cổng thanh toán
           ▼
┌─────────────────────┐
│  PaymentGateway     │◄── Polling đợi callback
│  (VNPay/MoMo mock)  │
└──────────┬──────────┘
     ┌─────┴─────┐
     │           │
 Success     Failed
     │           │
     ▼           ▼
┌─────────────────────┐
│ BookingSuccessPage  │  ┌─────────────────────┐
│ (Hiển thị QR)       │  │ Dialog thông báo    │
└─────────────────────┘  │ lỗi + về trang chính│
                        └─────────────────────┘
```

### 4.4 Chi tiết các Cubit

#### 4.4.1 BookingSummaryCubit

Quản lý trang xem tổng kết trước khi thanh toán.

**States:**
```dart
sealed class BookingSummaryState {
  SummaryInitial
  SummaryLoading
  SummaryReady(config, calculatedAmount)     // Config loaded, có thể submit
  SummarySubmitting                            // Đang tạo booking
  SummarySuccess(bookingId, depositAmount, deadline)
  SummaryFailure(NO_CONFIG | DEPOSIT_CAP | CREATE | FETCH_CONFIG)
}
```

**Methods:**
- `loadDepositConfig(cafeId, gameId, scheduledTime, players)` — Load cấu hình cọc
- `submitBooking()` — Tạo booking với API

#### 4.4.2 PaymentCubit

Quản lý toàn bộ luồng thanh toán.

**States:**
```dart
sealed class PaymentState {
  PaymentIdle                                   // Chưa mở gateway
  PaymentOpening                                // Đang mở gateway
  PaymentAwaitingCallback(bookingId, deadline)   // Đợi callback
  PaymentProcessing                             // Đang xử lý kết quả
  PaymentSuccess(bookingId, transactionRef)     // Thanh toán thành công
  PaymentFailed(reason)                         // Thanh toán thất bại
  PaymentTimeout                                // Hết thời gian chờ
}
```

**Methods:**
- `openGateway(bookingId, amount, method)` — Mở cổng thanh toán
- `onGatewayCallback(result)` — Xử lý kết quả từ gateway
- `cancelByUser()` — User hủy thanh toán
- `onDeadlineExpired()` — Deadline hết hạn

**Tự động xử lý:**
- Khi gateway fail/timeout → tự động gọi `cancelBookingByPlayer()`
- Khi booking confirmed → clear pending booking từ storage

#### 4.4.3 BookingResultCubit

Quản lý trang thành công và lịch sử booking.

**States:**
```dart
sealed class BookingResultState {
  ResultInitial
  ResultLoading
  ResultConfirmed(booking)                      // Booking đang active
  ResultCancelled(booking)
  ResultHistory(List<BookingHistoryEntity>)     // Lịch sử đặt chỗ
  ResultUpcomingBookings(List<BookingEntity>)   // Booking sắp tới
  ResultUpcomingAndHistory(upcoming, history)   // Load song song
  ResumeToPayment(bookingId)
  ResumeToSuccess(booking)
}
```

**Methods:**
- `loadUpcomingBookings()` — Load booking sắp tới
- `loadHistory()` — Load lịch sử
- `loadUpcomingAndHistory()` — Load cả 2 song song (tránh race condition)
- `checkAndResumePendingBooking()` — Kiểm tra và restore pending booking

### 4.5 Chi tiết các Entity

#### BookingEntity

```dart
class BookingEntity {
  final String id;
  final String lobbyId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final DateTime scheduledTime;
  final BookingStatus status;           // pendingDeposit / confirmed / checkedIn / expired / cancelledByPlayer / cancelledByCafe
  final int depositAmount;              // Số tiền cọc (VND)
  final DateTime depositDeadline;       // Hạn chót thanh toán
  final PaymentMethod paymentMethod;    // Phương thức đã dùng
  final String qrPayload;               // Nội dung QR code
  final String hostId;
  final List<String> memberIds;
  final String? checkInCode;
}
```

#### BookingStatus Enum

```dart
enum BookingStatus {
  pendingDeposit,      // Chờ thanh toán cọc
  confirmed,          // Đã thanh toán, xác nhận
  checkedIn,          // Đã check-in tại quán
  expired,            // Hết hạn (không thanh toán kịp)
  cancelledByPlayer,  // Hủy bởi player
  cancelledByCafe,    // Hủy bởi cafe
}
```

**Extensions:**
```dart
extension BookingStatusX on BookingStatus {
  bool get isTerminal       // confirmed, expired, cancelled... → không chuyển tiếp được
  bool get isActive        // pendingDeposit, confirmed, checkedIn
  bool get canPlayerCancel // confirmed, pendingDeposit (không phải checkedIn/expired)
  String get displayLabel  // "Chờ thanh toán", "Đã xác nhận"...
}
```

#### DepositConfigEntity

```dart
class DepositConfigEntity {
  final int graceMinutes;           // Thời gian chờ thanh toán (≤30 phút)
  final int minDeposit;             // Số tiền cọc tối thiểu
  final int maxDeposit;             // Số tiền cọc tối đa (≤ 50% giờ đầu)
  final PricingModel pricingModel;  // hourly / flatEntry
  final int? firstHourPrice;        // Giá giờ đầu (nếu hourly)
  final int? flatEntryPrice;        // Giá vào cửa cố định (nếu flatEntry)
  
  bool canAccept(int amount)         // Kiểm tra amount có hợp lệ
}
```

### 4.6 Chi tiết các Widget

#### CountdownBanner

Hiển thị countdown đến deadline thanh toán.

```dart
CountdownBanner(
  deadline: DateTime,
  onExpired: () { /* xử lý timeout */ },
  onTick: (remaining) { /* cập nhật UI */ },
)
```

**Behavior:**
- Format: `MM:SS` hoặc `HH:MM:SS` nếu > 1 giờ
- Khi < 5 phút: hiển thị màu cảnh báo (orange)
- Khi < 1 phút: hiển thị màu nguy hiểm (red)
- Khi hết giờ: gọi `onExpired`

#### BookingQRCard

Hiển thị QR code và thông tin booking.

```dart
BookingQRCard(
  booking: BookingEntity,
  showActions: true,  // Hiện nút Cancel, Open Maps
)
```

**Chứa:**
- QR Code (dùng `qr_flutter`)
- Mã booking
- Thông tin cafe, game, giờ hẹn
- Trạng thái booking
- Nút "Mở Maps" (nếu có địa chỉ)

#### DepositBreakdownCard

Hiển thị chi tiết tiền cọc.

```dart
DepositBreakdownCard(
  config: DepositConfigEntity,
  selectedAmount: int,
  playerCount: int,
)
```

**Hiển thị:**
- Giá giờ đầu / vào cửa
- Số tiền cọc đã chọn
- Giới hạn (≤ 50% giờ đầu)
- Countdown deadline

#### PaymentMethodSelector

Chọn phương thức thanh toán.

```dart
PaymentMethodSelector(
  methods: [sandboxMock, vnpay, momo, zalopay, bank_transfer],
  selected: PaymentMethod,
  onChanged: (method) { },
)
```

---

## 5. Business Rules

### BR-03: Giới hạn tiền cọc

```
Tiền cọc ≤ 50% × Giá giờ đầu tiên
```

**Validation:** `DepositConfigEntity.canAccept(amount)`

### BR-05: Booking Success

```
Booking CONFIRMED khi:
1. Đủ số ghế (đủ người tham gia)
2. Thanh toán cọc thành công
```

### BR-06: Thời hạn giữ chỗ

```
depositDeadline = now + graceMinutes (≤ 30 phút)

Client:
- Hiển thị countdown
- Tự động cancel booking + emit PaymentTimeout khi hết hạn
```

### BR-07: Single-Payer Model

```
Mỗi booking có 1 người thanh toán (Host)
Các thành viên khác ghi nợ với Host (backend xử lý)
```

### State Machine

```
PENDING_DEPOSIT ──[thanh toán thành công]──► CONFIRMED
     │                                          │
     │──[hết deadline]──► EXPIRED               │
     │                                          │──[quét QR]──► CHECKED_IN
     │                                          │
     │──[user hủy]──► CANCELLED_BY_PLAYER      │
     │                                          │──[cafe hủy]──► CANCELLED_BY_CAFE
     ▼
[Terminal states: EXPIRED, CANCELLED_BY_PLAYER, CANCELLED_BY_CAFE]
```

---

## 6. Dependency Injection

### 6.1 Setup chính (`lib/core/di/injection.dart`)

```dart
void setupDependencies() {
  // External
  sl.registerLazySingleton<FlutterSecureStorage>(...);
  sl.registerLazySingleton<AuthInterceptor>(...);
  sl.registerLazySingleton<DioClient>(...);
  
  // Feature: Matchmaking Discovery
  if (AppConfig.useMockData) {
    sl.registerLazySingleton<MatchmakingDatasource>(() => MockMatchmakingDatasource());
  }
  sl.registerLazySingleton<MatchmakingRepository>(...);
  sl.registerFactory<MatchmakingCubit>(...);
  
  // Feature: Lobby Management
  sl.registerLazySingleton<LobbyRepository>(...);
  sl.registerFactory<LobbyCubit>(...);
  
  // Feature: Booking & Payment
  sl.registerLazySingleton<BookingRemoteDatasource>(() => 
    AppConfig.useMockData 
      ? MockBookingRemoteDatasource() 
      : BookingRemoteDatasourceImpl(dio: sl<Dio>())
  );
  
  // Mock-only: expose concrete singleton để BookingDetailPage gọi simulateQrScan
  sl.registerLazySingleton<MockBookingRemoteDatasource>(() => 
    sl<BookingRemoteDatasource>() as MockBookingRemoteDatasource
  );
  
  sl.registerLazySingleton<PaymentGateway>(() => MockPaymentGateway());
  sl.registerLazySingleton<BookingRepository>(...);
  sl.registerFactory<BookingSummaryCubit>(...);
  sl.registerFactory<PaymentCubit>(...);
  sl.registerFactory<BookingResultCubit>(...);
}
```

### 6.2 Đăng ký thêm sau khi sửa Bug 2 (2026-07-09)

```dart
// Quan trọng: phải Hot Restart (R) sau khi sửa injection.dart
// Hot Reload không re-run main() → GetIt giữ registration cũ
```

---

## 7. State Machine

### 7.1 Lobby State Machine

```
┌─────────────┐
│   CREATED   │──[user join]──► ┌─────────────┐
└─────────────┘                 │   WAITING  │
       ▲                        └──────┬──────┘
       │                               │
       │                    ┌──────────┴──────────┐
       │                    │                     │
  [lobby full]         [timeout]            [all ready]
       │                    │                     │
       ▼                    ▼                     ▼
┌─────────────┐     ┌─────────────┐      ┌─────────────┐
│  STARTING   │────►│ CANCELLED   │      │ IN_PROGRESS │
└─────────────┘     └─────────────┘      └──────┬──────┘
                                                 │
                                            [game end]
                                                 ▼
                                          ┌─────────────┐
                                          │  COMPLETED  │
                                          └─────────────┘
```

### 7.2 Payment State Machine

```
┌──────────┐  openGateway()  ┌────────────┐
│ PaymentIdle  ────────────► │PaymentOpening│
└──────────┘                 └──────┬──────┘
                                     │
                           gateway opened
                                     ▼
                           ┌─────────────────────┐
                           │PaymentAwaitingCallback│◄── polling ──┐
                           └─────────┬───────────┘               │
                                     │                             │
                    ┌────────────────┼────────────────┐           │
                    │                │                │           │
               success            failed           timeout         │
                    │                │                │           │
                    ▼                ▼                ▼           │
          ┌──────────────┐  ┌──────────────┐ ┌──────────────┐   │
          │PaymentSuccess│  │ PaymentFailed│ │PaymentTimeout│   │
          └──────────────┘  └──────────────┘ └──────────────┘   │
                                │                │                │
                          auto-cancel       auto-cancel           │
                                │                │                │
                                └────────────────┴────────────────┘
```

---

## 8. Bugs đã fix & Known Issues

### 8.1 Bug 1: ProviderNotFoundException — ĐÃ FIX ✅

**Nguyên nhân:** `PaymentPage` tạo `_cubit` ở `initState` nhưng `build()` không wrap `BlocConsumer` trong `BlocProvider.value`.

**Fix đã áp dụng:**
```dart
return BlocProvider.value(
  value: _cubit,
  child: BlocConsumer<PaymentCubit, PaymentState>(...),
);
```

### 8.2 Bug 2: GetIt crash khi gọi `simulateQrScan` — ĐÃ FIX ✅

**Nguyên nhân:** `BookingDetailPage` gọi `getIt<MockBookingRemoteDatasource>()` (concrete class) nhưng GetIt chỉ register interface `BookingRemoteDatasource`.

**Fix đã áp dụng:**
```dart
// injection.dart - thêm registration
sl.registerLazySingleton<MockBookingRemoteDatasource>(() => 
  sl<BookingRemoteDatasource>() as MockBookingRemoteDatasource,
);
```

**Lưu ý:** Phải **Hot Restart** (R) sau khi sửa.

### 8.3 Bug 3: Tab "Sắp tới" rỗng dù mock có data — ĐÃ FIX ✅

**Nguyên nhân:** Race condition - `_cubit.loadUpcomingBookings()` + `_cubit.loadHistory()` emit riêng biệt, tab "Sắp tới" nhận `ResultLoading` rồi bị stuck.

**Fix đã áp dụng:**
- Thêm state `ResultUpcomingAndHistory`
- Thêm method `loadUpcomingAndHistory()` dùng `Future.wait`
- Load song song rồi emit 1 state duy nhất

### 8.4 Known Issues (CHƯA FIX)

#### CountdownBanner.onExpired Empty Handler

```dart
CountdownBanner(
  deadline: widget.deadline,
  onExpired: () {}, // ← EMPTY
)
```

**Cần fix:** Thêm `_cubit.onDeadlineExpired()` và thêm method `onDeadlineExpired()` vào `PaymentCubit`.

#### Race Condition trong initState

```dart
void initState() {
  _init(); // async nhưng không await
}
```

**Cần fix:** Wrap `await _init()` trong try-catch.

---

## 9. TODO — Việc cần làm tiếp

### Ưu tiên cao

1. **Tích hợp VNPay / MoMo thật**
   - Hiện chỉ có `MockPaymentGateway`
   - Cần implement real gateway theo SDK từng provider
   - Thay `MockPaymentGateway` bằng `VnpayGateway` / `MomoGateway`

2. **Refactor pattern `getIt<MockBookingRemoteDatasource>()`**
   - Presentation layer không nên gọi concrete class
   - Chuyển sang gọi qua `BookingRepository` interface
   - Hoặc tạo `MockBookingRepository` riêng

3. **Fix CountdownBanner.onExpired**
   - Thêm method `onDeadlineExpired()` vào `PaymentCubit`
   - Khi deadline hết → emit `PaymentTimeout`

### Ưu tiên trung bình

4. **Polling → WebSocket**
   - `BookingRemoteDatasourceImpl.watchBookingStatus` hiện polling mỗi 3s
   - Phase sau thay bằng WebSocket để giảm tải server

5. **Currency formatting**
   - Hiện hiển thị raw số
   - Nên dùng `intl.NumberFormat.simpleCurrency(locale: 'vi_VN')`

6. **Test trên thiết bị thật**
   - Unit test đã pass nhưng chưa test trên Android emulator
   - Cần verify UX (countdown, QR scan, navigation)

### Ưu tiên thấp

7. **Web/Desktop platform**
   - Project hiện chỉ có android/ios
   - Cần `flutter create . --platforms=web,windows`

8. **flutter_secure_storage trên web**
   - Cần config `WebOptions` trong `main.dart`

9. **Cancel reason lưu DB**
   - Mock chỉ echo reason, chưa có DB persist

---

## 10. Test Coverage

```
test/features/booking_payment/
├── _fake_secure_storage.dart      # In-memory FlutterSecureStorage
├── booking_happy_path_test.dart   # 5 tests - happy path
└── booking_edge_cases_test.dart  # 9 tests - edge cases, errors

Total: 14/14 tests passed ✅
```

---

## 11. File quan trọng cần đọc khi tiếp tục

| File | Mô tả |
|------|-------|
| `lib/core/di/injection.dart` | Dependency injection setup |
| `lib/core/config/app_config.dart` | App configuration |
| `lib/features/booking_payment/domain/enums/booking_status.dart` | State machine chính |
| `lib/features/booking_payment/presentation/cubit/payment_cubit.dart` | Payment state machine |
| `lib/features/booking_payment/data/booking_repository_impl.dart` | Persistence orchestration |
| `lib/features/booking_payment/presentation/cubit/booking_result_cubit.dart` | History & resume flow |
| `lib/features/matchmaking_discovery/presentation/pages/lobby_config_page.dart` | Tạo lobby với DatePicker |
| `lib/main.dart` | App entry, resume pending booking |

---

*Document generated: 2026-07-10*
