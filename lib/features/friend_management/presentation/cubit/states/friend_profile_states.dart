import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

/// Base state for friend profile management.
///
/// All states include userId to identify which profile is being viewed.
abstract class FriendProfileState extends Equatable {
  const FriendProfileState({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Initial state before profile is loaded.
class FriendProfileInitial extends FriendProfileState {
  const FriendProfileInitial({required super.userId});
}

/// Loading state while fetching profile.
class FriendProfileLoading extends FriendProfileState {
  const FriendProfileLoading({required super.userId});
}

/// Loaded state containing full profile data.
class FriendProfileLoaded extends FriendProfileState {
  const FriendProfileLoaded({
    required super.userId,
    required this.profile,
    this.isMutating = false,
    this.mutualFriends,
    this.actionMessage,
  });

  final FriendProfileEntity profile;

  /// `true` when an action (send request / unfriend / block / unblock / report)
  /// is in progress — UI uses this to disable buttons and show loading state.
  final bool isMutating;

  /// Override list of mutual friends when user expands "View more".
  final List<MutualFriendSummary>? mutualFriends;

  /// Transient snackbar message (e.g. "Đã gửi lời mời").
  final String? actionMessage;

  List<MutualFriendSummary> get effectiveMutualFriends =>
      mutualFriends ?? profile.mutualFriends;

  @override
  List<Object?> get props => [
        userId,
        profile,
        isMutating,
        mutualFriends,
        actionMessage,
      ];

  FriendProfileLoaded copyWith({
    FriendProfileEntity? profile,
    bool? isMutating,
    List<MutualFriendSummary>? mutualFriends,
    String? actionMessage,
    bool clearActionMessage = false,
  }) {
    return FriendProfileLoaded(
      userId: userId,
      profile: profile ?? this.profile,
      isMutating: isMutating ?? this.isMutating,
      mutualFriends: mutualFriends ?? this.mutualFriends,
      actionMessage:
          clearActionMessage ? null : (actionMessage ?? this.actionMessage),
    );
  }
}

/// Error state when profile loading fails.
class FriendProfileError extends FriendProfileState {
  const FriendProfileError({
    required super.userId,
    required this.message,
    this.profile,
  });

  final String message;

  /// Previous profile data if available (e.g. when action fails mid-load).
  final FriendProfileEntity? profile;

  @override
  List<Object?> get props => [userId, message, profile];
}
