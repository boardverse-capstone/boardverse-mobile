# Booking Payment Feature Module

## Overview

Module xử lý việc đặt chỗ và thanh toán. Bao gồm tạo booking, thanh toán qua gateway (mock VNPay/MoMo), hiển thị QR code, và quản lý lịch sử đặt chỗ.

**Tổng số file**: ~30 files

---

## 1. Architecture

```
lib/features/booking_payment/
├── domain/
│   ├── entities/
│   │   ├── booking_entity.dart         # Core booking entity
│   │   ├── booking_history_entity.dart  # Past booking records
│   │   └── deposit_config_entity.dart  # Cafe pricing config
│   ├── enums/
│   │   ├── booking_status.dart        # 6 booking states
│   │   ├── payment_method.dart       # 3 payment methods
│   │   └── pricing_model.dart        # hourly/flatEntry
│   └── repositories/
│       └── booking_repository.dart     # Repository interface
├── data/
│   ├── models/
│   │   ├── booking_model.dart
│   │   ├── booking_history_model.dart
│   │   └── deposit_config_model.dart
│   ├── datasources/
│   │   ├── base/
│   │   │   ├── booking_remote_datasource.dart
│   │   │   └── payment_gateway.dart
│   │   ├── remote/
│   │   │   └── booking_remote_datasource_impl.dart
│   │   └── mock/
│   │       ├── mock_booking_remote_datasource.dart
│   │       └── mock_payment_gateway.dart
│   ├── booking_repository_impl.dart
│   └── booking_persistence_service.dart  # SecureStorage persistence
└── presentation/
    ├── cubit/
    │   ├── booking_summary_cubit.dart
    │   ├── booking_summary_state.dart
    │   ├── payment_cubit.dart
    │   ├── payment_state.dart
    │   ├── booking_result_cubit.dart
    │   └── booking_result_state.dart
    ├── pages/
    │   ├── booking_summary_page.dart
    │   ├── payment_page.dart
    │   ├── booking_success_page.dart
    │   ├── booking_history_page.dart
    │   └── booking_detail_page.dart
    └── widgets/
        ├── booking_qr_card.dart
        ├── cancel_booking_dialog.dart
        ├── countdown_banner.dart
        ├── deposit_breakdown_card.dart
        ├── info_row.dart
        ├── no_show_badge.dart
        ├── payment_method_selector.dart
        ├── qr_scanner_mock_dialog.dart
        ├── section_header.dart
        └── status_pill.dart
```

---

## 2. Key Classes

### BookingEntity

**Key Fields:**
- `id`, `cafeId`, `gameId`
- `scheduledTime` - Appointment time
- `seatCount` - Number of seats booked
- `depositAmount` - Deposit amount
- `depositDeadline` - Grace period deadline (BR-06)
- `qrPayload` - QR code payload
- `nonce` - Unique identifier for QR scanning

**Computed Properties:**
- `remainingGraceTime` - Time until deadline
- `isLocallyExpired` - Client-side deadline check

### BookingStatus Enum

| Status | Meaning |
|--------|---------|
| `pendingDeposit` | Awaiting payment (BR-06) |
| `confirmed` | Payment successful |
| `checkedIn` | POS scanned QR (Task 4) |
| `expired` | Grace period exceeded (BR-06) |
| `cancelledByPlayer` | User cancellation |
| `cancelledByCafe` | Cafe cancellation (via polling) |

### PaymentMethod Enum

| Method | Description |
|--------|-------------|
| `sandboxMock` | Development/testing (currently active) |
| `vnpay` | Placeholder for future VNPay integration |
| `momo` | Placeholder for future MoMo integration |

### DepositConfigEntity

```dart
class DepositConfigEntity {
  final double firstHourPrice;
  final double? entryFee;
  final double maxDeposit;        // BR-03: <= 50% first hour
  final double defaultDeposit;
  final int graceMinutes;         // BR-06: <= 30 min
  final PricingModel pricingModel; // hourly or flatEntry
}
```

---

## 3. Cubits

### BookingSummaryCubit

**States:** `SummaryInitial` → `SummaryLoading` → `SummaryReady/Submitting/Success/Failure`

**Methods:**
- `loadConfig(cafeId)` - Fetches deposit configuration
- `selectPaymentMethod()` - Updates selected payment method
- `submit(...)` - Validates BR-03, creates booking

### PaymentCubit

**States:** `PaymentIdle` → `PaymentOpening` → `PaymentAwaitingCallback` → `PaymentProcessing` → `PaymentSuccess/Failed/Timeout`

**Methods:**
- `start(...)` - Opens gateway, starts countdown
- `cancelByUser(reason)` - User-initiated cancellation

**Internal:**
- `_startCountdown()` - Timer-based deadline checking
- `_onPaymentSuccess()` - Confirms booking via repository
- `_onExpired()` - Auto-cancels at deadline

### BookingResultCubit

**States:** `ResultInitial/Loading/Confirmed/CheckedIn/Expired/Cancelled/History/UpcomingBookings/ResumeToPayment/ResumeToSuccess/ResumeCleared/Failure`

**Methods:**
- `loadById(id)` - Fetches single booking
- `startPolling(id)` - 3-second status polling
- `cancelByPlayer(reason)` - User cancellation
- `loadHistory()` - Past bookings
- `loadUpcomingBookings()` - Future bookings
- `tryRestorePending()` - App resume flow

---

## 4. API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/Cafes/{cafeId}/deposit-config` | Fetch deposit configuration |
| POST | `/api/Bookings` | Create new booking |
| GET | `/api/Bookings/{id}` | Get booking details |
| POST | `/api/Bookings/{id}/confirm` | Confirm payment |
| POST | `/api/Bookings/{id}/cancel` | Cancel booking (with reason) |
| GET | `/api/Bookings/{id}/status` | Polling for status changes |
| GET | `/api/Bookings/history` | Get user's booking history |

---

## 5. Business Logic Flow

### Main Booking Flow (Happy Path)

```
┌─────────────────┐
│ Lobby Full      │ ← From lobby_management
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────────────────┐
│ BookingSummaryPage                                │
│ 1. Load deposit config (getDepositConfig)        │
│ 2. Display breakdown (firstHourPrice, maxDeposit)│
│ 3. Select payment method                        │
│ 4. submit() → createBooking()                  │
└────────┬────────────────────────────────────────┘
         │ Returns bookingId + depositDeadline
         ▼
┌─────────────────────────────────────────────────┐
│ PaymentPage                                      │
│ 1. start() → openGateway()                      │
│ 2. Watch gateway result stream                   │
│ 3. Countdown timer to deadline                   │
│ 4. Gateway returns success                       │
│ 5. confirmBookingPayment(bookingId, paymentRef)   │
└────────┬────────────────────────────────────────┘
         │ Booking now confirmed
         ▼
┌─────────────────────────────────────────────────┐
│ BookingSuccessPage                               │
│ 1. Display QR code (qrPayload)                  │
│ 2. Show countdown to deadline                   │
└─────────────────────────────────────────────────┘
```

### QR Check-in Flow (Task 4)

```
Host displays QR at cafe
Staff scans with POS device
       ↓
Backend validates:
1. Booking exists?
2. Status == confirmed?
3. Nonce not used?
4. Scanner is member of group?
       ↓ Valid
Backend updates:
- status → checkedIn
- nonceUsed → true
- actualCheckinTime → now
```

### App Resume Flow (Kill & Reopen)

```
App starts / returns from background
→ tryRestorePending()
 1. Get pendingBookingId from secure storage
 2. Fetch booking by ID
 3. Check status:
    - pendingDeposit → ResumeToPayment
    - confirmed → ResumeToSuccess
    - terminal → ResumeCleared (clear storage)
```

---

## 6. Business Rules Implemented

| BR | Rule | Implementation |
|----|------|----------------|
| BR-01 | Cafe chooses pricing model | `PricingModel` enum (hourly/flatEntry) |
| BR-02 | Cafe sets deposit config | `DepositConfigEntity` from server |
| BR-03 | Deposit <= 50% first hour | Client: `canAccept()`, Server validates |
| BR-04 | Cafe assigns table | UI shows no table number (QR-based check-in) |
| BR-05 | Seat validation | Server checks available seats |
| BR-06 | Grace period <= 30 min | `depositDeadline` + countdown timer |

---

## 7. Key Technical Decisions

1. **Manual JSON Parsing** - No `json_serializable`, simple structures
2. **Mock Datasource** - In-memory storage for offline-first development
3. **Polling over WebSocket** - Current 3-second polling; ready for WebSocket upgrade
4. **Secure Storage for Resume** - `FlutterSecureStorage` keeps pending booking ID safe
5. **Sealed Payment Results** - `GatewayPending`, `GatewaySuccess`, `GatewayFailed` pattern

---

## 8. Quick Reference

| Task | File/Method |
|------|-------------|
| Add new booking field | `booking_entity.dart` + `booking_model.dart` |
| Add new API endpoint | `booking_remote_datasource_impl.dart` |
| Modify payment flow | `payment_cubit.dart` |
| Change QR display | `booking_qr_card.dart` |
| Modify countdown | `countdown_banner.dart` |
