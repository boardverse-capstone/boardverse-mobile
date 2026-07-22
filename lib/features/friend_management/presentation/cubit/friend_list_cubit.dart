import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/friend_repository.dart';
import 'friend_list_state.dart';

class FriendListCubit extends Cubit<FriendListState> {
  FriendListCubit({required this._repository}) : super(const FriendListInitial());

  final FriendRepository _repository;

  Future<void> loadFriends() async {
    emit(const FriendListLoading());

    final friendsResult = await _repository.getFriendsWithActivity();
    final receivedResult = await _repository.getReceivedRequests();
    final sentResult = await _repository.getSentRequests();

    final friends = friendsResult.fold(
      (failure) => <dynamic>[],
      (data) => data,
    );

    final received = receivedResult.fold(
      (failure) => <dynamic>[],
      (data) => data,
    );

    final sent = sentResult.fold(
      (failure) => <dynamic>[],
      (data) => data,
    );

    final unreadCount = received.where((r) => !r.isRead).length;

    emit(FriendListLoaded(
      friends: List.from(friends),
      receivedRequests: List.from(received),
      sentRequests: List.from(sent),
      unreadRequestCount: unreadCount,
    ));
  }

  Future<void> refreshFriends() async {
    await loadFriends();
  }

  Future<void> sendFriendRequest({
    required String addresseeId,
    String? message,
  }) async {
    final currentState = state;
    final result = await _repository.sendFriendRequest(
      addresseeId: addresseeId,
      message: message,
    );

    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (request) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            sentRequests: [...currentState.sentRequests, request],
          ));
        } else {
          emit(FriendRequestSent(addresseeId));
        }
      },
    );
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final currentState = state;
    final result = await _repository.acceptFriendRequest(requestId);

    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (updated) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(requestId: requestId, accepted: true));
        }
      },
    );
  }

  Future<void> declineFriendRequest(String requestId) async {
    final currentState = state;
    final result = await _repository.declineFriendRequest(requestId);

    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (updated) {
        if (currentState is FriendListLoaded) {
          final newReceived = currentState.receivedRequests
              .where((r) => r.requestId != requestId)
              .toList();
          emit(currentState.copyWith(
            receivedRequests: newReceived,
            unreadRequestCount: newReceived.where((r) => !r.isRead).length,
          ));
        } else {
          emit(FriendRequestProcessed(requestId: requestId, accepted: false));
        }
      },
    );
  }

  Future<void> unfriend(String friendId) async {
    final currentState = state;
    final result = await _repository.unfriend(friendId);

    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (_) {
        if (currentState is FriendListLoaded) {
          emit(currentState.copyWith(
            friends: currentState.friends
                .where((f) => f.odId != friendId)
                .toList(),
          ));
        } else {
          emit(FriendUnfriended(friendId));
        }
      },
    );
  }

  Future<void> blockUser(String userId) async {
    final result = await _repository.blockUser(userId);

    result.fold(
      (failure) => emit(FriendListError(failure.message)),
      (_) => loadFriends(),
    );
  }

  Future<void> markRequestAsRead(String requestId) async {
    await _repository.markRequestAsRead(requestId);

    final currentState = state;
    if (currentState is FriendListLoaded) {
      final updated = currentState.receivedRequests.map((r) {
        if (r.requestId == requestId && !r.isRead) {
          return r;
        }
        return r;
      }).toList();
      emit(currentState.copyWith(
        receivedRequests: updated,
        unreadRequestCount: updated.where((r) => !r.isRead).length,
      ));
    }
  }
}
