# Friend Management — Module Documentation

> Feature quản lý quan hệ bạn bè (Friend List, Friend Request, Friend Note,
> Privacy, Reports) ở role **Player**. Tài liệu này mô tả kiến trúc,
> nghiệp vụ và cách bảo trì — không cần đọc toàn bộ source code trừ khi
> cần fix bug cụ thể.

---

## 1. Tổng quan

| Layer | Mục đích | Folder |
|-------|----------|--------|
| **Domain** | Pure entities + interfaces, không phụ thuộc Flutter/Dio | `domain/entities/`, `domain/repositories/` |
| **Data** | Parse JSON model, gọi API qua Dio, trả về entity | `data/datasources/`, `data/models/`, `data/friend_repository_impl.dart` |
| **Presentation** | UI Widget + Cubit state management | `presentation/cubit/`, `presentation/pages/`, `presentation/widgets/` |

**Đặc điểm kỹ thuật:**
- State management: **Cubit** (không dùng BLoC, đơn giản hơn cho nghiệp vụ CRUD).
- Pattern: **Repository + DataSource abstraction** (định nghĩa trong
  `.agents/docs/mobile_architeture.md`).
- Error handling: trả `Either<Failure, T>` từ Repository/Cubit, UI map failure → message tiếng Việt.
- API base: `lib/core/constants/api_endpoints.dart` (constants) + `lib/core/network/` (Dio client + interceptor).

---

## 2. Sơ đồ thư mục

```
lib/features/friend_management/
├── domain/
│   ├── entities/
│   │   ├── entities.dart                          # Barrel — import 1 lần lấy tất cả
│   │   ├── friend_entity.dart                     # FriendEntity + ActivityStatus + GamerTier
│   │   ├── friend_request_entity.dart             # FriendRequestEntity + FriendRequestStatus
│   │   ├── friend_search_entity.dart              # FriendSuggestionEntity + UserSearchEntity + FriendshipStatus
│   │   ├── friend_note_entity.dart                # FriendNoteEntity
│   │   ├── friend_privacy_entity.dart             # FriendPrivacyEntity
│   │   └── friend_report_entity.dart              # FriendReportEntity + FriendReportCategory
│   └── repositories/
│       └── friend_repository.dart                 # Interface: 17 methods
│
├── data/
│   ├── friend_repository_impl.dart                # Pass-through: delegate to datasource
│   ├── models/
│   │   ├── enum_parsing.dart                      # Helper: parseEnum + parseDateTime + parseStringList
│   │   ├── friend_model.dart                      # FriendModel — alias JSON tap chung
│   │   ├── friend_request_model.dart
│   │   ├── friend_search_model.dart               # FriendSuggestion + UserSearch
│   │   ├── friend_note_model.dart
│   │   ├── friend_privacy_model.dart
│   │   └── friend_report_model.dart
│   └── datasources/
│       ├── base/
│       │   └── friend_remote_datasource.dart       # Abstract interface
│       └── remote/
│           ├── real_friend_remote_datasource.dart  # Compose các mixin (~30 dòng)
│           ├── _api_guard_mixin.dart               # Abstract helper: guardApiCall + mapDioError
│           ├── _friend_datasource_friends.dart     # Friends + requests + search/suggestions
│           ├── _friend_datasource_notes.dart       # Friend notes
│           └── _friend_datasource_privacy_reports.dart # Privacy + reports
│
└── presentation/
    ├── cubit/
    │   ├── friend_list_cubit.dart                  # 17 methods (1 cho mỗi repo method)
    │   └── friend_list_state.dart                  # Initial | Loading | Loaded | Error + 7 event states
    ├── pages/
    │   ├── friends_page.dart                       # Scaffold + TabController + AppBar + UnreadBadge
    │   └── tabs/
    │       ├── friends_list_tab.dart               # Tab "Bạn bè"
    │       ├── friend_requests_tab.dart            # Tab "Lời mời" (kèm SentRequestTile)
    │       └── search_users_tab.dart               # Tab "Tìm kiếm" (kèm debounce + optimistic update)
    └── widgets/
        ├── friend_card.dart                        # Card trong list Friends
        ├── friend_request_card.dart                # Card trong inbox (received)
        ├── user_search_card.dart                   # Card trong tab Search
        └── shared/
            ├── common_widgets.dart                 # UserAvatar, TieredAvatar, OutlinedCard, EmptyState, ErrorRetryView, SectionTitle
            ├── time_ago.dart                       # formatTimeAgo helper
            └── activity_status_helpers.dart        # ActivityStatus → color/label extension
```

**File prefix:**
- `_` prefix (vd `_api_guard_mixin.dart`) = file private theo convention Dart
  (chữ `_` ở đầu identifier = library-private). Tuy nhiên vì import method vẫn
  dùng `import '_foo.dart'` nên đây chỉ là **quy ước đặt tên** trong project,
  không phải access modifier thật.

**Có barrel file** tại `domain/entities/entities.dart` để feature khác
(vd `lobby_management`) chỉ cần `import 'package:boardverse_mobile/features/friend_management/domain/entities/entities.dart'`
lấy được mọi entity.

---

## 3. Domain Layer

### 3.1 Entities

| Entity | Trường quan trọng | Dùng ở |
|--------|-------------------|--------|
| `FriendEntity` | `odId`, `username`, `avatarUrl`, `karmaPoints`, `gamerTier`, `activityStatus`, `isInLobby`, `mutualFriendsCount` | `FriendListTab`, `OnlineFriendsList` (lobby) |
| `FriendRequestEntity` | `requestId`, `requesterId`, `requesterName`, `requesterAvatar`, `status`, `createdAt`, `isRead`, `message` | `FriendRequestsTab` |
| `FriendSuggestionEntity` | `odId`, `username`, `reason`, `mutualFriendsCount` | (chưa có UI) |
| `UserSearchEntity` | `odId`, `username`, `friendshipStatus`, `mutualFriendsCount` | `SearchUsersTab` |
| `FriendNoteEntity` | `noteId`, `friendUserId`, `alias`, `note`, `tags` | (chưa có UI, đã có API) |
| `FriendPrivacyEntity` | `isFriendListPublic`, `acceptFriendRequestsFrom`, `friendLimit` | (chưa có UI) |
| `FriendReportEntity` | `reportId`, `targetUserId`, `category`, `reason`, `status` | (chưa có UI) |

### 3.2 Enums — Map backend

| Enum | FRONTEND | Backend (PascalCase từ .NET) | Ghi chú |
|------|----------|------------------------------|---------|
| `ActivityStatus` | `online`/`recentlyActive`/`away`/`offline` | `Online`/`RecentlyActive`/`Away`/`Offline` | `recentlyActive` chỉ backend alias (lowercase → camelCase) |
| `GamerTier` | `bronze`/`silver`/`gold`/`platinum`/`diamond` | `Bronze`/`Silver`/`Gold`/`Platinum`/`Diamond` | `Plat` → `Platinum` (alias) |
| `FriendRequestStatus` | `pending`/`accepted`/`declined`/`removed`/`expired` | `Pending`/`Accepted`/`Declined`/`Removed`/`Expired` | `Rejected`/`Cancelled` → map `declined`/`removed` |
| `FriendshipStatus` | `none`/`pendingSent`/`pendingReceived`/`accepted`/`blocked` | `null`/`Pending`/`Accepted`/`Blocked` | `Pending` mặc định → `pendingSent` (xem BR-FRIEND-SEARCH-01) |
| `FriendReportCategory` | `spam`/`harassment`/`fakeAccount`/`inappropriateContent`/`other` | `Spam`/`Harassment`/`FakeAccount`/`InappropriateContent`/`Other` | `inappropriate` → `inappropriateContent` |

> **Helper parse enum:** `data/models/enum_parsing.dart` cung cấp
> `parseEnum<T>(values, raw, fallback, aliases)`. Logic: bỏ `_` `-` ` ` rồi
> match theo 3 bước (alias → exact → substring). Dùng cho tất cả enum parse
> từ JSON — KHÔNG được in-line `firstWhere` trong model.

### 3.3 Repository Interface

`friend_repository.dart` định nghĩa 17 method, chia 6 nhóm:

```
// Friends
getFriends, getFriendsWithActivity, getFriendList(otherUserId)

// Friend Requests
getReceivedRequests, getSentRequests,
sendFriendRequest, acceptFriendRequest, declineFriendRequest,
markRequestAsRead

// Friend Actions
unfriend, blockUser, unblockUser

// Search & Suggestions
searchUsers, getSuggestions, getMutualFriends

// Friend Notes
getAllNotes, upsertNote, deleteNote

// Friend Privacy
getPrivacySettings, updatePrivacySettings

// Friend Reports
createReport, getMyReports
```

---

## 4. Data Layer

### 4.1 Models

Mỗi `XEntity` có `XModel` tương ứng với `fromJson` + `toEntity()`. Đặc điểm:

- **Field aliasing:** `FriendModel.fromJson` chấp nhận cả `odId`/`userId`/`id`,
  `avatarUrl`/`avatar`, `username`/`name` — tương thích với nhiều DTO backend.
- **DateTime fallback:** `parseDateTime` trả null khi null/invalid; model dùng
  `DateTime.now()` như last-resort default (vd `FriendRequestModel.expiresAt`).
- **CSN list:** `parseStringList` chấp nhận `List<String>` hoặc CSV string —
  cho `FriendNote.tags`.

### 4.2 Datasource — Mixin Pattern

**Trước refactor:** 1 file `real_friend_remote_datasource.dart` 511 dòng, 21
method, mỗi method lặp try/catch `_mapDioError` ~10 dòng.

**Sau refactor:** 4 file + 1 base class:
- `real_friend_remote_datasource.dart` (~30 dòng) — chỉ compose mixin.
- `_api_guard_mixin.dart` — abstract helper: `guardApiCall<T>`, `unwrapEnvelope`, `parseListEnvelope<T>`, `mapDioError`.
- `_friend_datasource_friends.dart` — 15 method (friends + requests + search).
- `_friend_datasource_notes.dart` — 3 method.
- `_friend_datasource_privacy_reports.dart` — 4 method.

**Cách dùng mixin:**
```dart
class RealFriendRemoteDatasource extends ApiGuardMixin
    with FriendsAndRequestsMixin, FriendNotesMixin, FriendPrivacyAndReportsMixin
    implements FriendRemoteDatasource {
  RealFriendRemoteDatasource({required this.dio});
  @override final Dio dio;
}
```

**Không tự viết** try/catch hoặc `mapDioError` trong mixin method — luôn gọi
`guardApiCall(() async { ... })`. Status code → Failure mapping đã có sẵn:
- 400 → BadRequestFailure
- 401 → UnauthorizedFailure
- 403 → ForbiddenFailure
- 404 → NotFoundFailure
- 409 → ConflictFailure
- 429 → RateLimitFailure
- timeout / no network → NetworkFailure

### 4.3 Repository Implementation

`friend_repository_impl.dart` chỉ là pass-through: mỗi method trong interface
→ delegate thẳng tới datasource. Không có logic mapping. Lý do: layer
repository đã được định nghĩa trong `mobile_architeture.md` là nơi có thể
chèn logic tương lai (cache, fallback, error transform) — giữ đúng pattern.

---

## 5. Presentation Layer

### 5.1 Cubit + State

**File:** `presentation/cubit/friend_list_cubit.dart`, `friend_list_state.dart`.

**State hierarchy:**
```
FriendListState (abstract)
├── FriendListInitial           # Trước khi load lần đầu
├── FriendListLoading           # Loading
├── FriendListLoaded            # Có data: friends + received + sent + unread + notes + privacy + reports
├── FriendListError(message)    # Lỗi chung
├── FriendRequestSent(id)       # Event: vừa gửi request
├── FriendRequestProcessed(id, accepted)  # Event: accept/decline
├── FriendUnfriended(friendId)  # Event: unfriend
├── FriendNoteSaved(note)       # Event: tạo/sửa note
├── FriendNoteDeleted(noteId)   # Event: xóa note
├── FriendPrivacyUpdated(privacy)  # Event: update privacy
└── FriendReportCreated(targetId)  # Event: báo cáo
```

**Cubit methods (17 method, 1-to-1 với repository):**
- Load/refresh: `loadFriends`, `refreshFriends`, `loadPrivacySettings`
- Friend request: `sendFriendRequest`, `acceptFriendRequest`, `declineFriendRequest`, `markRequestAsRead`
- Friend actions: `unfriend`, `blockUser`, `unblockUser`
- Search: `searchUsers` (trả `List<UserSearchEntity>` thay vì `Either` — UI tự xử lý error)
- Notes: `getAllNotes`, `upsertNote`, `deleteNote`
- Privacy: `updatePrivacySettings`
- Reports: `createReport`

**Pattern emit:**
- `Load/Read` → `FriendListLoaded` (hoặc `FriendListError` nếu fail).
- `Mutate` (accept/decline/update) → vẫn emit `FriendListLoaded` với state update
  qua `copyWith`, fallback emit event state riêng nếu `currentState` không phải `FriendListLoaded`.

### 5.2 Pages

**`FriendsPage`** (entry point) — chỉ chứa:
1. `BlocProvider` tạo `FriendListCubit` + `loadFriends()`.
2. `FriendsScaffold` quản lý `TabController` + TabBar + AppBar.
3. `UnreadBadge` (private `_UnreadBadge`) — badge đỏ với số request chưa đọc.

**Mỗi tab sau là `StatelessWidget`/`StatefulWidget` riêng** trong `pages/tabs/`:
- `FriendsListTab` — BlocBuilder render `FriendCard` list.
- `FriendRequestsTab` — BlocBuilder render `FriendRequestCard` (inbox) + `SentRequestTile` (outbox).
- `SearchUsersTab` — `StatefulWidget` quản lý search controller + debounce + optimistic update.

### 5.3 Widgets

**Card widgets** (`FriendCard`, `FriendRequestCard`, `UserSearchCard`):
- Mỗi card là 1 widget độc lập, dùng `OutlinedCard` (shared) làm wrapper.
- Hiển thị avatar qua `UserAvatar` (shared) → fallback chữ cái đầu.
- Action nút ở cuối card drive button state.

**Shared widgets** (`presentation/widgets/shared/`):

| Widget | Mục đích | Thay thế cho |
|--------|----------|--------------|
| `UserAvatar` | Avatar + fallback initials | Lặp CircleAvatar ở 4 chỗ |
| `TieredAvatar` | Avatar có viền theo tier | FriendCard |
| `OutlinedCard` | Material + outlined border + optional onTap | BorderRadius + RoundedRectangleBorder inline |
| `EmptyState` | Icon tròn + title + subtitle | Lặp `_EmptyView` 4 chỗ |
| `ErrorRetryView` | Icon + message + retry button | Lặp `_ErrorView` 4 chỗ |
| `SectionTitle` | Title + count badge | `_SectionTitle` inline |
| `ActivityStatusBadge` | Null-safe wrapper cho `ActivityStatus` color/label | Lặp switch case 3 chỗ |
| `extension FriendStatusPresentation` | `ActivityStatus.color`/`.label` | Switch inline |
| `extension GamerTierPresentation` | `GamerTier.color` | Switch inline |
| `formatTimeAgo(time)` | "X ngày trước" / "X giờ trước" | Lặp `_formatTimeAgo` 2 chỗ |

### 5.4 Search — Optimistic Update

`SearchUsersTab._sendRequest` thực hiện optimistic update:

1. Trước khi gọi API: UI đổi `friendshipStatus` của user → `pendingSent`,
   user thấy nút "Đã gửi" ngay.
2. Gọi `FriendListCubit.sendFriendRequest`.
3. **Success:** Snackbar "Đã gửi lời mời" + refresh search (`_performSearch`).
4. **Error:** Rollback UI về `friendshipStatus` ban đầu + Snackbar đỏ.

Biến `_sendingIds` track user đang trong quá trình gửi để disable nút
(nếu cần mở rộng). Hiện tại UI chỉ dựa vào `friendshipStatus` để đổi trạng thái nút.

---

## 6. Nghiệp vụ chính (Business Rules)

### 6.1 Friend Lifecycle

```
[Gửi]                 [Nhận]
   sender → request → receiver
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
          Accepted     Declined      Expired
              │
              ▼
        [Unfriend] / [Block]
              │
              ▼
        (gỡ khỏi friend list)
```

#### BR-FRIEND-01: Friend List hiển thị user có status = Accepted
- Endpoint: `GET /api/v1/friends/activity` (kèm presence).
- Friends với status `none`/`pendingSent`/`pendingReceived`/`blocked` không xuất hiện.

#### BR-FRIEND-02: Send Friend Request
- Endpoint: `POST /api/v1/friends/requests` body `{addresseeId, message?}`.
- Backend validate: không gửi cho chính mình, không gửi khi đã Accepted, không gửi khi đã Pending ngược chiều.
- 409 Conflict nếu đã có request: hiển thị thông báo từ backend.

#### BR-FRIEND-03: Accept Friend Request
- Endpoint: `POST /api/v1/friends/requests/{id}/accept`.
- Tự động thêm vào friend list đôi bên.
- 404 nếu request không tồn tại hoặc không phải của current user.

#### BR-FRIEND-04: Unfriend
- Endpoint: `DELETE /api/v1/friends/{friendId}`.
- Status chuyển về `none`. Có thể gửi lại request ngay.

#### BR-FRIEND-05: Block
- Endpoint: `POST /api/v1/friends/block/{userId}`.
- Status chuyển về `blocked` (1 chiều). User bị chặn không thấy current user.
- Backend xử lý unblock: `DELETE /api/v1/friends/block/{userId}`.

### 6.2 Search & Suggestions

#### BR-FRIEND-SEARCH-01: Kết quả search có `friendshipStatus`
- Endpoint: `GET /api/v1/friends/search?q=&limit=`.
- Backend trả `friendshipStatus` cho mỗi user trong response.
- Giá trị backend (`null` / `Pending` / `Accepted` / `Blocked`) map sang
  frontend enum (`none` / `pendingSent` / `accepted` / `blocked`).
- Lưu ý: hiện tại backend không phân biệt `pendingSent` vs `pendingReceived`
  → mặc định `Pending` → `pendingSent`. Nếu backend sau này trả `requesterId`,
  sửa parser trong `friend_search_model.dart::_parseFriendshipStatus`.

#### BR-FRIEND-SEARCH-02: Mutual Friend Count
- Mỗi kết quả search kèm `mutualFriendsCount` (số bạn chung với current user).
- Hiển thị icon 🤝 + count ở UserSearchCard.

#### BR-FRIEND-SEARCH-03: Debounce 400ms
- SearchUsersTab debounce 400ms giữa các keystroke, tránh gọi API mỗi lần gõ.
- Cancel debounce cũ khi gõ tiếp.

#### BR-FRIEND-SEARCH-04: Optimistic Update
- Send request → UI đổi nút thành "Đã gửi" ngay.
- API lỗi → rollback UI + Snackbar đỏ.

### 6.3 Friend Note

#### BR-FRIEND-NOTE-01: Mỗi (Owner, Friend) chỉ có 1 note
- Endpoint: `PUT /api/v1/friends/notes/{friendUserId}` body `{alias, note?, tags?}`.
- Backend là upsert: gọi 2 lần với cùng `friendUserId` → cập nhật note.

#### BR-FRIEND-NOTE-02: Tags là CSV
- Backend nhận string `"tag1,tag2,tag3"` (không phải array).
- Model `parseStringList` đã hỗ trợ convert `List<String>` ↔ CSV.

### 6.4 Friend Privacy

#### BR-FRIEND-PRIVACY-01: `acceptFriendRequestsFrom`
- Enum backend: `Everyone` / `FriendsOfFriends`.
- Frontend giữ String thô (chưa enum hóa) — UI tự render dropdown.

#### BR-FRIEND-PRIVACY-02: `friendLimit` max 5000
- 0 = unlimited.
- UI chưa có — `isFriendListPublic` là flag đơn giản.

### 6.5 Friend Reports

#### BR-FRIEND-REPORT-01: Chỉ báo cáo user đang là bạn
- Chưa có UI; backend hiện chấp nhận report mọi user (theo swagger).

#### BR-FRIEND-REPORT-02: Category enum
- `Spam` / `Harassment` / `FakeAccount` / `InappropriateContent` / `Other`.
- Frontend enum: `spam` / `harassment` / `fakeAccount` / `inappropriateContent` / `other`.

#### BR-FRIEND-REPORT-03: Status giữ String
- Backend không public enum cụ thể → `FriendReportEntity.status` là String.
- UI chỉ hiển thị, không branch theo value.

---

## 7. APIMapping

| Endpoint | Method | Repository Method | Note |
|----------|--------|-------------------|------|
| `/api/v1/friends` | GET | `getFriends` | Plain list (không kèm activity) |
| `/api/v1/friends/activity` | GET | `getFriendsWithActivity` | Có `activityStatus` + `lastActiveAt` |
| `/api/v1/friends/{otherUserId}/list` | GET | `getFriendList` | Friend list của user khác |
| `/api/v1/friends/requests/received` | GET | `getReceivedRequests` | Inbox |
| `/api/v1/friends/requests/sent` | GET | `getSentRequests` | Outbox |
| `/api/v1/friends/requests` | POST | `sendFriendRequest` | Body: `{addresseeId, message?}` |
| `/api/v1/friends/requests/{id}/accept` | POST | `acceptFriendRequest` | |
| `/api/v1/friends/requests/{id}/decline` | POST | `declineFriendRequest` | |
| `/api/v1/friends/requests/{id}/read` | POST | `markRequestAsRead` | |
| `/api/v1/friends/{id}` | DELETE | `unfriend` | |
| `/api/v1/friends/block/{userId}` | POST | `blockUser` | |
| `/api/v1/friends/block/{userId}` | DELETE | `unblockUser` | |
| `/api/v1/friends/search` | GET | `searchUsers` | Query: `q`, `limit` |
| `/api/v1/friends/suggestions` | GET | `getSuggestions` | Query: `limit` |
| `/api/v1/friends/{otherUserId}/mutual` | GET | `getMutualFriends` | |
| `/api/v1/friends/notes` | GET | `getAllNotes` | |
| `/api/v1/friends/notes/{friendUserId}` | PUT | `upsertNote` | Body: `{alias, note?, tags?}` |
| `/api/v1/friends/notes/{noteId}` | DELETE | `deleteNote` | |
| `/api/v1/friends/privacy` | GET | `getPrivacySettings` | |
| `/api/v1/friends/privacy` | PUT | `updatePrivacySettings` | Body: từng field optional |
| `/api/v1/friends/reports` | POST | `createReport` | Body: `{targetUserId, category, reason}` |
| `/api/v1/friends/reports` | GET | `getMyReports` | |

> **Response envelope:** Tất cả endpoint trả `{statusCode, message, data: ...}`.
> Datasource có helper `parseListEnvelope` (lấy `data[]`) và `unwrapEnvelope`
> (lấy `data` object).

> **Constants** định nghĩa tại `lib/core/constants/api_endpoints.dart`.

---

## 8. Cấu hình & DI

`lib/core/di/injection.dart`:
```dart
sl.registerLazySingleton<FriendRemoteDatasource>(
  () => RealFriendRemoteDatasource(dio: sl<Dio>()),
);
sl.registerLazySingleton<FriendRepository>(
  () => FriendRepositoryImpl(datasource: sl<FriendRemoteDatasource>()),
);
sl.registerFactory<FriendListCubit>(
  () => FriendListCubit(repository: sl<FriendRepository>()),
);
```

- `RealFriendRemoteDatasource` là singleton (recycle Dio connection).
- `FriendRepositoryImpl` là singleton (stateless).
- `FriendListCubit` là factory (mỗi page instance có thể có state riêng
  — vd Profile có thể mở FriendPage độc lập với HomePage).

---

## 9. Hướng dẫn bảo trì

### 9.1 Thêm endpoint mới

1. **Entity:** Tạo file riêng trong `domain/entities/` (vd `friend_block_entity.dart`).
   Update `entities.dart` barrel export.
2. **Model:** Tạo `friend_block_model.dart` trong `data/models/`. Follow pattern
   `fromJson` + `toEntity` + `parseEnum` nếu có enum.
3. **Repository interface:** Thêm method vào `friend_repository.dart`.
4. **Repository impl:** Pass-through tới datasource.
5. **Datasource:** Thêm method vào 1 trong các mixin (hoặc tạo mixin mới
   nếu concern khác). Nhớ `extends ApiGuardMixin` để dùng `guardApiCall`.
6. **Cubit:** Thêm method tương ứng + emit state phù hợp.
7. **State:** Thêm state class mới nếu cần (event-style hoặc update `FriendListLoaded`).
8. **UI:** Tạo widget mới trong `presentation/widgets/` hoặc tab mới trong `pages/tabs/`.

### 9.2 Thêm enum mới

1. Định nghĩa trong entity file phù hợp.
2. Model parser dùng `parseEnum<T>(values, raw, fallback: defaultValue, aliases: const {...})`.
3. Nếu có UI label/color, viết extension trong `widgets/shared/activity_status_helpers.dart`
   hoặc tạo file mới nếu domain khác.

### 9.3 Thêm shared widget

- Reusable cho >= 2 chỗ → đặt trong `widgets/shared/`.
- Đặt tên theo concern (vd `OutlinedCard`, `UserAvatar`) — không generic quá
  (vd `MyCustomContainer` là tên tệ).

### 9.4 Không nên

- ❌ In-line `try/catch DioException` trong mixin method — dùng `guardApiCall`.
- ❌ In-line `firstWhere` cho enum parse — dùng `parseEnum` helper.
- ❌ Tạo `BorderRadius` + `RoundedRectangleBorder` rải rác — dùng `OutlinedCard`.
- ❌ Hardcode màu/size/radius — dùng `AppColors`/`AppSpacing`/`AppRadius`.
- ❌ Đặt logic nghiệp vụ (vd gọi API) trong Widget — chỉ Cubit được gọi repo.

### 9.5 Lỗi thường gặp

| Lỗi | Nguyên nhân | Fix |
|------|-------------|-----|
| `enum_parsing.dart` không tìm thấy | Import thiếu `.dart` | Check import path |
| Status badge đếm sai | `currentState` không phải `FriendListLoaded` | Thêm fallback `else` emit event state |
| `Material` assertion `borderRadius != null && shape != null` | Dùng cả `borderRadius` + `RoundedRectangleBorder` | Bỏ `borderRadius` ở `Material`, giữ trong shape |
| `Cannot find FriendListCubit` | Quên `BlocProvider` ở root | Check `MultiBlocProvider` ở `main.dart` |
| Optimistic update không rollback | Rollback setState trước khi check `mounted` | Check `if (mounted)` trước `setState` |

---

## 10. Câu hỏi thường gặp

**Q: Tại sao tách entity thành nhiều file?**
A: Mỗi entity là 1 domain concept riêng (Friend ≠ FriendRequest ≠ FriendNote).
Tách file giúp:
- Tìm nhanh: Ctrl+P `friend_request_entity.dart` thay vì scroll 1 file 200 dòng.
- Giảm coupling: lobby chi cần `FriendEntity`, không import `FriendNoteEntity`.
- Dễ test: mỗi entity test độc lập.

**Q: Tại sao dùng mixin cho datasource?**
A: Cohesion cao (mỗi mixin = 1 concern), dễ thêm concern mới (tạo mixin
riêng), dễ test (có thể test 1 mixin không cần construct full class).

**Q: FriendListCubit có 17 method — vi phạm SRP?**
A: Theo SRP, "1 class có 1 lý do để thay đổi". Cubit này chỉ thay đổi khi
nghiệp vụ friend thay đổi → 1 lý do. Tách thành nhiều Cubit (FriendsCubit,
RequestsCubit, NotesCubit) sẽ tăng boilerplate (mỗi cubit cần DI, BlocProvider)
mà lợi ích không rõ ràng. Nếu sau này state FriendListLoaded trở nên phức tạp
(> 30 field), có thể tách.

**Q: Tại sao `searchUsers` trả List<UserSearchEntity> thay vì Either?**
A: Search UI cần error để Snackbar nhưng không cần state Loaded riêng cho
search — vì FriendListLoaded không chứa search results. Trực tiếp từ Cubit
giúp UI đơn giản hơn (không cần FriendListSearchState mới).

**Q: Khi nào nên thêm test cho friend_management?**
A: Hiện tại không có test. Ưu tiên test:
- `parseEnum` (nhiều edge case — `Pending` lowercase, `Pending ` có space, etc.).
- `FriendListCubit` happy path (emit state đúng khi gọi repo).
- `SearchUsersTab` optimistic update (rollback khi API fail).
- `RealFriendRemoteDatasource` với mock Dio (verify URL + body).

---

## 11. Tra cứu nhanh

| Cần sửa | File |
|---------|------|
| Map enum backend khác | `data/models/friend_*_model.dart` (hàm `_parseXxx`) |
| Thêm nghiệp vụ gửi request | `presentation/cubit/friend_list_cubit.dart` + `presentation/pages/tabs/search_users_tab.dart` |
| Đổi UI card | `presentation/widgets/friend_card.dart` (hoặc tương tự) |
| Thêm tab mới | `presentation/pages/friends_page.dart` (TabBar + TabBarView) + tạo file trong `pages/tabs/` |
| Đổi cách unwrap response | `data/datasources/remote/_api_guard_mixin.dart` (parseListEnvelope/unwrapEnvelope) |
| Đổi cách map DioException → Failure | `data/datasources/remote/_api_guard_mixin.dart` (mapDioError) |
| Đổi API endpoint | `lib/core/constants/api_endpoints.dart` (KHÔNG sửa trong friend_management) |
| Đổi theme/UI dùng chung | `presentation/widgets/shared/common_widgets.dart` |

---

**Tài liệu liên quan:**
- `.agents/docs/mobile_architeture.md` — Kiến trúc tổng thể project.
- `.agents/docs/lobby_docs/friend.md` — API docs chi tiết (nếu có).
- `.agents/docs/swagger.json` — OpenAPI spec.
- `lib/core/error/failures.dart` — Failure types.
- `lib/core/constants/api_endpoints.dart` — Endpoint constants.
