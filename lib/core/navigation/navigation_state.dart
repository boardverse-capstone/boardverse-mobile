part of 'navigation_cubit.dart';

class NavigationState extends Equatable {
  final int currentIndex;
  final int lobbyCount;
  final bool hasBookingBadge;
  final bool isPlayingBadge;
  final int friendInviteCount;

  const NavigationState({
    this.currentIndex = 2,
    this.lobbyCount = 0,
    this.hasBookingBadge = false,
    this.isPlayingBadge = false,
    this.friendInviteCount = 0,
  });

  NavigationState copyWith({
    int? currentIndex,
    int? lobbyCount,
    bool? hasBookingBadge,
    bool? isPlayingBadge,
    int? friendInviteCount,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
      lobbyCount: lobbyCount ?? this.lobbyCount,
      hasBookingBadge: hasBookingBadge ?? this.hasBookingBadge,
      isPlayingBadge: isPlayingBadge ?? this.isPlayingBadge,
      friendInviteCount: friendInviteCount ?? this.friendInviteCount,
    );
  }

  @override
  List<Object?> get props => [
        currentIndex,
        lobbyCount,
        hasBookingBadge,
        isPlayingBadge,
        friendInviteCount,
      ];
}
