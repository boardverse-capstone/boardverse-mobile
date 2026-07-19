part of 'navigation_cubit.dart';

class NavigationState extends Equatable {
  /// Default to Home so that freshly-logged-in users land on the dashboard,
  /// not the discovery tab.
  final int currentIndex;

  const NavigationState({
    this.currentIndex = 0,
  });

  NavigationState copyWith({
    int? currentIndex,
  }) {
    return NavigationState(
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  @override
  List<Object?> get props => [
        currentIndex,
      ];
}