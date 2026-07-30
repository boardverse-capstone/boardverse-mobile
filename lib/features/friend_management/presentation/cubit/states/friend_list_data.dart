import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

/// Base state for friend list management.
///
/// Contains common data shared across different states.
class FriendListData extends Equatable {
  const FriendListData({
    this.friends = const [],
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.unreadRequestCount = 0,
    this.notes = const [],
    this.privacySettings,
    this.myReports = const [],
    this.friendsLoading = false,
    this.receivedRequestsLoading = false,
  });

  final List<FriendEntity> friends;
  final List<FriendRequestEntity> receivedRequests;
  final List<FriendRequestEntity> sentRequests;
  final int unreadRequestCount;
  final List<FriendNoteEntity> notes;
  final FriendPrivacyEntity? privacySettings;
  final List<FriendReportEntity> myReports;
  final bool friendsLoading;
  final bool receivedRequestsLoading;

  @override
  List<Object?> get props => [
        friends,
        receivedRequests,
        sentRequests,
        unreadRequestCount,
        notes,
        privacySettings,
        myReports,
        friendsLoading,
        receivedRequestsLoading,
      ];

  FriendListData copyWith({
    List<FriendEntity>? friends,
    List<FriendRequestEntity>? receivedRequests,
    List<FriendRequestEntity>? sentRequests,
    int? unreadRequestCount,
    List<FriendNoteEntity>? notes,
    FriendPrivacyEntity? privacySettings,
    List<FriendReportEntity>? myReports,
    bool? friendsLoading,
    bool? receivedRequestsLoading,
  }) {
    return FriendListData(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      unreadRequestCount: unreadRequestCount ?? this.unreadRequestCount,
      notes: notes ?? this.notes,
      privacySettings: privacySettings ?? this.privacySettings,
      myReports: myReports ?? this.myReports,
      friendsLoading: friendsLoading ?? this.friendsLoading,
      receivedRequestsLoading:
          receivedRequestsLoading ?? this.receivedRequestsLoading,
    );
  }
}
