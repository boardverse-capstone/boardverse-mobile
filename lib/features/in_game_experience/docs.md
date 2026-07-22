# In-Game Experience Feature Module

## Overview

Module xử lý trải nghiệm trong lúc chơi game tại quán. Bao gồm check-in session, live timer, inventory checking overlay, và session ending notifications.

**Tổng số file**: 10 files

---

## 1. Architecture

```
lib/features/in_game_experience/
├── domain/
│   ├── entities/
│   │   └── in_game_session_entity.dart   # Core session entity
│   └── repositories/
│       └── in_game_repository.dart        # Repository interface
├── data/
│   ├── models/
│   │   └── in_game_session_model.dart   # JSON serialization
│   ├── datasources/
│   │   └── mock_in_game_datasource.dart  # Mock data
│   └── in_game_repository_impl.dart     # Repository implementation
└── presentation/
    ├── cubit/
    │   ├── in_game_cubit.dart
    │   └── in_game_state.dart
    ├── pages/
    │   └── in_game_session_page.dart
    └── widgets/
        ├── play_duration_timer.dart
        ├── inventory_checking_overlay.dart
        └── session_ended_notification_dialog.dart
```

---

## 2. Key Classes

### InGameSessionEntity

```dart
class InGameSessionEntity {
  final String sessionId;
  final String bookingId;
  final String cafeId;
  final String cafeName;
  final String gameId;
  final String gameName;
  final String tableNumber;
  final List<InGamePlayer> players;
  final DateTime startTime;
  final InGameSessionStatus status;
  final Duration playDuration;
  final bool isCheckingInventory;
}

enum InGameSessionStatus {
  active,       // Session is in progress
  checkingOut,  // User requested checkout
  completed,    // Session finished normally
  cancelled,    // Session was cancelled
}

class InGamePlayer {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isPresent;
}
```

### InGameRepository

```dart
abstract class InGameRepository {
  Future<Either<Failure, InGameSessionEntity>> checkIn({required String bookingId});
  Stream<InGameSessionEntity> watchSession(String sessionId);
  Future<Either<Failure, void>> reportMissingComponent(String sessionId, String componentName, int quantity);
  Future<Either<Failure, void>> completeSession(String sessionId);
}
```

### InGameCubit

**State Management Flow:**

```
InGameInitial
    │
    ▼ checkIn(bookingId)
InGameLoading
    │
    ├───[failure]──► InGameFailure
    │
    └───[success]──► InGameSessionActive
                          │
                          ├── requestCheckout() ──► InGameCheckingInventory
                          │
                          ├── endSession() ──► InGameSessionEnded
                          │
                          └── completeCheckout() ──► InGameCheckoutComplete
```

**Methods:**

| Method | Description |
|--------|-------------|
| `checkIn(bookingId)` | Initiates a session, starts timer, begins watching |
| `requestCheckout(sessionId)` | Triggers inventory check, pauses timer |
| `endSession()` | Ends session (mock POS action) |
| `completeCheckout()` | Finalizes payment |
| `loadMockSession()` | Development shortcut |

### InGameState (Sealed Classes)

```
InGameState (sealed base)
├── InGameInitial
├── InGameLoading
├── InGameSessionActive (session, currentDuration)
├── InGameCheckingInventory (session)
├── InGameCheckoutComplete (totalAmount, depositPaid, remainingAmount)
├── InGameSessionEnded (totalDuration, startTime, endTime)
└── InGameFailure (message)
```

---

## 3. Business Logic Flow

```
1. USER CHECKS IN (via QR scan or booking confirmation)
   └─► InGameCubit.checkIn(bookingId)
       └─► Repository.checkIn() fetches session data
           └─► Timer starts, stream watching begins
               └─► UI shows active session with live timer

2. DURING GAME SESSION
   └─► Timer ticks every second, updating duration display
   └─► Session stream provides real-time updates
   └─► User can view player list and session details

3. USER REQUESTS CHECKOUT
   └─► Cubit.requestCheckout() called
       └─► State changes to InGameCheckingInventory
           └─► Timer pauses, overlay appears
           └─► Staff verifies game components

4. STAFF COMPLETES CHECKOUT
   └─► Cubit.completeCheckout() or endSession() triggered
       └─► State changes to InGameCheckoutComplete or InGameSessionEnded
           └─► Navigation to RatingPage

5. POST-SESSION
   └─► User rates teammates and votes for no-shows
       └─► RatingPage handles feedback submission
```

---

## 4. Widgets

### PlayDurationTimer

- Calculates duration from `startTime` to now
- Updates every second when `isRunning = true`
- Displays in HH:MM:SS format

### InventoryCheckingOverlay

- Semi-transparent black background (70% opacity)
- Centered card with circular progress indicator
- Inventory icon and explanatory text

### SessionEndedNotificationDialog

Three action options:
1. **"Đánh giá ngay"** - Navigate to rating page immediately
2. **"Bình chọn no-show"** - Vote for absent players
3. **"Để sau"** - Remind later

---

## 5. External Dependencies

| Feature | Interaction |
|---------|-------------|
| `match_summary_rating` | `RatingPage` - Navigate after session ends |

---

## 6. Quick Reference

| Task | File |
|------|------|
| Modify session flow | `in_game_session_page.dart` |
| Add new state | `in_game_state.dart` |
| Change timer | `play_duration_timer.dart` |
| Modify checkout overlay | `inventory_checking_overlay.dart` |
