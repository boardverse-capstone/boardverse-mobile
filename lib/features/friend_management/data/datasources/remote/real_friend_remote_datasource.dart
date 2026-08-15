import 'package:dio/dio.dart';

import 'package:boardverse/features/friend_management/data/datasources/base/friend_remote_datasource.dart';

import '_api_guard_mixin.dart';
import '_friend_datasource_friends.dart';
import '_friend_datasource_notes.dart';
import '_friend_datasource_privacy_reports.dart';

/// Triển khai [FriendRemoteDatasource] gọi real backend.
///
/// Trước đây file này ~510 dòng với toàn bộ method + try/catch DioException +
/// error mapping inline. Đã refactor:
/// - `_api_guard_mixin.dart`: cung cấp `guardApiCall` + `mapDioError`
///   + `parseListEnvelope` + `unwrapEnvelope`.
/// - `_friend_datasource_friends.dart`: friends + requests + search/suggestions.
/// - `_friend_datasource_notes.dart`: friend notes.
/// - `_friend_datasource_privacy_reports.dart`: privacy + reports.
///
/// Class này chỉ cần compose các mixin với nhau — không chứa logic nào.
class RealFriendRemoteDatasource extends ApiGuardMixin
    with
        FriendsAndRequestsMixin,
        FriendNotesMixin,
        FriendPrivacyAndReportsMixin
    implements
        FriendRemoteDatasource {
  RealFriendRemoteDatasource({required this.dio});

  @override
  final Dio dio;
}
