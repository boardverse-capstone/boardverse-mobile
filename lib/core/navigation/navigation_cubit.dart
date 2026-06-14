import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'navigation_state.dart';

class NavigationCubit extends Cubit<NavigationState> {
  NavigationCubit() : super(const NavigationState());

  void setTab(int index) => emit(state.copyWith(currentIndex: index));

  void resetToDiscovery() => emit(state.copyWith(currentIndex: 0));

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
