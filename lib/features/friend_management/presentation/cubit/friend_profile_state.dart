import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// Trạng thái của màn hình Friend Profile (xem chi tiết 1 player).
///
/// **Quan trọng:** mọi state đều mang `userId` để UI/retry/action luôn biết
/// đang thao tác trên profile của ai — kể cả khi `profile == null` (vd
/// lỗi load lần đầu, chưa từng load thành công). Tránh truyền empty
/// `userId` xuống các API endpoint yêu cầu path param (`/friends/{userId}/...`).
abstract class FriendProfileState extends Equatable {
  const FriendProfileState({required this.userId});

  /// ID của player mà state này đang đại diện. Đặt từ lúc
  /// `loadProfile(userId)` được gọi, tồn tại xuyên suốt lifecycle của
  /// cubit cho đến khi dispose.
  final String userId;

  @override
  List<Object?> get props => [userId];
}

class FriendProfileInitial extends FriendProfileState {
  const FriendProfileInitial({required super.userId});
}

class FriendProfileLoading extends FriendProfileState {
  const FriendProfileLoading({required super.userId});
}

class FriendProfileLoaded extends FriendProfileState {
  const FriendProfileLoaded({
    required super.userId,
    required this.profile,
    this.isMutating = false,
    this.mutualFriends,
    this.actionMessage,
  });

  final FriendProfileEntity profile;

  /// `true` khi đang thực hiện action (gửi request / unfriend / block / mở
  /// khóa / report) — UI dùng để disable button + show snackbar.
  final bool isMutating;

  /// Override danh sách mutual friends khi người dùng mở rộng "Xem thêm".
  /// Mặc định lấy từ [profile.mutualFriends]; list ở đây dài hơn sau khi
  /// Cubit gọi thêm `getMutualFriends`.
  final List<MutualFriendSummary>? mutualFriends;

  /// Snackbar message transient (vd: "Đã gửi lời mời"). UI flush sau khi xử lý.
  final String? actionMessage;

  List<MutualFriendSummary> get effectiveMutualFriends =>
      mutualFriends ?? profile.mutualFriends;

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
      actionMessage: clearActionMessage
          ? null
          : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        profile,
        isMutating,
        mutualFriends,
        actionMessage,
      ];
}

class FriendProfileError extends FriendProfileState {
  const FriendProfileError({
    required super.userId,
    required this.message,
    this.profile,
  });

  final String message;

  /// Có thể giữ lại profile cũ nếu action phụ (block/unfriend) fail.
  final FriendProfileEntity? profile;

  @override
  List<Object?> get props => [userId, message, profile];
}
