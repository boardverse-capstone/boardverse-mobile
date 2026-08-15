import 'package:boardverse/features/friend_management/data/models/friend_request_model.dart';
import 'package:boardverse/features/friend_management/domain/entities/entities.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests cho [FriendRequestModel] defensive parsing — đảm bảo parse đúng
/// các alias field name mà backend `FriendshipResponseDto` có thể trả.
///
/// **Schema thực tế từ log debug** (verified 2026-07-28):
/// ```json
/// {
///   "friendshipId": "762b3368-d8ef-4084-ab31-e6be6d32dc4d",
///   "otherUserId": "092bbcf3-e729-43b5-8913-898961babc99",
///   "otherUsername": "jonny",
///   "otherAvatarUrl": null,
///   "status": "Pending",
///   "isRequester": false,
///   "createdAt": "2026-07-28T12:16:41.670646Z",
///   "acceptedAt": null,
///   "message": null,
///   "addresseeReadAt": null,
///   "mutualFriendsCount": 0
/// }
/// ```
void main() {
  group('FriendRequestModel.fromJson', () {
    test('parses schema thực tế (otherUserId / otherUsername / friendshipId)',
        () {
      // JSON thực tế từ backend `/api/v1/friends/requests/received` — đã
      // verify qua console log.
      final json = {
        'friendshipId': '762b3368-d8ef-4084-ab31-e6be6d32dc4d',
        'otherUserId': '092bbcf3-e729-43b5-8913-898961babc99',
        'otherUsername': 'jonny',
        'otherAvatarUrl': null,
        'status': 'Pending',
        'isRequester': false,
        'createdAt': '2026-07-28T12:16:41.670646Z',
        'acceptedAt': null,
        'message': null,
        'addresseeReadAt': null,
        'mutualFriendsCount': 0,
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requestId, '762b3368-d8ef-4084-ab31-e6be6d32dc4d');
      expect(m.requesterId, '092bbcf3-e729-43b5-8913-898961babc99');
      expect(m.requesterName, 'jonny');
      // otherAvatarUrl == null → fallback empty string (UI dùng "?" avatar).
      expect(m.requesterAvatar, '');
      expect(m.status, FriendRequestStatus.pending);
      expect(m.message, isNull);
      expect(m.mutualFriendsCount, 0);
      expect(m.isRead, isFalse); // addresseeReadAt == null
      expect(m.createdAt.year, 2026);
      expect(m.createdAt.month, 7);
    });

    test('parses top-level fields với prefix requester*', () {
      final json = {
        'requestId': 'req-1',
        'requesterId': 'user-1',
        'requesterName': 'alice',
        'requesterAvatar': 'https://cdn/alice.png',
        'status': 'Pending',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
        'message': 'Chơi Catan nhé',
        'addresseeReadAt': '2026-01-15T10:05:00Z',
        'mutualFriendsCount': 3,
        'karmaPoints': 120,
        'gamerTier': 'Silver',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requestId, 'req-1');
      expect(m.requesterId, 'user-1');
      expect(m.requesterName, 'alice');
      expect(m.requesterAvatar, 'https://cdn/alice.png');
      expect(m.status, FriendRequestStatus.pending);
      expect(m.message, 'Chơi Catan nhé');
      expect(m.isRead, isTrue); // addresseeReadAt != null
      expect(m.mutualFriendsCount, 3);
      expect(m.karmaPoints, 120);
      expect(m.gamerTier, GamerTier.silver);
    });

    test('parses alias không có prefix requester*', () {
      final json = {
        'id': 'req-2',
        'userId': 'user-2',
        'username': 'bob',
        'avatarUrl': 'https://cdn/bob.png',
        'status': 'Pending',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requestId, 'req-2');
      expect(m.requesterId, 'user-2');
      expect(m.requesterName, 'bob');
      expect(m.requesterAvatar, 'https://cdn/bob.png');
    });

    test('parses flat schema `odId`/`username` (giống UserSearchResultDto)', () {
      // Backend .NET có thể trả FriendshipResponseDto với schema flat
      // (không prefix `requester*`) giống UserSearchResultDto / FriendSearchDto.
      final json = {
        'id': 'req-flat',
        'odId': '14acc364-e60e-49b5-9399-7e3c9a823407',
        'username': 'jonny',
        'avatarUrl': 'https://cdn/jonny.png',
        'karmaPoints': 100,
        'friendshipStatus': 'Pending',
        'mutualFriendsCount': 2,
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requesterId, '14acc364-e60e-49b5-9399-7e3c9a823407');
      expect(m.requesterName, 'jonny');
      expect(m.requesterAvatar, 'https://cdn/jonny.png');
      expect(m.karmaPoints, 100);
    });

    test('parses nested object `requester: { username, avatarUrl }`', () {
      final json = {
        'requestId': 'req-3',
        'requesterId': 'user-3',
        'requester': {
          'username': 'charlie',
          'avatarUrl': 'https://cdn/charlie.png',
        },
        'status': 'Pending',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requesterName, 'charlie');
      expect(m.requesterAvatar, 'https://cdn/charlie.png');
    });

    test('parses nested firstName + lastName ghép thành full name', () {
      final json = {
        'requestId': 'req-4',
        'requesterId': 'user-4',
        'requester': {
          'firstName': 'Alice',
          'lastName': 'Nguyen',
        },
        'status': 'Pending',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requesterName, 'Alice Nguyen');
    });

    test('parse schema rỗng (chỉ có id) — defensive fallback', () {
      // Bug ban đầu: backend trả DTO chỉ có `requesterId` + `createdAt`
      // → model cũ để `requesterName = ''` → UI hiển thị avatar "?" +
      // name rỗng. Test này verify parsing không crash và trả empty string
      // (để UI fallback `User #<short id>`).
      final json = {
        'id': 'req-5',
        'requesterId': 'abcdef12-3456-7890-abcd-ef1234567890',
        'status': 'Pending',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      final m = FriendRequestModel.fromJson(json);

      expect(m.requestId, 'req-5');
      expect(m.requesterId, 'abcdef12-3456-7890-abcd-ef1234567890');
      expect(m.requesterName, ''); // fallback rỗng → UI dùng "User #abcdef12"
      expect(m.requesterAvatar, '');
      expect(m.message, isNull);
      expect(m.karmaPoints, isNull);
      expect(m.gamerTier, isNull);
    });

    test('parse status alias "rejected" → declined, "cancelled" → removed', () {
      final base = {
        'requestId': 'req-x',
        'requesterId': 'user-x',
        'requesterName': 'x',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
      };

      expect(
        FriendRequestModel.fromJson({...base, 'status': 'rejected'}).status,
        FriendRequestStatus.declined,
      );
      expect(
        FriendRequestModel.fromJson({...base, 'status': 'cancelled'}).status,
        FriendRequestStatus.removed,
      );
      expect(
        FriendRequestModel.fromJson({...base, 'status': 'Expired'}).status,
        FriendRequestStatus.expired,
      );
    });

    test('toEntity giữ nguyên data', () {
      final json = {
        'friendshipId': 'req-6',
        'otherUserId': 'user-6',
        'otherUsername': 'dave',
        'otherAvatarUrl': 'https://cdn/dave.png',
        'status': 'Accepted',
        'createdAt': '2026-01-15T10:00:00Z',
        'expiresAt': '2026-02-15T10:00:00Z',
        'message': 'Hi',
        'mutualFriendsCount': 5,
      };
      final entity = FriendRequestModel.fromJson(json).toEntity();

      expect(entity, isA<FriendRequestEntity>());
      expect(entity.requestId, 'req-6');
      expect(entity.requesterId, 'user-6');
      expect(entity.requesterName, 'dave');
      expect(entity.requesterAvatar, 'https://cdn/dave.png');
      expect(entity.status, FriendRequestStatus.accepted);
      expect(entity.message, 'Hi');
      expect(entity.mutualFriendsCount, 5);
    });
  });
}
