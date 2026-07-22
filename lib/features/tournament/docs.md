# Tournament Feature Module

## Overview

Module xử lý giải đấu board game. Bao gồm xem danh sách giải đấu, đăng ký tham gia, xem chi tiết participants và matches, bảng xếp hạng global (ELO), và lịch sử ELO của user.

**Tổng số file**: ~30 files

---

## 1. Architecture

```
lib/features/tournament/
├── domain/
│   ├── entities/
│   │   ├── tournament_entity.dart
│   │   ├── tournament_participant_entity.dart
│   │   ├── tournament_match_entity.dart
│   │   ├── leaderboard_entity.dart
│   │   ├── elo_history_entity.dart
│   │   └── tournament_status.dart
│   └── repositories/
│       └── tournament_repository.dart
├── data/
│   ├── models/
│   │   ├── tournament_model.dart
│   │   ├── participant_model.dart
│   │   ├── match_model.dart
│   │   ├── leaderboard_model.dart
│   │   └── elo_history_model.dart
│   ├── datasources/
│   │   ├── base/
│   │   │   └── tournament_remote_datasource.dart
│   │   └── tournament_remote_datasource_impl.dart
│   └── tournament_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── tournament_list_cubit.dart
    │   ├── tournament_list_state.dart
    │   ├── tournament_detail_cubit.dart
    │   ├── tournament_detail_state.dart
    │   ├── my_registrations_cubit.dart
    │   ├── my_registrations_state.dart
    │   ├── elo_history_cubit.dart
    │   ├── elo_history_state.dart
    │   ├── leaderboard_cubit.dart
    │   └── leaderboard_state.dart
    ├── pages/
    │   ├── tournament_page.dart
    │   ├── tournament_detail_page.dart
    │   ├── match_detail_page.dart
    │   ├── participant_detail_page.dart
    │   ├── leaderboard_page.dart
    │   ├── elo_history_page.dart
    │   ├── my_registrations_page.dart
    │   └── tournament_detail_sheet.dart
    ├── tabs/
    │   ├── tournament_info_tab.dart
    │   ├── tournament_participants_tab.dart
    │   └── tournament_matches_tab.dart
    └── widgets/
        ├── tournament_hero.dart
        ├── tournament_list_card.dart
        ├── tournament_filter_section.dart
        ├── tournament_status_pill.dart
        ├── tournament_action_button.dart
        ├── tournament_detail_header.dart
        ├── tournament_detail_info.dart
        ├── tournament_error_state.dart
        ├── tournament_empty_state.dart
        └── elo_chart.dart
```

---

## 2. Key Classes

### TournamentEntity

**Computed Properties:**
| Property | Description |
|----------|-------------|
| `slotsRemaining` | maxParticipants - currentParticipants |
| `fillRatio` | currentParticipants / maxParticipants |
| `canRegister` | Not registered, open, has slots, deadline not passed |
| `canWithdraw` | Registered and before deadline |
| `canViewBracket` | Tournament has started |
| `isRegistrationDeadlinePassed` | Registration time elapsed |
| `registrationTimeRemaining` | Time until deadline |
| `hasStarted` | Start time passed |
| `timeUntilStart` | Time until start |

### TournamentStatus Enum

```dart
enum TournamentStatus {
  upcoming,
  registrationOpen,
  registrationClosed,
  inProgress,
  completed,
  cancelled,
}
```

### TournamentParticipantEntity

```dart
class TournamentParticipantEntity {
  final String id;
  final String tournamentId;
  final String odify odifyName;
  final String avatarUrl;
  final ParticipantStatus status;
  final int currentElo;
  final int? swissScore;
  final bool isCurrentUserFlag;
}
```

### LeaderboardEntity

```dart
class LeaderboardEntryEntity {
  final int rank;
  final String playerId;
  final String playerName;
  final String avatarUrl;
  final int elo;
  final int wins;
  final int losses;
  final int? rankDelta;  // Change from previous period
  
  double get winRate;
  EloTier get eloTier;  // Bronze, Silver, Gold, Platinum, Diamond
}

enum EloTier {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
}
```

### EloHistoryEntity

```dart
class EloHistoryEntity {
  final String id;
  final String tournamentId;
  final String tournamentName;
  final int eloBefore;
  final int eloAfter;
  final int eloDelta;
  final DateTime playedAt;
  final int? rank;
  final int? totalParticipants;
  
  int get gainedElo;
  int get lostElo;
  String get formattedDelta;  // "+15" or "-12"
}
```

---

## 3. Cubits

### TournamentListCubit

**Methods:**
- `loadTournaments()` - Load all 4 categories (open, upcoming, ongoing, completed)
- `loadTournamentsByGame(gameId)` - Filter by game template
- `refresh()` - Refresh all data

**State Properties:**
- `openTournaments`
- `upcomingTournaments`
- `ongoingTournaments`
- `completedTournaments`

### TournamentDetailCubit

**Methods:**
- `loadDetail(tournamentId)` - Load full tournament details
- `register(tournamentId)` - Register for tournament
- `unregister(tournamentId)` - Withdraw from tournament
- `selectRound(round)` - Filter matches by round
- `refresh()` - Refresh data

**State Properties:**
- `tournament`
- `participants`
- `matches`
- `selectedRound`

### EloHistoryCubit

**Methods:**
- `loadEloHistory()` - Fetch user's Elo progression
- `refresh()` - Refresh data

**State Properties:**
- `history` - List of EloHistoryEntity
- `initialElo` - First tournament Elo
- `currentElo` - Latest Elo
- `totalDelta` - Current - Initial
- `tournamentsPlayed` - Total count

### LeaderboardCubit

**Methods:**
- `loadLeaderboard()` - Fetch global rankings
- `refresh()` - Refresh data

**State Properties:**
- `entries` - List of LeaderboardEntryEntity
- `totalPlayers` - Total ranked players

---

## 4. API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/tournaments/open` | List tournaments open for registration |
| GET | `/tournaments/upcoming` | List upcoming tournaments |
| GET | `/tournaments/{id}` | Tournament details |
| GET | `/tournaments/{id}/participants` | List participants |
| GET | `/tournaments/{id}/participants/{participantId}` | Single participant detail |
| GET | `/tournaments/{id}/matches` | All matches |
| GET | `/tournaments/{id}/matches/round/{round}` | Matches by round |
| GET | `/matches/{matchId}` | Single match detail |
| POST | `/tournaments/{id}/register` | Register for tournament |
| POST | `/tournaments/{id}/unregister` | Withdraw from tournament |
| GET | `/tournaments/my-registrations` | User's registered tournaments |
| GET | `/tournaments/my-elo-history` | User's Elo history |
| GET | `/tournaments/leaderboard` | Global leaderboard |

---

## 5. Business Logic Flow

### Tournament Registration Flow

```
User taps "Register" → TournamentActionButton.onRegister
    ↓
TournamentDetailCubit.register(tournamentId)
    ↓
emit(TournamentDetailRegistering) → Show loading state
    ↓
repository.register(id) → POST /tournaments/{id}/register
    ↓
On Success: emit(TournamentDetailActionSuccess) → Show snackbar
           → reload detail to sync UI
On Failure: emit(TournamentDetailError) → Show error snackbar
```

### Tournament List Flow

```
TournamentPage loads → TournamentListCubit.loadTournaments()
    ↓
Parallel API calls:
    ├── getOpenTournaments() → Filter: registrationOpen, deadline not passed
    ├── getUpcomingTournaments() → Filter: upcoming OR deadline passed
    ├── getMyRegistrations(status='OnGoing') → User's ongoing tournaments
    └── getMyRegistrations(status='Completed') → User's completed tournaments
    ↓
emit(TournamentListLoaded) with all 4 categories
    ↓
FilterSection allows switching between categories
```

### Elo History Flow

```
EloHistoryPage loads → EloHistoryCubit.loadEloHistory()
    ↓
repository.getMyEloHistory() → GET /tournaments/my-elo-history
    ↓
Sort by playedAt ascending (left → right for chart)
    ↓
Calculate: initialElo, currentElo, totalDelta
    ↓
emit(EloHistoryLoaded) → Display summary + chart + list
```

---

## 6. Navigation

All tournament-related navigation goes through `TournamentRoutes` (from `core/navigation/tournament_routes.dart`):

```dart
TournamentRoutes.openTournamentDetail(context, tournamentId);
TournamentRoutes.openParticipantDetail(context, tournamentId, participantId);
TournamentRoutes.openMatchDetail(context, matchId);
TournamentRoutes.openMyRegistrations(context);
TournamentRoutes.openEloHistory(context);
TournamentRoutes.openLeaderboard(context);
```

---

## 7. Quick Reference

| Task | File |
|------|------|
| Add new tournament field | `tournament_entity.dart` + `tournament_model.dart` |
| Add new API endpoint | `tournament_remote_datasource_impl.dart` |
| Modify tournament list | `tournament_page.dart` |
| Add new state | `tournament_list_state.dart` |
| Change ELO chart | `elo_chart.dart` |
| Modify leaderboard | `leaderboard_page.dart` |
