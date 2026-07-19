import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'theme_state.dart';
import '../../../../core/services/storage/theme_preferences_service.dart';

export 'theme_state.dart';

/// Cubit quản lý [ThemeMode] hiện tại của ứng dụng.
///
/// - Khởi tạo với [ThemeMode.system] mặc định và sau đó [load] sẽ đọc
///   preference đã lưu để cập nhật state.
/// - Cung cấp các hàm [setLight], [setDark], [setSystem] để chuyển đổi.
/// - Mỗi lần thay đổi sẽ được persist xuống local storage.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit({required ThemePreferencesService preferences})
      // ignore: prefer_initializing_formals
      : _preferences = preferences,
        super(const ThemeState());

  final ThemePreferencesService _preferences;

  /// Đọc preference đã lưu và cập nhật state.
  Future<void> load() async {
    final mode = await _preferences.loadMode();
    if (isClosed) return;
    if (mode != state.mode) {
      emit(state.copyWith(mode: mode));
    }
  }

  void setLight() => _setMode(ThemeMode.light);
  void setDark() => _setMode(ThemeMode.dark);
  void setSystem() => _setMode(ThemeMode.system);

  /// Toggle giữa light/dark. Khi đang ở [ThemeMode.system] sẽ chuyển sang
  /// light nếu nền tảng đang sáng, ngược lại chuyển sang dark.
  void toggle(Brightness platformBrightness) {
    final current = state.mode;
    final next = switch (current) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system =>
        platformBrightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark,
    };
    _setMode(next);
  }

  void _setMode(ThemeMode mode) {
    if (mode == state.mode) return;
    _preferences.saveMode(mode);
    emit(state.copyWith(mode: mode));
  }
}