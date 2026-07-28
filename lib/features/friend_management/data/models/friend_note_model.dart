import '../../domain/entities/entities.dart';
import 'enum_parsing.dart';

/// Model cho [FriendNoteEntity] — ghi chú cá nhân của current user về friend.
class FriendNoteModel {
  const FriendNoteModel({
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

  factory FriendNoteModel.fromJson(Map<String, dynamic> json) {
    return FriendNoteModel(
      noteId: (json['noteId'] ?? json['id'] ?? '').toString(),
      friendUserId: (json['friendUserId'] ?? json['userId'] ?? '').toString(),
      alias: (json['alias'] ?? '').toString(),
      note: json['note'] as String?,
      tags: parseStringList(json['tags']),
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: parseDateTime(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alias': alias,
      if (note != null) 'note': note,
      if (tags != null) 'tags': tags!.join(','),
    };
  }

  FriendNoteEntity toEntity() => FriendNoteEntity(
        noteId: noteId,
        friendUserId: friendUserId,
        alias: alias,
        note: note,
        tags: tags,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
