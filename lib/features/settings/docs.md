# Settings Feature Module

## Overview

Module quản lý cài đặt ứng dụng. Hiện tại chỉ chứa theme management (light/dark/system mode). Đây là module nhỏ, tập trung vào single responsibility.

**Tổng số file**: 3 files

---

## 1. Architecture

```
lib/features/settings/
└── presentation/
    ├── cubit/
    │   ├── theme_cubit.dart
    │   └── theme_state.dart
    └── widgets/
        └── theme_switcher_sheet.dart
```

**Note**: Module này KHÔNG có domain/data layers vì theme preference là local storage concern thuần túy.

---

## 2. Key Classes

### ThemeState

```dart
class ThemeState extends Equatable {
  final ThemeMode mode;

  const ThemeState({this.mode = ThemeMode.system});

  ThemeState copyWith({ThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }

  @override
  List<Object?> get props => [mode];
}
```

### ThemeCubit

```dart
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required ThemePreferencesService preferences})
      : _preferences = preferences,
        super(const ThemeState());

  final ThemePreferencesService _preferences;

  Future<void> load() async { ... }
  void setLight() => _setMode(ThemeMode.light);
  void setDark()  => _setMode(ThemeMode.dark);
  void setSystem()=> _setMode(ThemeMode.system);
  void toggle(Brightness platformBrightness) { ... }
  void _setMode(ThemeMode mode) { ... }
}
```

**Toggle Logic:**
```dart
void toggle(Brightness platformBrightness) {
  final current = state.mode;
  final next = switch (current) {
    ThemeMode.light => ThemeMode.dark,
    ThemeMode.dark  => ThemeMode.light,
    ThemeMode.system =>
      platformBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
  };
  _setMode(next);
}
```

### ThemePreferencesService (Core)

**Location**: `lib/core/services/storage/theme_preferences_service.dart`

```dart
class ThemePreferencesService {
  // Key: 'theme_mode'
  // Values: 'light', 'dark', 'system'
  
  Future<ThemeMode> loadMode() async { ... }
  ThemeMode get defaultMode => ThemeMode.system;
  Future<void> saveMode(ThemeMode mode) async { ... }
}
```

### ThemeSwitcherSheet

```dart
class ThemeSwitcherSheet extends StatelessWidget {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => BlocProvider.value(
        value: context.read<ThemeCubit>(),
        child: const ThemeSwitcherSheet(),
      ),
    );
  }
  ...
}
```

---

## 3. Business Logic Flow

### App Startup Flow

```
main() → setupDependencies()
       → BoardVerseApp builds
       → BlocProvider<ThemeCubit>(..load())
       → BlocBuilder<ThemeCubit> reads ThemeState.mode
       → MaterialApp.themeMode = state.mode
       → Flutter applies light/dark/system theme
```

### User Changes Theme

```
User taps theme option in ThemeSwitcherSheet
  → context.read<ThemeCubit>().setLight/Dark/System()
    → _setMode(mode)
      → ThemePreferencesService.saveMode(mode)   [persists]
      → emit(state.copyWith(mode: mode))         [emits new state]
        → BlocBuilder rebuilds
          → MaterialApp.themeMode = state.mode
            → Flutter re-paints entire app with new theme
```

---

## 4. Dependency Injection

**Registration** (`lib/core/di/injection.dart`):

```dart
sl.registerLazySingleton<ThemePreferencesService>(
  () => ThemePreferencesService(storage: sl<FlutterSecureStorage>()),
);

sl.registerLazySingleton<ThemeCubit>(
  () => ThemeCubit(preferences: sl<ThemePreferencesService>()),
);
```

**Initialization** (`main.dart`):

```dart
BlocProvider<ThemeCubit>(
  create: (_) => sl<ThemeCubit>()..load()
)
```

---

## 5. Usage

### Show Theme Switcher

```dart
ThemeSwitcherSheet.show(context);
```

### Read Current Theme

```dart
final mode = context.read<ThemeCubit>().state.mode;
```

### Toggle Programmatically

```dart
final brightness = MediaQuery.platformBrightnessOf(context);
context.read<ThemeCubit>().toggle(brightness);
```

### React to Theme Changes

```dart
BlocBuilder<ThemeCubit, ThemeState>(
  builder: (context, state) {
    // state.mode is ThemeMode.light / dark / system
    return YourWidget();
  },
)
```

---

## 6. Quick Reference

| Task | File |
|------|------|
| Change storage mechanism | `ThemePreferencesService` in core |
| Add new theme option | `ThemeSwitcherSheet` |
| Modify toggle logic | `ThemeCubit.toggle()` |
