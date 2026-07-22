# Lobby Management Feature Module

## Overview

Module xử lý online waiting room cho việc ghép nhóm chơi board game. Bao gồm tạo lobby, tham gia lobby, realtime updates qua SignalR, karma-based filtering, và booking integration.

**Tổng số file**: ~25 files

---

## 1. Architecture

```
lib/features/lobby_management/
├── domain/
│   ├── entities/
│   │   ├── lobby_entity.dart          # Core LobbyEntity + LobbyPlayer
│   │   ├── lobby_summary.dart        # Lightweight version for lists
│   │   └── friend_entity.dart        # Online friends
│   └── repositories/
│       └── lobby_repository.dart     # Repository interface
├── data/
│   ├── models/
│   │   ├── lobby_model.dart
│   │   └── friend_model.dart
│   ├── datasources/
│   │   ├── base/
│   │   │   └── lobby_remote_datasource.dart
│   │   ├── remote/
│   │   │   └── real_lobby_remote_datasource.dart
│   │   └── mock/
│   │       └── mock_lobby_remote_datasource.dart
│   ├── realtime/
│   │   ├── lobby_realtime_service.dart     # Abstract + event types
│   │   ├── real_lobby_realtime_service.dart  # SignalR implementation
│   │   └── mock_lobby_realtime_service.dart  # Timer simulation
│   ├── lobby_repository_impl.dart
│   └── lobby_persistence_service.dart  # SecureStorage persistence
└── presentation/
    ├── cubit/
    │   ├── lobby_cubit.dart          # Main state management
    │   ├── lobby_state.dart          # Sealed state classes
    │   └── lobby_search_cubit.dart   # Nearby lobby search
    ├── pages/
    │   ├── lobby_page.dart           # Main lobby room
    │   ├── nearby_lobbies_page.dart  # Lobby discovery
    │   └── play_mode_selection_page.dart
    └── widgets/
        ├── lobby_player_card.dart
        ├── lobby_countdown_timer.dart
        └── online_friends_list.dart
```

---

## 2. Key Classes

### LobbyEntity

**LobbyStatus Enum:**

| Status | Meaning |
|--------|---------|
| `open` | Actively recruiting players (BR-08 timer running) |
| `full` | Reached max capacity, auto-creating booking (Luong A) |
| `inProgress` | Group has checked in at the cafe |
| `closed` | Session ended, karma rating allowed |
| `timeoutFailed` | BR-08 lead-time elapsed without reaching minPlayers |
| `hostCancelled` | Host voluntarily dissolved an open lobby |

**Key Fields:**
- `id`, `gameId`, `gameName`, `cafeId`, `cafeName`
- `hostId`, `hostName`
- `scheduledTime` - Actual appointment time
- `timeoutAt = scheduledTime - leadTimeMinutes` - BR-08 deadline
- `currentPlayers`, `maxPlayers`, `minPlayers`
- `players: List<LobbyPlayer>`
- `inviteCode` - Shareable code for private lobbies
- `bookingId` - Link to BR-07 booking
- `minimumKarma` - BR-10 karma threshold
- `searchRadiusKm` - BR-08 search radius

### LobbyPlayer

| Field | Type | Purpose |
|-------|------|---------|
| `id` | String | Player's user ID |
| `name` | String | Display name |
| `avatarUrl` | String | Profile picture |
| `isHost` | bool | True for lobby creator |
| `isReady` | bool | Ready-to-play flag |
| `joinedAt` | DateTime | When they joined |
| `karma` | double | BR-10 reputation score |

### LobbyCubit

**Methods:**

| Method | Description |
|--------|-------------|
| `createLobby(...)` | Creates lobby (Luong A), starts countdown, watches realtime |
| `createLobbyFromBooking(...)` | Creates lobby tied to existing booking (Luong B) |
| `joinLobby(String, String?)` | Joins existing lobby |
| `leaveLobby(String)` | Leaves lobby, cancels subscriptions |
| `inviteFriend(String, String)` | Sends invite notification to friend |
| `closeLobby(String)` | Host manually closes lobby |
| `lockLobby(String)` | Host locks lobby → triggers auto-booking |
| `openKarmaWindow(String)` | Host opens karma rating window |
| `loadOnlineFriends()` | Fetches friend list |
| `searchNearbyLobbies(...)` | BR-10 filtered search |
| `restoreActiveLobby()` | Restore persisted lobby on app restart |

### LobbyState (Sealed Classes)

```
LobbyState (sealed base)
|-- LobbyInitial            # No active lobby
|-- LobbyLoading            # Async operation in progress
|-- LobbyCreated            # Lobby successfully created/joined
|-- LobbyUpdatedRealtime    # Realtime update received
|-- LobbyDismissed          # Lobby ended (timeout/cancelled/closed)
|-- LobbyReady              # All players ready → proceed to booking
|-- LobbyFriendsLoaded      # Online friends fetched
|-- LobbyFailure            # Error occurred
|-- LobbyListLoaded        # Nearby lobbies search results
|-- LobbyAutoBookingCreated # Lobby full → booking created
```

### LobbyRealtimeEvent (Sealed Classes)

| Event | Payload | Triggered By |
|-------|---------|--------------|
| `MemberJoinedEvent` | `lobbyId`, `member`, `timestamp` | Player joins |
| `MemberLeftEvent` | `lobbyId`, `memberId`, `timestamp` | Player leaves |
| `LobbyFullEvent` | `lobbyId`, `message`, `timestamp` | Reaches maxPlayers |
| `LobbyCancelledEvent` | `lobbyId`, `reason`, `timestamp` | Host cancels |
| `LobbyTimeoutEvent` | `lobbyId`, `message`, `timestamp` | BR-08 deadline exceeded |
| `BookingConfirmedEvent` | `lobbyId`, `bookingId`, `message`, `timestamp` | BR-05 booking confirmed |

---

## 3. API Endpoints

| Operation | Method | Path | Key BR |
|-----------|--------|------|--------|
| Create lobby | POST | `/api/v1/lobbies` | BR-07/BR-08 |
| Get lobby | GET | `/api/v1/lobbies/{id}` | - |
| Search lobbies | POST | `/api/v1/lobbies/search` | BR-10 |
| Join lobby | POST | `/api/v1/lobbies/{id}/join` | BR-07/BR-10 |
| Leave lobby | POST | `/api/v1/lobbies/{id}/leave` | - |
| Invite friend | POST | `/api/v1/lobbies/{id}` | - |
| Close lobby | POST | `/api/v1/lobbies/{id}/close` | BR-07 |
| Lock lobby | POST | `/api/v1/lobbies/{id}/lock` | BR-07 (Open→Full) |
| Open karma | POST | `/api/v1/lobbies/{id}/open-karma-window` | BR-05 |
| SignalR Hub | WebSocket | `/hubs/lobby` | BR-07/08/10 |

---

## 4. Business Logic Flow

### Create Lobby (Luong A - Flow A)

```
User selects game/cafe
    → LobbyCubit.createLobby()
        → LobbyRepository.createLobby()
            → LobbyRemoteDatasource.createLobby()
                → POST /api/v1/lobbies
        → _startCountdown(timeoutAt)
        → _watchLobbyRealtime(lobbyId)
        → _watchLobbyEvents(lobbyId)
        → _persistLobby(lobby)
        → emit LobbyCreated(lobby)
```

### Join Lobby + Realtime Update

```
User joins lobby
    → LobbyCubit.joinLobby()
        → POST /api/v1/lobbies/{id}/join
        → GET /api/v1/lobbies/{id}
        → subscribe SignalR group
    → Another user joins (SignalR)
        → LobbyRealtimeService emits MemberJoinedEvent
            → Repository.watchLobbyRealtime() fetches updated lobby
                → LobbyCubit._onLobbyUpdate()
                    → if full && no bookingId → _triggerAutoBooking()
                    → else → emit LobbyUpdatedRealtime(lobby)
```

### Lobby Auto-Booking (Luong A)

```
Member count reaches maxPlayers
    → SignalR broadcasts LobbyFullEvent
        → LobbyCubit._watchLobbyEvents() receives it
            → _triggerAutoBooking(lobby)
                → emit LobbyUpdatedRealtime(lobby)
                → repository.autoCreateBookingWhenFull(lobbyId)
                → emit LobbyAutoBookingCreated(lobby, bookingId)
    → LobbyPage listener
        → show SnackBar
        → navigate to BookingSummaryPage with autoBookingId
```

---

## 5. Business Rules Implemented

| BR | Rule | Implementation |
|----|------|----------------|
| BR-05 | Karma rating window opens after POS payment | `openKarmaWindow()` / `BookingConfirmedEvent` |
| BR-07 | Booking-linked lobbies (Luong B) + auto-booking (Luong A) | `lockLobby()` và `LobbyFullEvent` trigger `_triggerAutoBooking()` |
| BR-08 | Lead-time timeout for recruiting | `timeoutAt = scheduledTime - leadTimeMinutes`; countdown timer |
| BR-10 | Karma-based lobby filtering | `minimumKarma` field; `searchNearbyLobbies()` filters by karma |

---

## 6. Dependency Injection / Mode Switching

| Component | Mock Mode | Real Mode |
|-----------|-----------|-----------|
| `LobbyRemoteDatasource` | `MockLobbyRemoteDatasource` | `RealLobbyRemoteDatasource` |
| `LobbyRealtimeService` | `MockLobbyRealtimeService` (Timer) | `RealLobbyRealtimeService` (SignalR) |

---

## 7. Mock Data (Development)

Pre-seeded lobbies:
- `lobby_001` - Avalon với 5 players (realtime testing)
- 8 seed lobbies: Catan, Wingspan, Splendor, Gloomhaven, Azul, Codenames, Dixit, Terraforming Mars

Mock online friends: 5 friends (3 online, 1 in lobby, 1 offline)

---

## 8. Quick Reference

| Task | File/Method |
|------|-------------|
| Add new lobby field | `lobby_entity.dart` + `lobby_model.dart` |
| Add new API endpoint | `real_lobby_remote_datasource.dart` |
| Add new realtime event | `lobby_realtime_service.dart` |
| Modify lobby UI | `lobby_page.dart` |
| Change countdown timer | `lobby_countdown_timer.dart` |
