import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'nav_tab.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  void setTab(int index) =>
      emit(state.copyWith(currentIndex: index));

  void setTabFromEnum(NavTab tab) => setTab(tab.tabIndex);

  void resetToDiscovery() => emit(state.copyWith(currentIndex: NavTab.discovery.tabIndex));

  void goHome() => emit(state.copyWith(currentIndex: NavTab.home.tabIndex));

  void updateLobbyCount(int count) =>
      emit(state.copyWith(lobbyCount: count));

  void updateBookingBadge({bool hasDepositPending = false, bool isPlaying = false}) =>
      emit(state.copyWith(
        hasBookingBadge: hasDepositPending,
        isPlayingBadge: isPlaying,
      ));

  void updateFriendInvites(int count) =>
      emit(state.copyWith(friendInviteCount: count));
}
