# Friend Management Module Documentation

## Overview

The `friend_management` feature handles all friend-related functionality in the BoardVerse mobile app, including:

- Viewing and managing friends list
- Friend request workflow (send, accept, decline)
- User search and discovery
- Friend profile viewing
- Notes and privacy settings
- User blocking and reporting

## Architecture

The module follows **Clean Architecture** with the **Feature-First** organization pattern, separated into three layers:

```
lib/features/friend_management/
├── data/                  # Data layer
│   ├── datasources/       # Remote data source with mixin-based API grouping
│   ├── models/            # JSON parsing models
│   └── friend_repository_impl.dart
├── domain/                # Domain layer
│   ├── entities/          # Business entities
│   └── repositories/      # Repository interfaces
└── presentation/          # Presentation layer
    ├── cubit/             # State management (Cubit pattern)
    ├── pages/             # Screen compositions
    └── widgets/           # UI components
```

### State Management

Uses **Cubit** (lightweight BLoC) for state management:

- `FriendListCubit`: Manages friends list, requests, search, notes, privacy, reports
- `FriendProfileCubit`: Manages individual profile viewing and actions

### Repository Pattern

Abstract data operations through `FriendRepository` interface, allowing for easy testing and backend swapping.

## Directory Structure & File Responsibilities

### Domain Layer

#### `domain/entities/`

| File | Entity | Responsibility |
|------|--------|----------------|
| `friend_entity.dart` | `FriendEntity` | Represents a friend with activity status, tier, karma |
| `friend_request_entity.dart` | `FriendRequestEntity` | Friend request with requester info and status |
| `friend_profile_entity.dart` | `FriendProfileEntity` | Full profile with relationship status, mutual friends |
| `friend_search_entity.dart` | `FriendSearchEntity` | Search result with basic user info |
| `friend_note_entity.dart` | `FriendNoteEntity` | User notes about friends |
| `friend_privacy_entity.dart` | `FriendPrivacyEntity` | Privacy settings (who can send requests) |
| `friend_report_entity.dart` | `FriendReportEntity` | Report submission data |
| `entities.dart` | - | Barrel file for all entities |

#### `domain/repositories/`

| File | Responsibility |
|------|----------------|
| `friend_repository.dart` | Abstract interface defining all friend operations |

### Data Layer

#### `data/models/`

| File | Model | Responsibility |
|------|-------|----------------|
| `friend_model.dart` | `FriendModel` | Parses friend data from API response |
| `friend_request_model.dart` | `FriendRequestModel` | Parses friend request with multiple schema support |
| `friend_profile_model.dart` | `FriendProfileModel` | Parses profile with relationship and mutual friends |
| `friend_search_model.dart` | `FriendSearchModel` | Parses search results |
| `friend_note_model.dart` | `FriendNoteModel` | Parses note data |
| `friend_privacy_model.dart` | `FriendPrivacyModel` | Parses privacy settings |
| `friend_report_model.dart` | `FriendReportModel` | Parses report data |
| `enum_parsing.dart` | - | Utility for parsing enums and DateTimes |

#### `data/datasources/`

| File | Responsibility |
|------|----------------|
| `base/friend_remote_datasource.dart` | Abstract interface for remote data operations |
| `remote/real_friend_remote_datasource.dart` | Real implementation with API calls |
| `remote/_api_guard_mixin.dart` | Mixin for API response unwrapping |
| `remote/_friend_datasource_friends.dart` | Mixin for friends/requests API calls |
| `remote/_friend_datasource_notes.dart` | Mixin for notes API calls |
| `remote/_friend_datasource_privacy_reports.dart` | Mixin for privacy/reports API calls |

### Presentation Layer

#### `presentation/cubit/`

| File | Type | Responsibility |
|------|------|----------------|
| `friend_list_cubit.dart` | Cubit | Manages friends list, requests, search, notes, privacy, reports |
| `friend_profile_cubit.dart` | Cubit | Manages profile viewing and profile actions |
| `states/friend_list_data.dart` | Data | Common data container for friend list states |
| `states/friend_list_states.dart` | States | Concrete states: Initial, Loading, Loaded, Error, action states |
| `states/friend_profile_states.dart` | States | Profile states: Initial, Loading, Loaded, Error |
| `states/states.dart` | Barrel | Barrel file for all states |

#### `presentation/pages/`

| File | Page | Responsibility |
|------|------|----------------|
| `friends_page.dart` | `FriendsPage` | Main page with 3 tabs: Friends, Requests, Search |
| `friend_profile_page.dart` | `FriendProfilePage` | Profile detail with actions |
| `tabs/friends_list_tab.dart` | `FriendsListTab` | List of accepted friends |
| `tabs/friend_requests_tab.dart` | `FriendRequestsTab` | Received/sent requests |
| `tabs/search_users_tab.dart` | `SearchUsersTab` | User search with debounce |

#### `presentation/widgets/`

##### `widgets/common/` - Reusable generic components

| File | Widget | Responsibility |
|------|--------|----------------|
| `avatar_widgets.dart` | `UserAvatar`, `TieredAvatar` | Avatar display with initials fallback |
| `outlined_card.dart` | `OutlinedCard` | Configurable bordered card |
| `state_widgets.dart` | `EmptyState`, `ErrorRetryView`, `SectionTitle` | Common state display widgets |
| `common.dart` | Barrel | Barrel file |

##### `widgets/shared/` - Feature-specific shared components

| File | Widget | Responsibility |
|------|--------|----------------|
| `meta_row.dart` | `MetaRow` | Karma points + mutual friends row |
| `status_chip.dart` | `StatusChip` | Activity status chip |
| `activity_status_helpers.dart` | `ActivityStatusBadge` | Activity status enum and helpers |
| `time_ago.dart` | `TimeAgo` | Relative time formatting |
| `shared.dart` | Barrel | Barrel file |

##### `widgets/dialogs/` - Dialog functions

| File | Function/Class | Responsibility |
|------|----------------|----------------|
| `friend_dialogs.dart` | `showConfirmDialog`, `showReportDialog`, `showActionSnackBar`, `ReportResult` | Confirmation and report dialogs |
| `dialogs.dart` | Barrel | Barrel file |

##### `widgets/` - Feature-specific widgets

| File | Widget | Responsibility |
|------|--------|----------------|
| `friend_card.dart` | `FriendCard` | Friend list item card |
| `friend_request_card.dart` | `FriendRequestCard` | Request card with accept/decline |
| `user_search_card.dart` | `UserSearchCard` | Search result card |
| `friend_profile_actions.dart` | `FriendProfileActions`, `listenProfileActionMessage` | Profile action buttons |
| `widgets.dart` | Barrel | Barrel file |

## Business Logic Processing

### Friend List Loading (Lazy Tab Loading)

```
FriendsPage → Tab switch → _loadIfNeeded()
  ├─ Tab 0 (Friends):     cubit.loadFriends()
  ├─ Tab 1 (Requests):     cubit.loadReceivedRequests()
  └─ Tab 2 (Search):       cubit.searchUsers(query) [debounced]
```

### Friend Request Workflow

```
1. User A sends request → POST /friends/request
2. User B receives request → GET /friends/requests/received
3. User B accepts/declines → PUT /friends/requests/{id}/accept|reject
4. Both update their lists → GET /friends, GET /friends/requests
```

### Profile Viewing & Actions

```
FriendProfileCubit.loadProfile(userId)
  ├─ GET /friends/{userId}/profile
  ├─ Returns FriendProfileEntity with relationship status
  └─ UI renders actions based on FriendshipStatus:
       ├─ none → "Kết bạn" button
       ├─ pendingSent → "Đã gửi lời mời" notice
       ├─ pendingReceived → Notice to accept in Requests tab
       ├─ accepted → "Mời vào phòng" + unfriend/report menu
       └─ blocked → "Bỏ chặn" button
```

### Search with Debounce

```
SearchUsersTab
  └─ DebounceTimer (300ms)
       └─ cubit.searchUsers(query)
            └─ GET /friends/search?query=...
```

### Privacy Settings

```
FriendPrivacyEntity controls:
  - canReceiveFriendRequests: bool
  → API: GET/PUT /friends/privacy
```

### User Blocking & Reporting

```
Block: POST /friends/{userId}/block → updates local list
Unblock: DELETE /friends/{userId}/block
Report: POST /reports
  └─ showReportDialog() → category + reason (5-1000 chars)
```

## Common Patterns

### Widget Composition

```dart
// Friend card uses shared components
FriendCard → OutlinedCard + UserAvatar + TieredAvatar + MetaRow + StatusChip

// Request card uses shared components
FriendRequestCard → OutlinedCard + UserAvatar + MutualFriendsChip
```

### State Extension Pattern

```dart
// States extend FriendListData for common fields
class FriendListLoaded extends FriendListData {
  // Contains: friends, receivedRequests, sentRequests, notes, etc.
}

// Action states carry metadata
class FriendRequestSent extends FriendListData {
  final String addresseeId;
}
```

### Mixin-based API Grouping

```dart
// RealFriendRemoteDatasource uses mixins for organization
class RealFriendRemoteDatasource
    with ApiGuardMixin,
         FriendDatasourceFriends,
         FriendDatasourceNotes,
         FriendDatasourcePrivacyReports
    implements FriendRemoteDatasource { }
```

## Import Convention

Use barrel files for clean imports:

```dart
// Instead of multiple imports
import '../cubit/cubit.dart';           // FriendListCubit, states
import '../widgets/common/common.dart'; // UserAvatar, OutlinedCard
import '../widgets/shared/shared.dart'; // MetaRow, StatusChip
import '../widgets/dialogs/dialogs.dart'; // showConfirmDialog
```

## Key Enums

| Enum | Values | Usage |
|------|--------|-------|
| `FriendshipStatus` | `none`, `pendingSent`, `pendingReceived`, `accepted`, `blocked` | Profile relationship |
| `ActivityStatus` | `online`, `offline`, `inLobby`, `inGame` | Friend activity |
| `RequestStatus` | `pending`, `accepted`, `declined`, `removed` | Request state |
| `GamerTier` | `bronze`, `silver`, `gold`, `platinum`, `diamond` | User tier (from entity) |

## Error Handling

- API errors wrapped in `ServerFailure` from `dartz` Either
- UI shows `ErrorRetryView` for load failures
- Snackbar notifications for action results
- Optimistic updates with rollback on failure

## Testing

Tests located in `test/features/friend_management/`:

| Test File | Coverage |
|-----------|----------|
| `api_guard_mixin_test.dart` | API envelope unwrapping |
| `friend_profile_cubit_test.dart` | Profile cubit state transitions |
| `friend_profile_model_test.dart` | Profile JSON parsing |
| `friend_request_model_test.dart` | Request JSON parsing (multi-schema) |

Run tests: `flutter test test/features/friend_management/`

## Future Considerations

- Add pagination for friends list
- Implement search filters
- Add friend note search
- Support for friend groups/tags
