# Match Summary Rating Feature Module

## Overview

Module xử lý việc đánh giá sau trận đấu. Bao gồm 4 bước: đánh giá karma teammates bằng tags, chọn kết quả trận đấu (Win/Loss/Draw), hiển thị thay đổi ELO, và voting cho no-show players.

**Tổng số file**: 14 files

---

## 1. Architecture

```
lib/features/match_summary_rating/
├── domain/
│   ├── entities/
│   │   ├── rating_entity.dart         # Rating, KarmaTag, EloResult
│   │   └── voting_session.dart        # VotingSession, VoteType
│   └── repositories/
│       └── rating_repository.dart      # Repository interface
├── data/
│   ├── models/
│   │   └── rating_model.dart         # KarmaTagModel, EloResultModel
│   ├── datasources/
│   │   └── mock_rating_datasource.dart
│   └── rating_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── rating_cubit.dart
    │   ├── rating_state.dart
    │   └── voting_state.dart
    ├── pages/
    │   └── rating_page.dart
    └── widgets/
        ├── player_rating_card.dart
        ├── elo_result_display.dart
        ├── voting_card.dart
        └── voting_result_dialog.dart
```

---

## 2. Key Classes

### RatingCubit

**Methods:**

| Method | Description |
|--------|-------------|
| `startRatingFlow(sessionId)` | Initializes flow, fetches karma tags |
| `toggleKarmaTag(playerId, tagId)` | Toggles tag selection for a player |
| `submitKarmaRatings()` | Submits ratings, transitions to MatchResultEntry |
| `submitMatchResult(result)` | Submits win/lose/draw, fetches ELO result |
| `skipMatchResult()` | Skips competitive rating |
| `checkPendingVotes()` | Checks if no-show candidates exist |
| `startVoting(target)` | Creates VotingSession with deadline timer |
| `submitVote(vote)` | Records vote, checks if all voted or expired |
| `completeVoting()` | Resets voting state to VotingComplete |

**Internal State:**
- `_votingState` - Manages voting sub-flow independently
- `_votingTimer` - Countdown timer for voting deadline
- `_mockCandidates` - List of eligible voters
- `_mockNoShowCandidates` - Players flagged as potentially no-show

### RatingState (Sealed Classes)

```
RatingState (abstract)
├── RatingInitial        - Initial state before flow starts
├── RatingLoading        - Loading indicator during async operations
├── KarmaRating          - Step 1: User rates teammates with karma tags
├── MatchResultEntry     - Step 2: User selects win/lose/draw
├── EloResultDisplay     - Step 3: Shows ELO change result
├── RatingComplete       - Final state after all steps done
└── RatingFailure       - Error state with message
```

### VotingState (Sealed Classes)

```
VotingState (abstract)
├── VotingInitial       - No voting in progress
├── VotingLoading       - Loading voting data
├── VotingPending       - Has candidates to vote on
├── VotingActive        - Active voting session with countdown
├── VotingResult        - Voting concluded, shows outcome
├── VotingComplete      - Voting process finished
└── VotingFailure      - Voting error
```

### Domain Entities

```dart
// Karma Tags
class KarmaTag extends Equatable {
  final String id;
  final String name;        // e.g., "Đúng giờ", "Toxic"
  final String icon;       // e.g., "check_circle", "mood_bad"
  final bool isPositive;   // true = green, false = red styling
}

// Elo Result
class EloResult extends Equatable {
  final String sessionId;
  final MatchResult result;  // win, lose, draw
  final int eloChange;       // +15, -12, 0
  final int currentElo;
  final int newElo;
}

// Voting Session
class VotingSession extends Equatable {
  final String id;
  final String sessionId;
  final String targetPlayerId;
  final String targetPlayerName;
  final List<String> eligibleVoters;
  final int threshold;  // floor(n/2)+1
  final Map<String, VoteType> votes;
  
  bool get isNoShowConfirmed;  // noShowVotes >= threshold
}

// Vote Types
enum VoteType {
  noShow,       // "Vắng mặt"
  notNoShow,    // "Có đến"
  skip,         // "Bỏ qua"
}
```

---

## 3. Business Logic Flow

### Main Rating Flow (4 Steps)

```
┌─────────────────────────────────────────────────────────────┐
│ [1. KARMA RATING]                                          │
│       │                                                      │
│       ├─── User sees list of players to rate                │
│       ├─── Each player has selectable karma tags              │
│       │     • Positive: Đúng giờ, Văn minh, Thân thiện     │
│       │     • Negative: Toxic, No-show, Trễ giờ, Gian lận  │
│       └─── On "Tiếp tục" ─► submitKarmaRatings()        │
│                           │                                  │
│                           ▼                                  │
│ [2. MATCH RESULT]                                          │
│       │                                                      │
│       ├─── User selects: Win / Lose / Draw                   │
│       └─── On selection ─► submitMatchResult()              │
│                           │                                  │
│                           ▼                                  │
│ [3. ELO RESULT]                                            │
│       │                                                      │
│       ├─── Shows: Current ELO ─► New ELO                    │
│       └─── On "Hoàn tất" ─► checkPendingVotes()          │
│                           │                                  │
│           ┌───────────────┴───────────────┐                   │
│           ▼                               ▼                   │
│ [4a. VOTING] (if pending)     [4b. COMPLETE] (if no pending)│
│           │                               │                   │
│           └─── Thank you screen ◄─────────┘                   │
│                       │                                      │
│           ┌───────────┴───────────┐                          │
│           ▼                       ▼                          │
│ [FINAL COMPLETE]           [VOTING]                         │
└─────────────────────────────────────────────────────────────┘
```

### Voting Sub-Flow

```
THRESHOLD CALCULATION:
┌───────────────────────────────────────────────────────────────┐
│  threshold = floor(checkedInCount / 2) + 1                   │
│                                                               │
│  Example: 4 eligible voters                                   │
│  threshold = floor(4/2) + 1 = 3                              │
│  Need 3 "NoShow" votes to confirm no-show status             │
└───────────────────────────────────────────────────────────────┘
```

---

## 4. Karma Tags (Mock Data)

**Positive Tags (Green):**
| Icon | Name | Description |
|------|------|-------------|
| `check_circle` | Đúng giờ | On time |
| `thumb_up` | Văn minh | Civilized |
| `emoji_emotions` | Thân thiện | Friendly |
| `stars` | Chơi hay | Good player |

**Negative Tags (Red):**
| Icon | Name | Description |
|------|------|-------------|
| `mood_bad` | Toxic | Bad behavior |
| `event_busy` | No-show | Did not show up |
| `schedule` | Trễ giờ | Late |
| `gavel` | Gian lận | Cheating |

---

## 5. File Interactions

```
rating_page.dart (Entry Point)
    │
    ├───┬──> BlocBuilder<RatingCubit, RatingState>
    │   │
    │   ├── [KarmaRating] ───────────────> player_rating_card.dart
    │   │
    │   ├── [MatchResultEntry] ──────────> _ResultChoiceCard
    │   │
    │   ├── [EloResultDisplay] ──────────> elo_result_display.dart
    │   │
    │   └── [RatingComplete + step=3] ──> voting_card.dart
    │
    └─── Uses RatingCubit methods:
          ├── startRatingFlow()
          ├── toggleKarmaTag()
          ├── submitKarmaRatings()
          ├── submitMatchResult()
          └── checkPendingVotes()

rating_cubit.dart
    │
    ├────> rating_state.dart (RatingState hierarchy)
    ├────> voting_state.dart (VotingState hierarchy)
    └────> rating_repository.dart (interface)
```

---

## 6. Quick Reference

| Task | File |
|------|------|
| Add new karma tag | `rating_entity.dart` + `mock_rating_datasource.dart` |
| Modify rating flow | `rating_page.dart` |
| Add new state | `rating_state.dart` |
| Change voting logic | `voting_session.dart` |
| Modify ELO display | `elo_result_display.dart` |
