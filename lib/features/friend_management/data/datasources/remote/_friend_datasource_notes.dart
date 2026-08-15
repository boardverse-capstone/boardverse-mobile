import 'package:dartz/dartz.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/data/models/friend_note_model.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';

import '_api_guard_mixin.dart';

/// Phần 2: Friend Notes (`GET/PUT/DELETE /notes`).
///
/// Friend note là ghi chú cá nhân của current user về một friend — alias,
/// tags, mô tả. Không liên quan tới quan hệ bạn bè (Friendship) nên tách
/// riêng cho rõ ràng.
mixin FriendNotesMixin on ApiGuardMixin {
  Future<Either<Failure, List<FriendNoteEntity>>> getAllNotes() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.friendNotes);
      return parseListEnvelope<FriendNoteEntity>(
        res.data,
        FriendNoteModel.fromJson,
      );
    });
  }

  Future<Either<Failure, FriendNoteEntity>> upsertNote({
    required String friendUserId,
    required String alias,
    String? note,
    List<String>? tags,
  }) {
    return guardApiCall(() async {
      final body = <String, dynamic>{'alias': alias};
      if (note != null && note.isNotEmpty) body['note'] = note;
      if (tags != null && tags.isNotEmpty) body['tags'] = tags.join(',');
      final res = await dio.put<Map<String, dynamic>>(
        ApiEndpoints.friendNoteUpdate(friendUserId),
        data: body,
      );
      return FriendNoteModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, void>> deleteNote(String noteId) {
    return guardApiCall(() async {
      await dio.delete(ApiEndpoints.friendNoteDelete(noteId));
    });
  }
}
