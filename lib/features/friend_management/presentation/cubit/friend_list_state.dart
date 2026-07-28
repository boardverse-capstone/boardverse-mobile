import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

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
  final List<FriendNoteEntity> notes;
  final FriendPrivacyEntity? privacySettings;
  final List<FriendReportEntity> myReports;

  const FriendListLoaded({
    required this.friends,
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.unreadRequestCount = 0,
    this.notes = const [],
    this.privacySettings,
    this.myReports = const [],
  });

  @override
  List<Object?> get props => [
        friends,
        receivedRequests,
        sentRequests,
        unreadRequestCount,
        notes,
        privacySettings,
        myReports,
      ];

  FriendListLoaded copyWith({
    List<FriendEntity>? friends,
    List<FriendRequestEntity>? receivedRequests,
    List<FriendRequestEntity>? sentRequests,
    int? unreadRequestCount,
    List<FriendNoteEntity>? notes,
    FriendPrivacyEntity? privacySettings,
    List<FriendReportEntity>? myReports,
  }) {
    return FriendListLoaded(
      friends: friends ?? this.friends,
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      unreadRequestCount: unreadRequestCount ?? this.unreadRequestCount,
      notes: notes ?? this.notes,
      privacySettings: privacySettings ?? this.privacySettings,
      myReports: myReports ?? this.myReports,
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

// ─── Note States ──────────────────────────────────────────────────────────────

class FriendNoteSaved extends FriendListState {
  final FriendNoteEntity note;

  const FriendNoteSaved(this.note);

  @override
  List<Object?> get props => [note];
}

class FriendNoteDeleted extends FriendListState {
  final String noteId;

  const FriendNoteDeleted(this.noteId);

  @override
  List<Object?> get props => [noteId];
}

// ─── Privacy States ───────────────────────────────────────────────────────────

class FriendPrivacyUpdated extends FriendListState {
  final FriendPrivacyEntity privacy;

  const FriendPrivacyUpdated(this.privacy);

  @override
  List<Object?> get props => [privacy];
}

// ─── Report States ────────────────────────────────────────────────────────────

class FriendReportCreated extends FriendListState {
  final String targetUserId;

  const FriendReportCreated(this.targetUserId);

  @override
  List<Object?> get props => [targetUserId];
}
