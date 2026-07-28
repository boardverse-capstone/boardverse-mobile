import 'package:equatable/equatable.dart';

/// Ghi chú cá nhân mà current user viết về một friend.
///
/// Dùng để gắn alias (tên thân mật), ghi chú và tags cho friend — phục vụ UX
/// khi danh sách bạn dài. Mỗi `(OwnerUserId, FriendUserId)` chỉ có 1 note
/// (BR-FRIEND-NOTE-01).
class FriendNoteEntity extends Equatable {
  const FriendNoteEntity({
    required this.noteId,
    required this.friendUserId,
    required this.alias,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.tags,
  });

  final String noteId;
  final String friendUserId;
  final String alias;
  final String? note;
  final List<String>? tags;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
        noteId,
        friendUserId,
        alias,
        note,
        tags,
        createdAt,
        updatedAt,
      ];
}
