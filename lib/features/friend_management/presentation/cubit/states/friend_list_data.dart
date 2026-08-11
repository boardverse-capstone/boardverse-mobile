import 'package:equatable/equatable.dart';

import '../../../domain/entities/entities.dart';

/// Base state for friend list management.
///
/// Contains common data shared across different states.
///
/// Lưu ý về per-section error:
/// - `friendsError` / `receivedRequestsError` lưu thông báo lỗi của
///   từng section độc lập. Khi một section fail nhưng section khác đã
///   load thành công trước đó, ta vẫn giữ nguyên dữ liệu đã load (không
///   emit `FriendListError` tổng) để tránh mất dữ liệu khi user chuyển tab.
/// - UI mỗi tab sẽ tự kiểm tra `friendsError` / `receivedRequestsError`
///   để hiển thị ErrorRetryView tương ứng mà vẫn giữ nguyên dữ liệu cũ.
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
    this.friendsError,
    this.receivedRequestsError,
    this.friendsEverLoaded = false,
    this.receivedRequestsEverLoaded = false,
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

  /// Lỗi của section "Bạn bè" — null nếu OK hoặc chưa từng load.
  final String? friendsError;

  /// Lỗi của section "Lời mời" — null nếu OK hoặc chưa từng load.
  final String? receivedRequestsError;

  /// Section "Bạn bè" đã từng load thành công ít nhất một lần.
  /// Dùng để phân biệt "empty thật" với "chưa load" / "lỗi".
  final bool friendsEverLoaded;

  /// Section "Lời mời" đã từng load thành công ít nhất một lần.
  final bool receivedRequestsEverLoaded;

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
        friendsError,
        receivedRequestsError,
        friendsEverLoaded,
        receivedRequestsEverLoaded,
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
    Object? friendsError = friendListErrorSentinel,
    Object? receivedRequestsError = friendListErrorSentinel,
    bool? friendsEverLoaded,
    bool? receivedRequestsEverLoaded,
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
      friendsError: identical(friendsError, friendListErrorSentinel)
          ? this.friendsError
          : friendsError as String?,
      receivedRequestsError: identical(receivedRequestsError, friendListErrorSentinel)
          ? this.receivedRequestsError
          : receivedRequestsError as String?,
      friendsEverLoaded: friendsEverLoaded ?? this.friendsEverLoaded,
      receivedRequestsEverLoaded:
          receivedRequestsEverLoaded ?? this.receivedRequestsEverLoaded,
    );
  }
}

/// Sentinel object để phân biệt "không truyền" với "truyền null"
/// cho các field error trên cả `FriendListData.copyWith` và override
/// `FriendListLoaded.copyWith`. Đặt ở library-level để các file khác
/// trong cùng package có thể truy cập (tránh duplicate sentinel).
const Object friendListErrorSentinel = Object();
