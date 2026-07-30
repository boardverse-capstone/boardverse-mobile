import '../../../domain/entities/entities.dart';
import 'friend_list_data.dart';

/// Initial state before any data is loaded.
class FriendListInitial extends FriendListData {
  const FriendListInitial() : super();
}

/// Loading state while fetching initial data.
class FriendListLoading extends FriendListData {
  const FriendListLoading() : super();
}

/// Loaded state containing all friend list data.
class FriendListLoaded extends FriendListData {
  const FriendListLoaded({
    super.friends,
    super.receivedRequests,
    super.sentRequests,
    super.unreadRequestCount,
    super.notes,
    super.privacySettings,
    super.myReports,
    super.friendsLoading,
    super.receivedRequestsLoading,
  });
}

/// Error state when data fetching fails.
class FriendListError extends FriendListData {
  const FriendListError({required this.message}) : super();

  final String message;

  @override
  List<Object?> get props => [...super.props, message];
}

// ─── Action Result States ─────────────────────────────────────────────────────

/// State emitted after successfully sending a friend request.
class FriendRequestSent extends FriendListData {
  const FriendRequestSent({required this.addresseeId}) : super();

  final String addresseeId;

  @override
  List<Object?> get props => [...super.props, addresseeId];
}

/// State emitted after accepting or declining a friend request.
class FriendRequestProcessed extends FriendListData {
  const FriendRequestProcessed({
    required this.requestId,
    required this.accepted,
  }) : super();

  final String requestId;
  final bool accepted;

  @override
  List<Object?> get props => [...super.props, requestId, accepted];
}

/// State emitted after unfriending someone.
class FriendUnfriended extends FriendListData {
  const FriendUnfriended({required this.friendId}) : super();

  final String friendId;

  @override
  List<Object?> get props => [...super.props, friendId];
}

/// State emitted after saving a friend note.
class FriendNoteSaved extends FriendListData {
  const FriendNoteSaved({required this.note}) : super();

  final FriendNoteEntity note;

  @override
  List<Object?> get props => [...super.props, note];
}

/// State emitted after deleting a friend note.
class FriendNoteDeleted extends FriendListData {
  const FriendNoteDeleted({required this.noteId}) : super();

  final String noteId;

  @override
  List<Object?> get props => [...super.props, noteId];
}

/// State emitted after updating privacy settings.
class FriendPrivacyUpdated extends FriendListData {
  const FriendPrivacyUpdated({required this.privacy}) : super();

  final FriendPrivacyEntity privacy;

  @override
  List<Object?> get props => [...super.props, privacy];
}

/// State emitted after creating a report.
class FriendReportCreated extends FriendListData {
  const FriendReportCreated({required this.targetUserId}) : super();

  final String targetUserId;

  @override
  List<Object?> get props => [...super.props, targetUserId];
}
