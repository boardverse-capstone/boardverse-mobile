import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_tab.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  /// Switches the active tab. Out-of-range indices are clamped (not rejected)
  /// so a transient bounce-back from the PageView never leaves the nav bar
  /// in a "nothing is selected" state.
  void setTab(int index) {
    final clamped = index.clamp(0, NavTab.values.length - 1);
    if (clamped == state.currentIndex) return;
    emit(state.copyWith(currentIndex: clamped));
  }

  void setTabFromEnum(NavTab tab) => setTab(tab.tabIndex);

  void goHome() => setTab(NavTab.home.tabIndex);
}