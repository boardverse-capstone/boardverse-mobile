# Matchmaking Discovery Feature Module

## Overview

Module xử lý việc khám phá board games và tìm kiếm cafes gần đó để chơi. Bao gồm tìm kiếm, lọc theo category/player count, xem chi tiết game, và tạo lobby hoặc đặt chỗ.

**Tổng số file**: 39 files

---

## 1. Architecture

```
lib/features/matchmaking_discovery/
├── domain/
│   ├── entities/
│   │   ├── board_game_entity.dart
│   │   ├── board_game_detail_entity.dart
│   │   ├── cafe_entity.dart
│   │   ├── game_category_entity.dart
│   │   ├── game_component_entity.dart
│   │   ├── search_filter_entity.dart
│   │   ├── seat_availability_entity.dart
│   │   ├── game_play_configuration_entity.dart
│   │   ├── game_play_navigation_entity.dart
│   │   ├── nearby_cafes_search_result_entity.dart
│   │   └── alternative_game_suggestion_entity.dart
│   └── repositories/
│       └── matchmaking_repository.dart
├── data/
│   ├── models/
│   │   ├── board_game_model.dart
│   │   ├── board_game_detail_model.dart
│   │   ├── cafe_model.dart
│   │   ├── game_category_model.dart
│   │   ├── game_component_model.dart
│   │   ├── seat_availability_model.dart
│   │   ├── game_play_configuration_model.dart
│   │   ├── game_play_navigation_model.dart
│   │   ├── nearby_cafes_search_result_model.dart
│   │   └── alternative_game_suggestion_model.dart
│   ├── datasources/
│   │   ├── base/
│   │   │   └── matchmaking_datasource.dart
│   │   └── remote/
│   │       └── matchmaking_remote_datasource_impl.dart
│   └── matchmaking_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── matchmaking_cubit.dart
    │   └── matchmaking_state.dart
    ├── pages/
    │   ├── search_page.dart
    │   ├── board_game_detail_page.dart
    │   └── lobby_config_page.dart
    └── widgets/
        ├── board_game_card.dart
        ├── cafe_card.dart
        ├── game_detail_header.dart
        ├── game_filter_chips.dart
        ├── game_search_bar.dart
        ├── gps_warning_banner.dart
        ├── seat_availability_indicator.dart
        ├── similar_games_carousel.dart
        └── booking_button.dart
```

---

## 2. Key Classes

### MatchmakingCubit

**Methods:**

| Method | Purpose |
|--------|---------|
| `searchGames()` | Search với basic filters |
| `searchWithFilter()` | Search với SearchFilterEntity |
| `searchWithFilterPaged()` | Paginated search |
| `loadCategories()` | Load game categories |
| `loadGameDetail()` | Load game + nearby cafes |
| `loadCafesWithManualLocation()` | Load cafes khi GPS disabled |
| `enableGpsAndReload()` | Re-enable GPS and reload |
| `checkSeatAvailability()` | Check nếu cafe có đủ seats (BR-05) |
| `loadSeatAvailability()` | Get detailed seat info |
| `createLobby()` | Create a lobby via LobbyRepository |
| `loadGamePlayConfiguration()` | Get solo/group support config |
| `resolvePlayNavigation()` | Determine navigation target |
| `loadNearbyCafesForCurrentUser()` | Using saved user location |
| `loadNearbyCafesWithCoordinates()` | Using provided GPS coordinates |

### MatchmakingState (Sealed Classes)

| State | Purpose |
|-------|---------|
| `MatchmakingInitial` | Starting state |
| `MatchmakingLoading` | Loading indicator |
| `MatchmakingSearchResults` | Search results with games list |
| `MatchmakingGameDetail` | Game detail with nearby cafes |
| `MatchmakingCafeList` | Cafe list khi GPS disabled |
| `MatchmakingGpsDisabled` | GPS warning state |
| `MatchmakingOutOfRadius` | No cafes trong 15km radius |
| `SeatChecking` | Checking seat availability |
| `SeatCheckSuccess/Failure` | Seat check results |
| `MatchmakingFailure` | Error state |

### Enums

```dart
enum PlayMode {
  solo,   // playMode = 0 (only if minPlayers == 1)
  group,  // playMode = 1 (default)
}

enum NavigationTarget {
  lobbyCreation,  // Go to LobbyConfigPage
  soloBooking,    // Go to BookingSummaryPage
}

enum CafeSeatStatus {
  available, // > 20% seats free
  limited,  // <= 20% seats free
  full,     // 0 seats available
}
```

---

## 3. API Endpoints

### Board Games

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/board-games` | List games (paginated) |
| GET | `/api/v1/board-games/{id}` | Game details |
| GET | `/api/v1/board-games/categories` | Game categories |
| GET | `/api/v1/board-games/{id}/play-configuration` | Solo/group support |
| POST | `/api/v1/board-games/{id}/play-navigation` | Navigate to solo/lobby |

### Cafes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cafes/nearby` | Nearby cafes với game filter |
| GET | `/api/cafes/nearby/me` | Nearby cafes (user's saved location) |
| GET | `/api/cafes/{id}` | Cafe details |

### Query Parameters

```
/api/v1/board-games?
  search=<string>
  category_ids=<csv>
  player_count=<int>
  duration_range=<csv>
  pageNumber=<int>
  pageSize=<int>

/api/cafes/nearby?
  gameTemplateId=<string>
  latitude=<double>
  longitude=<double>
  radiusKm=<double>
  pageNumber=<int>
  pageSize=<int>
```

---

## 4. Business Logic Flow

### Search & Discover Games

```
User → SearchPage → MatchmakingCubit.searchGames()
                    ↓
              MatchmakingRepository.searchBoardGames()
                    ↓
              MatchmakingDatasource.getBoardGamesPaged()
                    ↓
              API Response → Model → Entity
                    ↓
              MatchmakingSearchResults state
                    ↓
              UI: BoardGameCard list
```

### View Game Details + Nearby Cafes

```
User taps game → BoardGameDetailPage
                  ↓
        MatchmakingCubit.loadGameDetail(gameId)
                  ↓
        Parallel calls:
        ├── getBoardGameDetails(id)
        └── getNearbyCafesWithGame(id, lat, lng)
                  ↓
        Filter cafes: only those with game in availableGameIds
                  ↓
        Check if within 15km radius
                  ↓
        If out of radius → MatchmakingOutOfRadius
        If GPS disabled → MatchmakingGpsDisabled
        Otherwise → MatchmakingGameDetail
                  ↓
        UI: GameDetailHeader + Components + CafeCard list
```

### Play Mode Navigation

```
User selects "Chơi một mình" or "Chơi cùng nhóm"
        ↓
MatchmakingCubit.resolvePlayNavigation(gameId, PlayMode)
        ↓
POST /api/v1/board-games/{id}/play-navigation
        ↓
NavigationTarget determined:
├── LobbyCreation → LobbyConfigPage → LobbyPage
└── SoloBooking → BookingSummaryPage
```

### Lobby Creation (BR-08, BR-10)

```
User in LobbyConfigPage configures:
├── Date/Time selection
├── Public/Private toggle
├── Additional slots (slider: 0 to maxPlayers-1)
├── Minimum Karma (BR-10): 0-100 slider
├── Search Radius (BR-08): 1-30km slider
└── Lead time: 20 minutes (from deposit config)
        ↓
Tap "Tạo phòng" → MatchmakingCubit.createLobby()
        ↓
LobbyRepository.createLobby(...)
        ↓
Navigate to LobbyPage with lobbyId
```

---

## 5. Business Rules Implemented

| BR | Description | Implementation |
|----|-------------|----------------|
| BR-01 | Seat-based cafe management | `CafeEntity`, `SeatAvailabilityEntity` |
| BR-03 | Wait time for unavailable games | `estimatedWaitMinutes` in `CafeEntity` |
| BR-05 | Seat availability check before booking | `checkSeatAvailability()` in Cubit |
| BR-06 | Deposit holding (max 30 min) | `depositMinutesLimit` (default 20 min) |
| BR-08 | Search radius for lobby | `searchRadiusKm` slider (1-30km) |
| BR-10 | Karma-based member filtering | `minimumKarma` slider (0-100) |

---

## 6. External Dependencies

| Feature | Interaction |
|---------|-------------|
| `lobby_management` | `LobbyRepository` - used for `createLobby()` |
| `booking_payment` | `BookingSummaryPage` - solo booking navigation |
| `core/di` | `getIt<LobbyCubit>()` for dependency injection |

---

## 7. Quick Reference

| Task | File/Method |
|------|-------------|
| Add new game field | `board_game_entity.dart` + `board_game_model.dart` |
| Add new cafe field | `cafe_entity.dart` + `cafe_model.dart` |
| Add new search filter | `search_filter_entity.dart` + `matchmaking_cubit.dart` |
| Modify seat display | `seat_availability_indicator.dart` |
| Change lobby config | `lobby_config_page.dart` |
