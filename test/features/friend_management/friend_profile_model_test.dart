import 'package:boardverse_mobile/features/friend_management/data/models/friend_profile_model.dart';
import 'package:boardverse_mobile/features/friend_management/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests cho [FriendProfileModel.fromJson] — verify parse đúng schema
/// `PlayerProfileDto` thực tế từ backend `GET /api/v1/friends/{userId}/profile`.
///
/// **Schema thực tế** (verified 2026-07-29 từ console log):
/// ```json
/// {
///   "statusCode": 200,
///   "message": "...",
///   "data": {
///     "userId": "092bbcf3-...",
///     "username": "jonny",
///     "avatarUrl": null,
///     "globalElo": 1200,
///     "karmaPoints": 100,
///     "gamerTier": "Bronze",
///     "level": 1,
///     "mutualFriendsCount": 0,
///     "relationship": {
///       "status": "PendingReceived",
///       "friendshipId": "762b3368-...",
///       "isRequester": false,
///       "friendsSince": null,
///       "message": null
///     },
///     "canSendFriendRequest": false,
///     "canReport": false
///   }
/// }
/// ```
void main() {
  group('FriendProfileModel.fromJson', () {
    test('parses schema thực tế với envelope wrapper + relationship nested',
        () {
      // JSON thực tế từ backend `/api/v1/friends/{userId}/profile` — đã verify
      // qua console log.
      final json = {
        'userId': '092bbcf3-e729-43b5-8913-898961babc99',
        'username': 'jonny',
        'avatarUrl': null,
        'avatarBorderUrl': null,
        'bio': 'player friendly',
        'firstName': 'jonny',
        'lastName': 'tran',
        'globalElo': 1200,
        'karmaPoints': 100,
        'gamerTier': 'Bronze',
        'level': 1,
        'friendsCount': 0,
        'mutualFriendsCount': 0,
        'activityStatus': 'Offline',
        'lastActiveAt': null,
        'joinedAt': '2026-06-06T02:52:28.920457Z',
        'relationship': {
          'status': 'PendingReceived',
          'friendshipId': '762b3368-d8ef-4084-ab31-e6be6d32dc4d',
          'isRequester': false,
          'friendsSince': null,
          'message': null,
        },
        'canSendFriendRequest': false,
        'canReport': false,
      };

      final m = FriendProfileModel.fromJson(json);

      expect(m.userId, '092bbcf3-e729-43b5-8913-898961babc99');
      expect(m.username, 'jonny');
      expect(m.avatarUrl, ''); // null → empty string
      expect(m.bio, 'player friendly');
      expect(m.karmaPoints, 100);
      expect(m.gamerTier, GamerTier.bronze);
      expect(m.globalElo, 1200);
      expect(m.level, 1);
      expect(m.mutualFriendsCount, 0);
      expect(m.friendshipStatus, FriendshipStatus.pendingReceived);
      expect(m.friendsSince, isNull);
      expect(m.isBlockedByMe, isFalse);
      expect(m.hasBlockedMe, isFalse);
      expect(m.canSendFriendRequest, isFalse);
      expect(m.canReport, isFalse);
    });

    test('parses friendshipStatus ở top-level (schema cũ)', () {
      // Backend cũ có thể trả `friendshipStatus` top-level thay vì
      // `relationship.status` nested. Model vẫn parse được để tương thích.
      final json = {
        'userId': 'u1',
        'username': 'alice',
        'avatarUrl': 'https://cdn/alice.png',
        'karmaPoints': 50,
        'globalElo': 1100,
        'level': 2,
        'mutualFriendsCount': 3,
        'friendshipStatus': 'Accepted',
        'friendsSince': '2025-12-01T10:00:00Z',
        'isBlockedByMe': false,
        'hasBlockedMe': false,
        'canSendFriendRequest': false,
        'canReport': true,
      };

      final m = FriendProfileModel.fromJson(json);

      expect(m.username, 'alice');
      expect(m.avatarUrl, 'https://cdn/alice.png');
      expect(m.friendshipStatus, FriendshipStatus.accepted);
      expect(m.friendsSince, isNotNull);
      expect(m.canReport, isTrue);
    });

    test('parses "None" relationship.status → FriendshipStatus.none', () {
      final json = {
        'userId': 'u1',
        'username': 'stranger',
        'globalElo': 0,
        'karmaPoints': 0,
        'level': 1,
        'mutualFriendsCount': 0,
        'relationship': {'status': 'None'},
        'canSendFriendRequest': true,
        'canReport': false,
      };

      final m = FriendProfileModel.fromJson(json);
      expect(m.friendshipStatus, FriendshipStatus.none);
    });

    test('parses "BlockedByMe" → FriendshipStatus.blocked + isBlockedByMe=true',
        () {
      final json = {
        'userId': 'u1',
        'username': 'blocked-person',
        'globalElo': 0,
        'karmaPoints': 0,
        'level': 1,
        'mutualFriendsCount': 0,
        'relationship': {'status': 'BlockedByMe'},
        'canSendFriendRequest': false,
        'canReport': false,
      };

      final m = FriendProfileModel.fromJson(json);
      expect(m.friendshipStatus, FriendshipStatus.blocked);
      expect(m.isBlockedByMe, isTrue);
      expect(m.hasBlockedMe, isFalse);
    });

    test('parses "BlockedByThem" → FriendshipStatus.blocked + hasBlockedMe=true',
        () {
      final json = {
        'userId': 'u1',
        'username': 'blocker',
        'globalElo': 0,
        'karmaPoints': 0,
        'level': 1,
        'mutualFriendsCount': 0,
        'relationship': {'status': 'BlockedByThem'},
        'canSendFriendRequest': false,
        'canReport': false,
      };

      final m = FriendProfileModel.fromJson(json);
      expect(m.friendshipStatus, FriendshipStatus.blocked);
      expect(m.isBlockedByMe, isFalse);
      expect(m.hasBlockedMe, isTrue);
    });

    test('parses alias cũ "Pending" → pendingSent (back-compat)', () {
      final json = {
        'userId': 'u1',
        'username': 'pending',
        'globalElo': 0,
        'karmaPoints': 0,
        'level': 1,
        'mutualFriendsCount': 0,
        'relationship': {'status': 'Pending'},
        'canSendFriendRequest': false,
        'canReport': false,
      };

      final m = FriendProfileModel.fromJson(json);
      expect(m.friendshipStatus, FriendshipStatus.pendingSent);
    });

    test('toEntity giữ nguyên data', () {
      final json = {
        'userId': 'u1',
        'username': 'dave',
        'avatarUrl': 'https://cdn/dave.png',
        'bio': 'Hi',
        'karmaPoints': 200,
        'gamerTier': 'Gold',
        'globalElo': 1500,
        'level': 5,
        'mutualFriendsCount': 2,
        'relationship': {'status': 'Accepted'},
        'canSendFriendRequest': false,
        'canReport': true,
      };
      final entity = FriendProfileModel.fromJson(json).toEntity();

      expect(entity, isA<FriendProfileEntity>());
      expect(entity.userId, 'u1');
      expect(entity.username, 'dave');
      expect(entity.bio, 'Hi');
      expect(entity.karmaPoints, 200);
      expect(entity.gamerTier, GamerTier.gold);
      expect(entity.globalElo, 1500);
      expect(entity.level, 5);
      expect(entity.friendshipStatus, FriendshipStatus.accepted);
      expect(entity.isFriend, isTrue);
    });
  });
}
