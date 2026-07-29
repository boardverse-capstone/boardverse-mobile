# Profile Feature Module

Module quản lý **hồ sơ người dùng** (profile) cho app BoardVerse:
- Thông tin cá nhân (bio, tên, ngày sinh, SĐT)
- Avatar (upload qua Cloudinary)
- Karma score, ELO rating, Level, Gamer Tier
- Vị trí GPS/Manual (last known location)
- Soft-delete profile

## 1. Architecture

```
lib/features/profile/
├── domain/                          # Pure business rules (no Flutter / Dio)
│   ├── entities/
│   │   ├── profile_entity.dart      # ProfileEntity (read model domain)
│   │   ├── karma_history_entity.dart
│   │   └── player_location_entity.dart
│   └── repositories/
│       └── profile_repository.dart  # Abstract repo (interface)
│
├── data/                            # Talks to the backend
│   ├── models/                      # Freezed JSON ⇄ entity models
│   │   ├── profile_model.dart
│   │   ├── karma_history_model.dart
│   │   ├── player_location_model.dart
│   │   ├── create_profile_request_model.dart
│   │   ├── update_profile_request_model.dart
│   │   ├── update_avatar_request_model.dart
│   │   ├── update_location_request_model.dart
│   │   └── update_progress_request_model.dart
│   ├── datasources/
│   │   └── profile_remote_datasource.dart   # HTTP layer (single `_request` pipeline)
│   └── profile_repository_impl.dart         # Maps Exception → Failure
│
└── presentation/                    # UI + state
    ├── cubit/
    │   ├── profile_cubit.dart       # Business logic, emits ProfileState
    │   └── profile_state.dart       # Sealed state classes
    ├── controllers/
    │   └── avatar_upload_controller.dart  # Pick + upload + loading UI
    ├── pages/
    │   └── home_page.dart           # Main screen (orchestration only)
    └── widgets/
        ├── avatar_header.dart           # Legacy (giữ cho compat — không dùng nữa)
        ├── stat_card.dart               # ELO / Level / Karma card (accentColor)
        ├── personal_info_card.dart      # Bio, name, DOB, phone (InfoEntry pattern)
        ├── location_card.dart           # Saved location
        ├── setup_profile_form.dart      # First-time profile creation form
        ├── edit_profile_sheet.dart      # Bottom-sheet to edit bio/name
        ├── quick_actions_card.dart      # Grid 2x2 minimal
        ├── profile_sticky_header.dart   # SliverAppBar flexibleSpace (avatar + username)
        ├── profile_stats_row.dart       # 3 cards ELO + Level + Karma (responsive)
        ├── loading_skeleton.dart        # Shimmer dashboard
        ├── error_state.dart             # Error + retry CTA
        ├── section_card.dart            # Shared Material card
        └── detail_row.dart              # Icon + label + value row
```

### Nguyên tắc kiến trúc (Clean Architecture + SOLID)

| Layer | Trách nhiệm | Phụ thuộc |
|---|---|---|
| **Domain** | Entities, abstract repo | none (pure Dart) |
| **Data** | HTTP, JSON parse, error mapping | Domain |
| **Presentation** | UI, state, side-effects | Domain + Data (via DI) |

---

## 2. Key Classes

### `ProfileCubit` — state machine

Toàn bộ state changes đi qua 3 pipelines:

| Method | Emits | Ghi chú |
|---|---|---|
| `getProfile()` | `ProfileLoading → ProfileLoaded / ProfileFailure` | Khởi đầu flow |
| `createProfile(...)` | `ProfileLoading → ProfileLoaded / ProfileFailure` | Empty strings → `null` |
| `updateProfile(...)` | `ProfileLoading → ProfileLoaded / ProfileFailure` | Partial update |
| `deleteProfile()` | `ProfileLoading → ProfileDeleted / ProfileFailure` | Soft-delete (logout) |
| `updateAvatar(url)` | `ProfileLoading → ProfileLoaded / ProfileFailure` | Sau khi URL sinh ra từ Cloudinary |
| `getLocation()` | `ProfileLocationLoaded / ProfileFailure` | Không emit Loading |
| `updateLocation(...)` | `ProfileLocationLoaded / ProfileFailure` | Không emit Loading |
| `deleteLocation()` | `ProfileLocationDeleted / ProfileFailure` | Không emit Loading |
| `getKarmaHistory()` | `ProfileKarmaLoaded / ProfileFailure` | Không emit Loading |
| `updateProgress(...)` | `ProfileLoaded / ProfileFailure` | Không emit Loading |

### `ProfileState` (sealed classes)

| State | Mục đích |
|---|---|
| `ProfileInitial` | Start state |
| `ProfileLoading` | Full-screen loading (chỉ trong CRUD + avatar) |
| `ProfileLoaded` | Profile đã sẵn sàng, có thể kèm location/karma + `supplementaryError` |
| `ProfileFailure` | Lỗi mức screen |
| `ProfileDeleted` | Soft-delete thành công → trigger logout |
| `ProfileLocationLoaded` | Location read/update |
| `ProfileLocationDeleted` | Location cleared |
| `ProfileKarmaLoaded` | Karma read |

### `AvatarUploadController` — pure UI controller

Tách riêng khỏi `HomePage` để:
- Dễ unit-test (inject `ImagePicker` + `CloudinaryService` mock)
- Tái sử dụng cho các tính năng upload khác (café, board game, …)
- Che giấu sentinel `__cancelled__` của picker cancel

API chính:
```dart
final result = await controller.runWithFeedback(context);
// result == null nếu user cancel picker
// result.url là secure URL cần đẩy về ProfileCubit.updateAvatar
```

---

## 3. API Endpoints

| Method | Endpoint | Purpose |
|---|---|---|
| GET | `/api/userprofile` | Lấy hồ sơ của tôi |
| POST | `/api/userprofile` | Tạo hồ sơ lần đầu |
| PUT | `/api/userprofile` | Partial update (bio, name, DOB) |
| PUT | `/api/userprofile/me/avatar` | Cập nhật avatar URL |
| DELETE | `/api/userprofile` | Soft-delete |
| GET | `/api/userprofile/me/location` | Last known location |
| PUT | `/api/userprofile/me/location` | Update location |
| DELETE | `/api/userprofile/me/location` | Clear location |
| GET | `/api/userprofile/me/karma-history` | Karma snapshot |
| POST | `/api/userprofile/progress` | Update ELO + level (after match) |

**Header bắt buộc:** `Authorization: Bearer <token>` (do `AuthInterceptor` thêm).

---

## 4. Business Logic Flow

### Initial load (sau login)

```
HomePage.initState()
  → ProfileCubit.getProfile()
    → ProfileRepositoryImpl.getProfile()
      → ProfileRemoteDatasourceImpl._request(GET /userprofile)
        → ApiResponse<ProfileModel> → ProfileEntity
  → ProfileLoaded(profile)
    ├─ hasProfile == false → SetupProfileForm
    └─ hasProfile == true
       → ProfileCubit.getLocation()  // once
       → Build _Dashboard_
```

### Avatar upload (3 bước rõ ràng)

```
AvatarHeader.onAvatarTap
  → AvatarUploadController.runWithFeedback(context)
       1. Show loading dialog
       2. ImagePicker.pickImage (gallery)
       3. CloudinaryService.uploadImage
       4. Hide loading dialog
  → ProfileCubit.updateAvatar(url)
    → PUT /api/userprofile/me/avatar
  → ProfileLoaded → re-render AvatarHeader
```

### Location update (BẬT GPS)

```
LocationCard "Bật GPS" → ProfileCubit.updateLocation(lat, lng, source=0)
  → PUT /api/userprofile/me/location
  → ProfileLocationLoaded → ProfileCubit state cập nhật
```

> **Lưu ý:** Ở thời điểm hiện tại `_updateLocationGps` hard-code toạ độ HCM (10.7769, 106.7008). Khi tích hợp `geolocator`, chỉ cần thay 2 dòng này.

### Soft-delete (xoá hồ sơ)

```
ProfileCubit.deleteProfile()
  → DELETE /api/userprofile
  → ProfileDeleted
HomePage listener → toast "đã vô hiệu hoá" → AuthCubit.logout() → LoginPage
```

---

## 5. Refactor Notes (Lần refactor 2026-07-28)

### Vấn đề ban đầu
- `profile_remote_datasource.dart` 352 dòng — 9 method gần như identical, chỉ khác HTTP verb/path/body.
- `profile_repository_impl.dart` 242 dòng — 10 method copy-paste cùng pattern `try { … } on ServerException / DioException / catch {}`.
- `home_page.dart` 549 dòng — pha trộn form control, avatar upload cloud, dashboard composition, navigation.
- `profile_cubit.dart` 226 dòng — 3 nhóm supplementary ops (location/karma/delete) lặp lại `result.fold` không cần thiết.

### Cách xử lý

| File | Thay đổi | Giảm LOC |
|---|---|---|
| `profile_remote_datasource.dart` | Đưa toàn bộ HTTP + parse vào `_request<T>(method, path, body, fromJson)`. Tách `RequestType` enum. | 352 → 194 |
| `profile_repository_impl.dart` | Đưa toàn bộ error mapping vào `_guardEntity<M, T>` + `_guardVoid`. | 242 → 206 |
| `profile_cubit.dart` | Gộp 9 supplementary operations thành `_runProfileOperation` (loading + loaded/failure). Tổ chức lại theo 4 nhóm nghiệp vụ. | 226 → 163 |
| `home_page.dart` | Trích `AvatarUploadController`, `QuickActionsCard`, `_StatsRow`. Decorator `_runWithFeedback` cho upload. | 549 → 397 |

### Kiểm tra
- `flutter analyze lib/features/profile` → **0 issue**
- `flutter test test/features/profile/` → **26/26 pass**
- Nghiệp vụ 100% giữ nguyên (state emitted không đổi).

### Lợi ích
- **DRY**: 4 method HTTP + 10 method repository chia sẻ pipeline duy nhất.
- **SRP**: Cubit chỉ làm "điều phối state", controller làm "thao tác upload", page chỉ "compose UI".
- **Testable**: `AvatarUploadController` có thể inject mock `ImagePicker` + `CloudinaryService`.
- **Extensible**: Thêm endpoint mới chỉ cần 1 dòng `_request(...)` thay vì 25 dòng template.

---

## 6. Refactor Notes (Lần refactor 2026-07-29 — UI Mobile Redesign)

### Vấn đề
- Giao diện Profile dùng nhiều `Color(0x…)` và `BoxShadow` hardcode, bypass hoàn toàn Material 3 design system (`AppColors`, `AppElevation`, `AppRadius`).
- `home_page.dart` dùng `SingleChildScrollView` + Column, không có sticky header — header avatar chiếm chỗ cố định, không tận dụng được không gian cuộn.
- `personal_info_card.dart` lặp pattern `if (field != null) Padding(DetailRow)` 4 lần (DRY violation).
- `quick_actions_card.dart` hiển thị list dọc — tốn nhiều chiều dọc, không thân thiện mobile.

### Cách xử lý

| File | Thay đổi |
|---|---|
| `home_page.dart` | Chuyển sang `CustomScrollView` + `SliverAppBar` (pinned) + `SliverToBoxAdapter` cho từng section. Tách thành `_DashboardShell` / `_SetupShell` / `_LoadingShell` để mỗi shell độc lập, dễ test. |
| `profile_sticky_header.dart` (mới) | `flexibleSpace` cho `SliverAppBar`. Avatar + username tự scale khi collapse, không gradient, dùng `Theme.colorScheme` + `AppRadius`. |
| `profile_stats_row.dart` (mới) | 3 thẻ ELO/Level/Karma. Dùng `LayoutBuilder`: width ≥ 600 → 3 cột, width < 600 → stacked (mobile). |
| `stat_card.dart` | Đổi `iconColor` → `accentColor`, dùng `AppElevation.shadowXs`, `AppRadius.radiusLgAll`, `Theme.colorScheme.outlineVariant`. Bỏ toàn bộ hex color. |
| `quick_actions_card.dart` | Đổi list dọc → `GridView.count(crossAxisCount: 2)`. Mỗi tile là icon + title + forward arrow, dùng `Material` + `InkWell` để có ripple. |
| `personal_info_card.dart` | Pattern `if (x != null) Padding(DetailRow)` → list `InfoEntry` + `where(value.isNotEmpty)`. Filter tập trung, dễ thêm field mới. |
| `location_card.dart` | Tách thành `_LoadedLocation` + `_EmptyLocation` để SRP. Dùng theme tokens. |
| `loading_skeleton.dart` | Bám sát layout mới: 3 stat cards stacked + 2 info cards + quick actions grid 2x2. |
| `section_card.dart` / `detail_row.dart` | Dùng `AppRadius.radiusLgAll`, `AppSpacing.xxs` thay cho hardcode. |
| `error_state.dart` | Dùng `Theme.colorScheme.errorContainer` thay cho hardcode. |
| `profile_sticky_header.dart` | dùng `Theme.colorScheme.surfaceContainerHighest` thay cho `surfaceVariant` (deprecated). |

### Kiểm tra
- `flutter analyze lib/features/profile` → **0 issue**
- `flutter test test/features/profile/` → **26/26 pass**
- Không thay đổi `ProfileCubit` / `ProfileState` / `ProfileEntity` / API contract.

### Lợi ích
- **DRY**: `InfoEntry` pattern ở `PersonalInfoCard`, theme tokens ở mọi nơi → bỏ hàng chục `Color(0x…)` và `BoxShadow` rải rác.
- **SRP**: `HomePage` chỉ điều phối state, giao layout cho `_DashboardShell`; mỗi widget con 1 trách nhiệm (sticky header, stats, info, location, quick actions, skeleton, error).
- **OCP**: thêm stat mới chỉ cần thêm 1 `_xxxCard()` trong `ProfileStatsRow`; thêm field info chỉ cần thêm 1 `InfoEntry`.
- **Responsive**: `ProfileStatsRow` dùng `LayoutBuilder` thay vì hardcode layout — 1 widget chạy mobile + tablet.
- **Testable**: `ProfileStickyHeader` có thể test riêng, layout collapse có thể test bằng cách truyền `maxExtent` constraint.

---

## 6. File Interactions

```
HomePage
├── ProfileCubit ─────────── state management
├── AvatarUploadController ─ pick + upload
├── CloudinaryService ────── upload binary
├── AuthCubit ────────────── logout
└── widgets/* ────────────── UI composition

ProfileCubit
└── ProfileRepository (interface)
    └── ProfileRepositoryImpl
        ├── ProfileRemoteDatasource (interface)
        │   └── ProfileRemoteDatasourceImpl
        │       └── Dio (with AuthInterceptor)
        └── Error mapping
            ServerException → ServerFailure
            DioException → NetworkFailure | ServerFailure
```

---

## 7. Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | `Cubit` + `BlocConsumer` |
| `dartz` | `Either<Failure, T>` |
| `equatable` | State equality |
| `dio` | HTTP client |
| `image_picker` | Avatar picker |
| `freezed` / `json_annotation` | Immutable models |
| `delightful_toast` | Toast feedback |

---

## 8. Quick Reference

| Task | File |
|---|---|
| Add new profile field | `profile_entity.dart` + `profile_model.dart` |
| Add new API endpoint | `profile_remote_datasource.dart` (1 line) + `profile_repository.dart` (1 line) + `profile_repository_impl.dart` (1 line) |
| Add new state | `profile_state.dart` + `profile_cubit.dart` |
| Change UI layout | `home_page.dart` (orchestration) + `widgets/*` (components) |
| Modify upload flow | `avatar_upload_controller.dart` |
| Tweak section card | `section_card.dart` (shared) |
