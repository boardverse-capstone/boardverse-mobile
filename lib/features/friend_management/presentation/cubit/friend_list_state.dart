import 'package:equatable/equatable.dart';

import '../../domain/entities/friend_entity.dart';

abstract class FriendListState extends Equatable {
  const FriendListState();

  @override
  List<Object?> get props => [];
}

class FriendListInitial extends FriendListState {
  const FriendListInitial();
}

class FriendListLoading extends FriendListState {
  const FriendListLoading();
}

class FriendListLoaded extends FriendListState {
  final List<FriendEntity> friends;
  final List<FriendRequestEntity> receivedRequests;
  final List<FriendRequestEntity> sentRequests;
  final int unreadRequestCount;

  const FriendListLoaded({
    required this.friends,
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.unreadRequestCount = 0,
  });

  @override
  List<Object?> get props => [
        friends,
        receivedRequests,
        sentRequests,
        unreadRequestCount,
      ];

  FriendListLoaded copyWith({
    List<FriendEntity>? friends,
    List<FriendRequestEntity>? receivedRequests,
    List<FriendRequestEntity>? sentRequests,
    int? unreadRequestCount,
  }) {
    return FriendListLoaded(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      unreadRequestCount: unreadRequestCount ?? this.unreadRequestCount,
    );
  }
}

class FriendListError extends FriendListState {
  final String message;

  const FriendListError(this.message);

  @override
  List<Object?> get props => [message];
}

class FriendRequestSent extends FriendListState {
  final String addresseeId;

  const FriendRequestSent(this.addresseeId);

  @override
  List<Object?> get props => [addresseeId];
}

class FriendRequestProcessed extends FriendListState {
  final String requestId;
  final bool accepted;

  const FriendRequestProcessed({required this.requestId, required this.accepted});

  @override
  List<Object?> get props => [requestId, accepted];
}

class FriendUnfriended extends FriendListState {
  final String friendId;

  const FriendUnfriended(this.friendId);

  @override
  List<Object?> get props => [friendId];
}
