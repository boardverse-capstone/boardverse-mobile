# BoardVerse Mobile - Core Module Documentation

## Overview

Module `lib/core` chứa các thành phần **cross-cutting** (xuyên suốt ứng dụng), không thuộc về bất kỳ feature cụ thể nào. Đây là tầng nền tảng cung cấp infrastructure cho toàn bộ ứng dụng.

### Module Count
- **41 files** | **~3,000 dòng code**

### Key Components

| Category | Files | Purpose |
|----------|-------|---------|
| Config | 1 | App-wide configuration |
| Constants | 1 | API endpoints |
| DI | 1 | Dependency injection (GetIt) |
| Error | 2 | Exception & Failure classes |
| Navigation | 10 | Tab navigation & routing |
| Network | 3 | Dio HTTP client, auth interceptor |
| Services | 9 | Cloudinary, storage services |
| Theme | 9 | Design system (colors, typography, spacing) |
| Utils | 1 | JWT user resolver |
| Widgets | 1 | Shimmer loading skeletons |

---

## 1. Configuration (`lib/core/config/`)

### `app_config.dart` - Single Source of Truth

Central configuration cho toàn bộ ứng dụng:

```dart
class AppConfig {
  // ─── Data Source Mode ───
  static const bool useMockData = true;           // Global mock toggle
  static const bool useMockLobbyData = true;      // Lobby-specific
  static const bool useMockMatchData = true;      // Match-specific

  // ─── Cache Configuration ───
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration seatRefreshInterval = Duration(seconds: 30);

  // ─── Search Configuration ───
  static const double defaultSearchRadiusKm = 15.0;
  static const int defaultMinKarma = 0;

  // ─── Business Rules ───
  static const int maxDepositMinutesLimit = 30;   // BR-06
  static const double maxDepositPercentage = 50.0; // BR-03 (50% of first hour)
  static const int defaultSeatHoldMinutes = 5;     // Pending payment hold

  // ─── UI Configuration ───
  static const Duration searchDebounceMs = Duration(milliseconds: 500);
  static const int similarGamesLimit = 5;
}
```

**Business Rules được cấu hình tại đây:**
- **BR-03**: Max deposit = 50% first hour price
- **BR-06**: Max deposit hold = 30 minutes
- **BR-10**: Min karma for matchmaking = 0

---

## 2. Constants (`lib/core/constants/`)

### `api_endpoints.dart` - API Route Registry

Single source of truth cho tất cả REST endpoints:

```dart
class ApiEndpoints {
  // Auth
  static const String login = '/api/Auth/login';
  static const String register = '/api/Auth/register';
  static const String refreshToken = '/api/Auth/refresh-token';
  static const String googleLogin = '/api/Auth/google-login';

  // User Profile
  static const String userProfile = '/api/userprofile';
  static const String userProfileAvatar = '/api/userprofile/me/avatar';

  // Board Games
  static const String boardGames = '/api/v1/board-games';
  static const String boardGameDetail = '/api/v1/board-games/{id}';

  // Cafes
  static const String cafesNearby = '/api/cafes/nearby';
  static const String cafeDetail = '/api/cafes/{id}';

  // Bookings
  static const String createBooking = '/api/Bookings';
  static const String paymentCreate = '/api/Payments/create-url';

  // Lobbies
  static const String lobbiesSearch = '/api/v1/lobbies/search';
  static const String lobbyJoin = '/api/v1/lobbies/{id}/join';

  // Tournaments
  static const String tournamentsOpen = '/api/v1/tournaments/open';
  static String tournamentDetail(String id) => '/api/v1/tournaments/$id';
}
```

**Note**: Endpoint có thể chứa placeholder `{id}`, cần replace trước khi gọi.

---

## 3. Error Handling (`lib/core/error/`)

### Architecture Pattern

```
Exception (Data Layer) → Failure (Domain Layer) → UI State
```

### `exceptions.dart` - Data Layer Exceptions

```dart
class ServerException implements Exception {
  final String message;
  final int? statusCode;
}

class NetworkException implements Exception {
  final String message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
}

class CacheException implements Exception {
  final String message = 'Lỗi lưu trữ cục bộ.';
}
```

**Usage**: Throw trong data layer (repositories, datasources).

### `failures.dart` - Domain Layer Failures

```dart
sealed class Failure extends Equatable {
  final String message;
}

class ServerFailure extends Failure {
  final int? statusCode;
}

class NetworkFailure extends Failure {
  final String message = 'Không có kết nối mạng. Vui lòng kiểm tra lại.';
}

class CacheFailure extends Failure {
  final String message = 'Lỗi lưu trữ cục bộ.';
}
```

**Usage**: Convert từ Exception trong repository implementation, chứa message hiển thị cho user.

---

## 4. Network Layer (`lib/core/network/`)

### `dio_client.dart` - HTTP Client Singleton

Sử dụng **Dio** để giao tiếp REST API:

```dart
class DioClient {
  late final Dio dio;

  DioClient({required AuthInterceptor authInterceptor}) {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    dio.interceptors.add(authInterceptor);
    // Log interceptor trong debug mode
    assert(() {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
      return true;
    }());
  }
}
```

### `auth_interceptor.dart` - JWT Token Management

**Interceptor tự động:**
1. Attach `Authorization: Bearer <token>` vào mọi request
2. Handle 401 → refresh token → retry request
3. Nếu refresh fail → clear tokens (force logout)

```dart
class AuthInterceptor extends Interceptor {
  // onRequest: Attach Bearer token
  // onError: Handle 401 → refresh token flow
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
}
```

**Flow:**
```
Request → [No Token] → Add Token → Continue
Request → [Got 401] → Refresh → Retry with new token
Refresh → [Failed] → Clear tokens → Return error
```

### `api_response.dart` - Response Envelope

Backend response format:

```json
{
  "statusCode": 200,
  "message": "OK",
  "data": { ... },
  "timestamp": "2026-05-31T12:34:56Z",
  "path": "/api/auth/login"
}
```

```dart
class ApiResponse<T> {
  final int statusCode;
  final String message;
  final T? data;
  final String? timestamp;
  final String? path;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}
```

---

## 5. Dependency Injection (`lib/core/di/`)

### `injection.dart` - GetIt Service Locator

Register toàn bộ dependencies của ứng dụng:

```dart
final sl = GetIt.instance;
final getIt = sl;

void setupDependencies() {
  // ─── External ───
  sl.registerLazySingleton<FlutterSecureStorage>(() => FlutterSecureStorage());

  // ─── Core / Network ───
  sl.registerLazySingleton<AuthInterceptor>(...);
  sl.registerLazySingleton<DioClient>(...);
  sl.registerLazySingleton<Dio>(() => sl<DioClient>().dio);

  // ─── Features ───
  // Auth
  sl.registerLazySingleton<AuthRemoteDatasource>(...);
  sl.registerLazySingleton<AuthRepository>(...);
  sl.registerFactory<AuthCubit>(...);

  // Profile
  sl.registerLazySingleton<ProfileRemoteDatasource>(...);
  sl.registerLazySingleton<ProfileRepository>(...);
  sl.registerFactory<ProfileCubit>(...);

  // Lobby (Mock/Real toggle per feature)
  sl.registerLazySingleton<LobbyRemoteDatasource>(() =>
    AppConfig.useMockLobbyData
      ? MockLobbyRemoteDatasource()
      : RealLobbyRemoteDatasource(dio: sl<Dio>())
  );

  // Match (Mock/Real toggle per feature)
  sl.registerLazySingleton<MatchResultRemoteDatasource>(() =>
    AppConfig.useMockMatchData
      ? MockMatchResultRemoteDatasource()
      : RealMatchResultRemoteDatasource(dio: sl<Dio>())
  );

  // Booking (Mock/Real toggle)
  sl.registerLazySingleton<BookingRemoteDatasource>(() =>
    AppConfig.useMockData
      ? MockBookingRemoteDatasource()
      : BookingRemoteDatasourceImpl(dio: sl<Dio>())
  );

  // Tournament (Always real)
  sl.registerLazySingleton<TournamentRemoteDatasource>(...);

  // Theme
  sl.registerLazySingleton<ThemePreferencesService>(...);
  sl.registerLazySingleton<ThemeCubit>(...);

  // Cloudinary (Conditional - only if env configured)
  if (CloudinaryConfig.isValid) {
    sl.registerLazySingleton<CloudinaryService>(() => CloudinaryService.fromEnv());
  }
}
```

**Pattern Types:**
- `registerLazySingleton`: Một instance cho toàn app (singleton)
- `registerFactory`: Instance mới mỗi lần resolve (dùng cho Cubits)

**Per-Feature Mock Toggle:**
Thay vì global toggle, mỗi feature có thể switch độc lập:
- `AppConfig.useMockData` - Global
- `AppConfig.useMockLobbyData` - Lobby only
- `AppConfig.useMockMatchData` - Match only

---

## 6. Navigation (`lib/core/navigation/`)

### `nav_tab.dart` - Tab Definition

```dart
enum NavTab {
  home(0, 'Trang chủ'),
  bookings(1, 'Phòng chờ'),
  discovery(2, 'Khám phá'),
  tournament(3, 'Giải đấu'),
  profile(4, 'Cá nhân');

  final int tabIndex;
  final String label;
}
```

### `navigation_cubit.dart` - Tab State Management

```dart
class NavigationCubit extends Cubit<NavigationState> {
  void setTab(int index) {
    final clamped = index.clamp(0, NavTab.values.length - 1);
    emit(state.copyWith(currentIndex: clamped));
  }

  void setTabFromEnum(NavTab tab) => setTab(tab.tabIndex);
  void goHome() => setTab(NavTab.home.tabIndex);
}

class NavigationState extends Equatable {
  final int currentIndex; // Default = 0 (Home)
}
```

### `widgets/board_verse_nav_bar.dart` - Glassmorphism Nav Bar

Custom bottom navigation với design hiện đại:

**Features:**
- **Glassmorphism**: Backdrop blur effect
- **Floating**: Margin từ bottom
- **Center FAB**: Discovery button nổi bật giữa
- **Haptic**: Vibration feedback khi tap
- **Dark/Light**: Tự động adapt theo theme

**Structure:**
```
┌─────────────────────────────────────────┐
│  [Home]    [Bookings]  [🔵]  [Tournament] [Profile]  │
└─────────────────────────────────────────┘
        ↑ Discovery FAB (centered)
```

**Key Widgets:**
- `BoardVerseNavBar` - Entry point với BlocSelector
- `_NavBarContent` - Main UI với glassmorphism
- `_NavItemV2` - Individual tab item
- `_CenterDiscoveryButton` - Center FAB
- `AnimatedPageTransition` - Smooth page transition

### `tournament_routes.dart` - Tournament Navigation Helpers

Centralized routing cho tournament feature:

```dart
class TournamentRoutes {
  // Push pages với consistent animation
  static Future<T?> openTournamentDetail<T>(...);
  static Future<T?> openParticipantDetail<T>(...);
  static Future<T?> openMatchDetail<T>(...);
  static Future<T?> openMyRegistrations<T>(...);
  static Future<T?> openEloHistory<T>(...);
  static Future<T?> openLeaderboard<T>(...);

  // Shared transition: iOS-style slide from right
  static Route<T> _routeBuilder<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: Duration(milliseconds: 320),
      // Slide from right animation
    );
  }
}
```

**Usage:**
```dart
TournamentRoutes.openTournamentDetail(
  context: context,
  tournamentId: 'abc123',
);
```

---

## 7. Theme / Design System (`lib/core/theme/`)

### Architecture

```
theme.dart (export all)
├── app_colors.dart       (Light mode colors)
├── app_colors_dark.dart  (Dark mode colors)
├── app_typography.dart   (Text styles)
├── app_spacing.dart      (8pt grid spacing)
├── app_radius.dart       (Border radius)
├── app_elevation.dart    (Shadow system)
├── app_shimmer.dart      (Loading animations)
├── app_icons.dart        (Icon sizes)
└── app_theme.dart        (ThemeData builder)
```

### `app_colors.dart` - Brand & Semantic Colors

**Light Mode:**

```dart
class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFE65100);      // Deep Orange
  static const Color secondary = Color(0xFF00897B);     // Teal
  static const Color accent = Color(0xFFFFD600);       // Amber

  // Semantic Colors
  static const Color success = Color(0xFF00C853);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFAB00);
  static const Color info = Color(0xFF2979FF);

  // Background
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFF5F5F5);

  // Text
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  // Functional
  static const Color starFilled = Color(0xFFFFD600);
  static const Color difficultyEasy = Color(0xFF4CAF50);
  static const Color difficultyMedium = Color(0xFFFF9800);
  static const Color difficultyHard = Color(0xFFFF5722);
  static const Color difficultyExpert = Color(0xFFF44336);

  // Gradients
  static const List<Color> cardGradientOrange = [Color(0xFFE65100), Color(0xFFFF9E40)];
  static const List<Color> cardGradientTeal = [Color(0xFF00897B), Color(0xFF4EBAAA)];
}
```

### `app_colors_dark.dart` - Dark Mode Colors

```dart
class AppColorsDark {
  // Background
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);

  // Brand (adjusted for dark)
  static const Color primary = Color(0xFFFF9E40);  // Lighter for dark bg
}
```

### `app_typography.dart` - Typography System

**Font**: Be Vietnam Pro (tối ưu tiếng Việt)

```dart
class AppTypography {
  static TextTheme get textThemeLight => _buildTextTheme(...);
  static TextTheme get textThemeDark => _buildTextTheme(...);

  // Text Style Hierarchy
  // Display: Hero titles (57px, 45px, 36px)
  // Headline: Section titles (32px, 28px, 24px)
  // Title: Card titles (22px, 16px, 14px)
  // Body: Content (16px, 14px, 12px)
  // Label: Buttons, chips (14px, 12px, 11px)

  // Helpers
  static TextStyle priceStyle(BuildContext context);  // Primary color, bold
  static TextStyle badgeStyle(BuildContext context);  // White, bold
  static TextStyle captionStyle(BuildContext context); // Secondary color
}
```

### `app_spacing.dart` - 8pt Grid System

```dart
class AppSpacing {
  // Base values
  static const double xxs = 4.0;    // 4px
  static const double xs = 8.0;     // 8px
  static const double sm = 12.0;    // 12px
  static const double md = 16.0;    // 16px (default)
  static const double lg = 20.0;    // 20px
  static const double xl = 24.0;    // 24px
  static const double xxl = 32.0;   // 32px
  static const double xxxl = 40.0;  // 40px

  // Screen
  static const double screenHorizontal = md;  // 16px
  static const double screenVertical = lg;     // 20px

  // Components
  static const double cardPadding = md;       // 16px
  static const double buttonHorizontal = lg;   // 20px
  static const double buttonVertical = md;      // 16px
  static const double bottomNavHeight = 80.0;

  // Pre-built EdgeInsets
  static const EdgeInsets screenPadding = ...;
  static const EdgeInsets cardPaddingAll = ...;
  static const EdgeInsets buttonPadding = ...;
}
```

### `app_radius.dart` - Border Radius System

```dart
class AppRadius {
  // Values
  static const double radiusXxs = 4.0;
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 999.0;  // Circle

  // Pre-built BorderRadius
  static const BorderRadius buttonRadius = radiusXsAll;
  static const BorderRadius cardRadius = radiusLgAll;
  static const BorderRadius bottomSheetRadius = radiusXlAll;
  static const BorderRadius avatarRadius = radiusFullAll;

  // Directional
  static BorderRadius radiusTopOnly({...});
  static BorderRadius radiusBottomOnly({...});
}
```

### `app_elevation.dart` - Shadow System

```dart
class AppElevation {
  // Values
  static const double elevationNone = 0.0;
  static const double elevationXxs = 1.0;
  static const double elevationXs = 2.0;
  static const double elevationSm = 4.0;
  static const double elevationMd = 6.0;
  static const double elevationLg = 8.0;

  // Pre-built shadows
  static List<BoxShadow> get shadowNone => [];
  static List<BoxShadow> get shadowSm => [...];  // Cards
  static List<BoxShadow> get shadowMd => [...];  // Floating
  static List<BoxShadow> get shadowLg => [...];  // Modals

  // Brand-specific
  static List<BoxShadow> get card => [...];
  static List<BoxShadow> get cardElevated => [...];
  static List<BoxShadow> get fab => [...];
  static List<BoxShadow> get bottomSheet => [...];
}
```

### `app_theme.dart` - Material 3 Theme Builder

```dart
class AppTheme {
  static const String appName = 'BoardVerse';

  static ThemeData get lightTheme => _buildTheme(...);
  static ThemeData get darkTheme => _buildTheme(...);

  // Applies to both themes:
  // - useMaterial3: true
  // - fontFamily: 'Be Vietnam Pro'
  // - AppBarTheme
  // - BottomNavigationBarTheme
  // - NavigationBarTheme (Material 3)
  // - CardTheme
  // - Button themes (Elevated, Filled, Outlined, Text)
  // - InputDecorationTheme
  // - ChipTheme
  // - DialogTheme
  // - BottomSheetTheme
  // - SnackBarTheme
  // - SwitchTheme
  // - CheckboxTheme
  // - TabBarTheme
  // - ProgressIndicatorTheme
}
```

---

## 8. Services (`lib/core/services/`)

### Cloudinary (`cloudinary/`)

Image upload & transformation service:

#### `cloudinary_config.dart`

```dart
class CloudinaryConfig {
  // From .env
  static String get cloudName => dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
  static String get uploadPreset => dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
  static String get defaultFolder => dotenv.env['CLOUDINARY_DEFAULT_FOLDER'] ?? 'boardverse/uploads';
  static bool get autoOptimize => (raw ?? 'true').toLowerCase() == 'true';

  // Validation
  static bool get isValid => cloudName.isNotEmpty && uploadPreset.isNotEmpty;

  // Upload endpoint
  static String uploadEndpoint() => 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
```

#### `cloudinary_service.dart` - Main Entry Point

```dart
class CloudinaryService {
  // Upload
  Future<String> uploadImage({
    required File file,
    String? folder,
    String? publicId,
    void Function(double progress)? onProgress,
  });

  Future<CloudinaryUploadResult> uploadImageDetailed({...});

  // Build URL
  String buildUrl({
    required String publicId,
    required CloudinaryTransformation transformation,
  });

  // Widget
  Widget image({
    required String publicId,
    required CloudinaryTransformation transformation,
  });
}
```

#### `cloudinary_uploader.dart` - Upload Logic

```dart
class CloudinaryUploadResult {
  final String secureUrl;    // HTTPS URL to save to backend
  final String publicId;    // For derived transformations
  final int bytes;           // File size
  final String format;       // jpg, png, webp
  final int? width;
  final int? height;
}

class CloudinaryUploader {
  Future<CloudinaryUploadResult> upload({
    required File file,
    required String folder,
    String? publicId,
    void Function(double progress)? onProgress,
  });
}
```

#### `cloudinary_transformation.dart` - Base Transformation

```dart
abstract class CloudinaryTransformation {
  Transformation toCldTransformation();

  // Auto-append f_auto/q_auto if CloudinaryConfig.autoOptimize
  void applyOptimization(Transformation t) {
    t.delivery(Delivery.format(Format.auto));
    t.delivery(Delivery.quality(Quality.auto()));
  }
}
```

#### Pre-built Transformations

```dart
// Avatar: Square, face-aware crop
AvatarTransformation.small()     // 96px
AvatarTransformation.medium()    // 200px
AvatarTransformation.large()    // 400px

// Cafe: Fit width, preserve aspect
CafeImageTransformation.thumb()    // 320px max width
CafeImageTransformation.gallery()  // 800px max width
CafeImageTransformation.detail()   // 1600px max width
```

#### `cloudinary_url_builder.dart`

```dart
class CloudinaryUrlBuilder {
  String build(String publicId, CloudinaryTransformation transformation);
}

// Usage
final url = cloudinaryService.buildUrl(
  publicId: 'boardverse/avatars/user123',
  transformation: AvatarTransformation.medium(),
);
```

### Storage (`storage/`)

#### `theme_preferences_service.dart`

```dart
class ThemePreferencesService {
  // Persist theme preference using FlutterSecureStorage
  // Key: 'theme_mode'
  // Values: 'light', 'dark', 'system'

  Future<ThemeMode> loadMode();   // Async read
  ThemeMode get defaultMode => ThemeMode.system;
  Future<void> saveMode(ThemeMode mode);
}
```

---

## 9. Utilities (`lib/core/utils/`)

### `current_user_resolver.dart` - JWT User Info

```dart
class CurrentUserResolver {
  // Read current user ID from stored JWT access token
  Future<String?> resolveUserId();

  // Read email from JWT
  Future<String?> resolveEmail();

  // Read username from JWT
  Future<String?> resolveUsername();
}

// JWT Claim Keys (XML Soap format from .NET backend)
class _JwtClaimKeys {
  static const String nameIdentifier = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  static const String name = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
  static const String email = 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';
}
```

**Note**: Returns null if token expired or missing.

---

## 10. Widgets (`lib/core/widgets/`)

### `shimmer_skeletons.dart` - Loading Placeholders

```dart
// Base
ShimmerBase(width: 100, height: 50, radius: 8);

// Tournament
TournamentCardSkeleton();    // List item placeholder
TournamentListSkeleton();    // Multiple cards

// Leaderboard
LeaderboardTileSkeleton();   // Row with avatar
LeaderboardListSkeleton();   // Multiple rows

// Elo History
EloHistorySkeleton();        // Hero + chart + list
```

**Usage:**
```dart
// Loading state
if (state is Loading) {
  return TournamentListSkeleton(itemCount: 4);
}
```

---

## Architecture Summary

```
┌─────────────────────────────────────────────────────────────┐
│                      lib/core                              │
├─────────────────────────────────────────────────────────────┤
│  config/        AppConfig (single source of truth)          │
│  constants/     ApiEndpoints (all REST routes)               │
│  di/            GetIt injection setup                      │
│  error/         Exceptions → Failures → UI                 │
│  navigation/    Tab navigation, tournament routing          │
│  network/       Dio client, auth interceptor               │
│  services/       Cloudinary, storage                        │
│  theme/          Design system (colors, spacing, etc.)     │
│  utils/          JWT user resolver                         │
│  widgets/        Shared widgets (shimmer)                  │
└─────────────────────────────────────────────────────────────┘

                         ↓
┌─────────────────────────────────────────────────────────────┐
│                    lib/features                             │
│  auth/  profile/  matchmaking_discovery/  lobby_management/  │
│  booking_payment/  in_game_experience/  match/                │
│  match_summary_rating/  tournament/  settings/             │
└─────────────────────────────────────────────────────────────┘
```

## Common Patterns

### 1. Mock/Real Toggle Pattern

```dart
// In injection.dart
sl.registerLazySingleton<SomeDatasource>(() =>
  AppConfig.useMockData
    ? MockSomeDatasource()
    : RealSomeDatasource(dio: sl<Dio>())
);

// In app_config.dart
static const bool useMockData = true;  // Toggle here
```

### 2. Error Flow Pattern

```dart
// Data Layer
try {
  final data = await api.get('/endpoint');
  return Right(data);
} on ServerException catch (e) {
  return Left(ServerFailure(message: e.message));
} on NetworkException catch (e) {
  return Left(NetworkFailure(message: e.message));
}
```

### 3. Token Refresh Flow

```dart
// Dio interceptor handles automatically:
// 1. Attach token on request
// 2. On 401, call refresh endpoint
// 3. Retry with new token
// 4. On refresh fail, clear tokens
```

### 4. Dependency Access

```dart
// Get registered instance
final dio = sl<Dio>();
final repository = sl<SomeRepository>();

// Create new instance (factory)
final cubit = sl<SomeCubit>();
```

---

## Environment Variables

Required in `.env`:

```bash
# API
API_BASE_URL=https://api.boardverse.com

# Cloudinary (optional - app boots without it)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_UPLOAD_PRESET=your_upload_preset
CLOUDINARY_DEFAULT_FOLDER=boardverse/uploads
CLOUDINARY_AUTO_OPTIMIZE=true
```

---

## Quick Reference

| What | Where |
|------|-------|
| API Base URL | `dotenv.env['API_BASE_URL']` |
| Change mock mode | `AppConfig.useMockData` |
| All endpoints | `ApiEndpoints.*` |
| Theme colors | `AppColors.*` (light) / `AppColorsDark.*` (dark) |
| Spacing | `AppSpacing.xs`, `AppSpacing.md`, etc. |
| User ID | `sl<CurrentUserResolver>().resolveUserId()` |
| Register deps | `injection.dart` → `setupDependencies()` |
| Navigation | `NavigationCubit`, `TournamentRoutes` |
| Image upload | `sl<CloudinaryService>()` |

---

## When to Read Detailed Code

| Task | Read Core? |
|------|-----------|
| Add new API endpoint | `api_endpoints.dart` |
| Change business rule | `app_config.dart` |
| Add new color | `app_colors.dart` |
| Add new dependency | `injection.dart` |
| Modify token flow | `auth_interceptor.dart` |
| Add new tab | `nav_tab.dart`, `navigation_cubit.dart` |
| Change theme | `app_theme.dart`, `app_*.dart` files |
| Add image transformation | `cloudinary/transformations/` |
