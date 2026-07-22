# Profile Feature Module

## Overview

Module quản lý user profile bao gồm thông tin cá nhân, avatar, karma score, ELO rating, và location. Hỗ trợ tạo profile mới, cập nhật, và xóa profile.

**Tổng số file**: 43 files

---

## 1. Architecture

```
lib/features/profile/
├── domain/
│   ├── entities/
│   │   ├── profile_entity.dart           # Core user profile entity
│   │   ├── karma_history_entity.dart     # Karma reputation history
│   │   └── player_location_entity.dart   # GPS/manual location
│   └── repositories/
│       └── profile_repository.dart       # Repository interface
├── data/
│   ├── models/
│   │   ├── profile_model.dart           # Freezed model
│   │   ├── karma_history_model.dart     # Freezed model
│   │   ├── player_location_model.dart   # Freezed model
│   │   ├── create_profile_request_model.dart
│   │   ├── update_profile_request_model.dart
│   │   ├── update_avatar_request_model.dart
│   │   ├── update_location_request_model.dart
│   │   └── update_progress_request_model.dart
│   ├── datasources/
│   │   └── profile_remote_datasource.dart
│   └── profile_repository_impl.dart
└── presentation/
    ├── cubit/
    │   ├── profile_cubit.dart           # State management
    │   └── profile_state.dart           # Sealed state classes
    ├── pages/
    │   └── home_page.dart               # Main profile page
    └── widgets/
        ├── avatar_header.dart
        ├── stat_card.dart
        ├── personal_info_card.dart
        ├── location_card.dart
        ├── setup_profile_form.dart
        ├── edit_profile_sheet.dart
        ├── loading_skeleton.dart
        ├── error_state.dart
        ├── section_card.dart
        └── detail_row.dart
```

---

## 2. Key Classes

### ProfileCubit

**Methods:**

| Method | Purpose |
|--------|---------|
| `getProfile()` | Fetch current user profile |
| `createProfile(...)` | Create profile first time |
| `updateProfile(...)` | Partial update (bio, name, DOB) |
| `updateAvatar(avatarUrl)` | Update avatar URL (Cloudinary) |
| `deleteProfile()` | Soft-delete profile |
| `getLocation()` | Get saved location |
| `updateLocation(...)` | Save GPS or manual location |
| `deleteLocation()` | Remove saved location |
| `getKarmaHistory()` | Get karma reputation data |
| `updateProgress(...)` | Update ELO/level after match |

### ProfileState (Sealed Classes)

| State | Purpose |
|-------|---------|
| `ProfileInitial` | Start state |
| `ProfileLoading` | During any mutation operation |
| `ProfileLoaded(ProfileEntity)` | Successful profile fetch/update |
| `ProfileNotFound(String)` | 404 handling |
| `ProfileFailure(String)` | Any error |
| `ProfileDeleted` | Soft-delete success, triggers logout |
| `ProfileLocationLoaded(PlayerLocationEntity)` | Location fetched/updated |
| `ProfileLocationDeleted` | Location removed |
| `ProfileKarmaLoaded(KarmaHistoryEntity)` | Karma history fetched |

### ProfileEntity

```dart
class ProfileEntity extends Equatable {
  final String userId;
  final String username;
  final String? avatar;
  final String? bio;
  final double karma;
  final String tier;
  final int globalElo;
  final int level;
  final bool hasProfile;  // New user flag
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  // ... location fields
}
```

### PlayerLocationEntity

```dart
class PlayerLocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final bool hasLocation;
  final LocationSource source;  // gps = 0, manual = 1
}

enum LocationSource { gps, manual }
```

---

## 3. API Endpoints

| Method | Endpoint | Purpose |
|--------|----------|---------|
| GET | `/api/userprofile` | Fetch current user profile |
| POST | `/api/userprofile` | Create profile first time |
| PUT | `/api/userprofile` | Partial update (bio, name, DOB) |
| PUT | `/api/userprofile/me/avatar` | Update avatar URL (Cloudinary) |
| DELETE | `/api/userprofile` | Soft-delete profile |
| GET | `/api/userprofile/me/location` | Get saved location |
| PUT | `/api/userprofile/me/location` | Save GPS or manual location |
| DELETE | `/api/userprofile/me/location` | Remove saved location |
| GET | `/api/userprofile/me/karma-history` | Get karma reputation data |
| POST | `/api/userprofile/progress` | Update ELO/level after match |

---

## 4. Business Logic Flow

### Initial Load

```
HomePage.initState()
  → ProfileCubit.getProfile()
    → ProfileRepository.getProfile()
      → ProfileRemoteDatasource.getProfile() [GET /api/userprofile]
        → ApiResponse<ProfileModel>
  → ProfileLoaded(profile)
    → IF hasProfile=false: Show SetupProfileForm
    → IF hasProfile=true:
      → ProfileCubit.getLocation() [parallel]
      → Build dashboard UI
```

### Avatar Upload

```
changeAvatar()
  → ImagePicker.pickImage(gallery)
  → CloudinaryService.uploadImage()
  → ProfileCubit.updateAvatar(url)
    → [PUT /api/userprofile/me/avatar]
  → ProfileLoaded → re-render AvatarHeader
```

### Location Update

```
updateLocationGps() → hardcoded lat=10.7769, lng=106.7008, source=0 (GPS)
  → ProfileCubit.updateLocation(lat, lng, source)
    → [PUT /api/userprofile/me/location]
  → ProfileLocationLoaded → LocationCard re-renders
```

---

## 5. Key Design Decisions

1. **`hasProfile` flag**: API trả về `hasProfile=false` cho user mới. UI branches: show `SetupProfileForm` vs dashboard.

2. **Location null-safety**: `PlayerLocationModel` dùng nullable lat/lng vì backend trả về `null` khi `hasLocation=false`.

3. **Location source encoding**: `int` (0=GPS, 1=Manual) gửi lên API. Entity convert sang `LocationSource` enum.

4. **Avatar upload flow**: Pick image → upload to Cloudinary → get URL → PUT to backend.

5. **Soft delete**: `deleteProfile()` gọi DELETE endpoint, trả về void. `ProfileDeleted` state trigger logout flow.

6. **Progress update**: `updateProgress(globalElo, level)` được gọi bởi match result flow.

---

## 6. File Interactions

```
home_page.dart
├── uses: ProfileCubit (actions, state listening)
├── uses: AvatarHeader (profile header)
├── uses: ProfileStatCard x2 (ELO + Level)
├── uses: PersonalInfoCard (info + edit button)
├── uses: LocationCard (BlocBuilder for location state)
├── uses: SetupProfileForm (when hasProfile=false)
├── uses: EditProfileSheet (bottom sheet modal)
├── uses: CloudinaryService (avatar upload)
└── uses: AuthCubit (logout)

profile_cubit.dart
├── depends on: ProfileRepository
└── emits: ProfileState subclasses

profile_repository.dart (interface)
└── implemented by: ProfileRepositoryImpl

profile_repository_impl.dart
├── depends on: ProfileRemoteDatasource
└── converts: ServerException → ServerFailure
            DioException → NetworkFailure/ServerFailure

profile_remote_datasource.dart
├── depends on: Dio
└── uses: ApiResponse wrapper + All Request/Response models
```

---

## 7. Dependencies

| Package | Purpose |
|---------|---------|
| `flutter_bloc` | State management |
| `dartz` | Functional error handling |
| `equatable` | Value equality |
| `dio` | HTTP client |
| `flutter_secure_storage` | Token storage |
| `image_picker` | Avatar selection |
| `cloudinary_flutter` | Image upload (optional) |
| `freezed` | Immutable models |
| `json_annotation` | JSON serialization |

---

## 8. Quick Reference

| Task | File/Method |
|------|-------------|
| Add new profile field | `profile_entity.dart` + `profile_model.dart` |
| Add new API endpoint | `profile_remote_datasource.dart` + `profile_repository.dart` |
| Add new state | `profile_state.dart` |
| Change UI layout | `home_page.dart` |
| Modify avatar upload | `avatar_header.dart` |
