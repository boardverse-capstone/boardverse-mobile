import 'package:dartz/dartz.dart';

import 'package:boardverse/core/constants/api_endpoints.dart';
import 'package:boardverse/core/error/failures.dart';
import 'package:boardverse/features/friend_management/data/models/friend_privacy_model.dart';
import 'package:boardverse/features/friend_management/data/models/friend_report_model.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';

import '_api_guard_mixin.dart';

/// Phần 3: Friend Privacy + Friend Reports.
///
/// Hai concern này nhỏ và ít được dùng nên gộp chung vào một mixin.
mixin FriendPrivacyAndReportsMixin on ApiGuardMixin {
  // ─── Privacy ───────────────────────────────────────────────────────────

  Future<Either<Failure, FriendPrivacyEntity>> getPrivacySettings() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.friendPrivacy);
      return FriendPrivacyModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  Future<Either<Failure, FriendPrivacyEntity>> updatePrivacySettings({
    bool? isFriendListPublic,
    String? acceptFriendRequestsFrom,
    int? friendLimit,
  }) {
    return guardApiCall(() async {
      final body = <String, dynamic>{};
      if (isFriendListPublic != null) {
        body['isFriendListPublic'] = isFriendListPublic;
      }
      if (acceptFriendRequestsFrom != null) {
        body['acceptFriendRequestsFrom'] = acceptFriendRequestsFrom;
      }
      if (friendLimit != null) body['friendLimit'] = friendLimit;
      final res = await dio.put<Map<String, dynamic>>(
        ApiEndpoints.friendPrivacy,
        data: body,
      );
      return FriendPrivacyModel.fromJson(unwrapEnvelope(res.data)).toEntity();
    });
  }

  // ─── Reports ───────────────────────────────────────────────────────────

  Future<Either<Failure, void>> createReport({
    required String targetUserId,
    required String category,
    required String reason,
  }) {
    return guardApiCall(() async {
      await dio.post<Map<String, dynamic>>(
        ApiEndpoints.friendReports,
        data: {
          'targetUserId': targetUserId,
          'category': category,
          'reason': reason,
        },
      );
    });
  }

  Future<Either<Failure, List<FriendReportEntity>>> getMyReports() {
    return guardApiCall(() async {
      final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.friendReports);
      return parseListEnvelope<FriendReportEntity>(
        res.data,
        FriendReportModel.fromJson,
      );
    });
  }
}
