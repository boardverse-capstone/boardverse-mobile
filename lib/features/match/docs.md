# Match Feature Module

## Overview

Module xử lý việc xác nhận kết quả trận đấu và tính toán Elo rating cho các board games cạnh tranh. Hỗ trợ consensus mechanism để xác nhận kết quả từ nhiều người chơi.

**Tổng số file**: 7 files

---

## 1. Architecture

```
lib/features/match/
├── domain/
│   ├── entities/
│   │   └── match_consensus_entity.dart   # Core match entity
│   └── repositories/
│       └── match_result_repository.dart  # Repository interface
├── data/
│   ├── datasources/
│   │   ├── base/
│   │   │   └── match_result_remote_datasource.dart
│   │   ├── mock/
│   │   │   └── mock_match_result_remote_datasource.dart
│   │   └── remote/
│   │       └── real_match_result_remote_datasource.dart
│   └── match_result_repository_impl.dart
└── presentation/
    └── cubit/
        ├── match_result_cubit.dart
        └── match_result_state.dart
```

---

## 2. Key Classes

### MatchConsensusEntity

```dart
class MatchConsensusEntity {
  final String lobbyId;
  final String gameTemplateId;
  final String gameName;
  final MatchConsensusStatus consensusStatus;  // awaitingSubmissions | conflict | finalized
  final int submittedCount;
  final int requiredCount;
  final List<MatchOutcome> availableOutcomes;  // Win/Loss/Draw options
  final List<MatchSubmission> submissions;
  
  bool get canSubmit;  // false when finalized
}

enum MatchConsensusStatus {
  awaitingSubmissions,
  conflict,
  finalized,
}

enum MatchOutcome {
  win,
  loss,
  draw,
}
```

### MatchSubmissionResultEntity

```dart
class MatchSubmissionResultEntity {
  final String? matchHistoryId;
  final List<EloUpdateEntity> eloUpdates;
  final bool isFinalized;
}
```

### MatchResultCubit

**States:**
| State | Purpose |
|-------|---------|
| `MatchResultInitial` | Initial/reset state |
| `MatchResultLoading` | Loading consensus data |
| `MatchResultLoaded` | Consensus loaded, user can submit |
| `MatchResultFinalized` | Finalized - navigate to Elo display |
| `MatchResultFailure` | Error occurred |

**Methods:**
- `loadMatchResult(lobbyId)` - Fetch consensus for a lobby
- `submitMatchResult(lobbyId, outcome)` - Submit user's outcome
- `reset()` - Reset to initial state

---

## 3. API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/v1/matches/results/lobbies/{lobbyId}` | Fetch consensus state |
| POST | `/api/v1/matches/results` | Submit match result |

**Current Real-Time Strategy:** Polling every 5 seconds via `Stream.periodic()` (placeholder for future SignalR hub)

---

## 4. Business Logic Flow

### Submitting a Match Result

```
User selects outcome (Win/Loss/Draw)
         │
         ▼
MatchResultCubit.submitMatchResult()
         │
         ▼
MatchResultRepository.submitMatchResult()
         │
         ▼
MatchResultRemoteDatasource.submitMatchResult()
         │
         ├── [Mock] ──► Check if finalized ─► Check count ─► Update store ─► Resolve consensus
         │
         └── [Real] ──► POST /api/v1/matches/results ──► Handle response
                          │
                          ▼
                   Update UI based on result
                          │
              ┌────────────┴────────────┐
              │                        │
        isFinalized?              isConflict?
              │                        │
              ▼                        ▼
    MatchResultFinalized     MatchResultLoaded
    (navigate to Elo)       (show conflict msg,
                              allow resubmit)
```

### Consensus Resolution (Mock Logic)

1. When `submittedCount == requiredCount`:
   - **All Draw** → Finalized (Draw)
   - **Exactly 1 Win + rest Loss** → Finalized (Win/Loss)
   - **Anything else** → Conflict (users must resubmit)

### Elo Update (Mock)

When finalized:
- Win → +16 Elo
- Loss → -16 Elo
- Draw → 0 Elo change

---

## 5. Configuration

| Config | Value | Description |
|--------|-------|-------------|
| `AppConfig.useMockMatchData` | `true` | Toggle mock/real datasource |

---

## 6. Quick Reference

| Task | File |
|------|------|
| Modify consensus logic | `match_consensus_entity.dart` |
| Change Elo calculation | `mock_match_result_remote_datasource.dart` |
| Add new state | `match_result_state.dart` |
| Add API endpoint | `real_match_result_remote_datasource.dart` |
