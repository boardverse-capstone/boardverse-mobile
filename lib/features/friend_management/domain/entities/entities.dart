/// Barrel file — export tất cả entities của friend_management để các feature
/// khác (lobby, profile, ...) chỉ cần import một file.
///
/// Nếu sau này muốn refactor sang sub-package riêng, chỉ cần đổi đường dẫn
/// ở đây, các file consumer không phải sửa.
library;

export 'friend_entity.dart';
export 'friend_note_entity.dart';
export 'friend_privacy_entity.dart';
export 'friend_profile_entity.dart';
export 'friend_report_entity.dart';
export 'friend_request_entity.dart';
export 'friend_search_entity.dart';
