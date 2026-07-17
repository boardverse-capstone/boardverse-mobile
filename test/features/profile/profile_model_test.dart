// Unit tests for profile data models.
//
// Verify fromJson/toJson round-trips for:
// - ProfileModel
// - CreateProfileRequestModel
// - UpdateProfileRequestModel
// - PlayerLocationModel
// - KarmaHistoryModel
// - UpdateProgressRequestModel

import 'package:flutter_test/flutter_test.dart';
import 'package:boardverse_mobile/features/profile/data/models/create_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/karma_history_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/player_location_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/profile_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_avatar_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_location_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_profile_request_model.dart';
import 'package:boardverse_mobile/features/profile/data/models/update_progress_request_model.dart';

void main() {
  group('ProfileModel', () {
    test('fromJson parses all fields including PII', () {
      final json = {
        'userId': 'user_001',
        'username': 'TestPlayer',
        'avatarUrl': 'https://cdn.example.com/avatar.png',
        'bio': 'Hello world',
        'karmaPoints': 150,
        'gamerTier': 'Silver',
        'globalElo': 1250,
        'level': 7,
        'updatedAt': '2026-01-01T12:00:00Z',
        'hasProfile': true,
        'firstName': 'Test',
        'lastName': 'User',
        'dateOfBirth': '2000-01-01',
        'phoneNumber': '0909123456',
      };

      final model = ProfileModel.fromJson(json);

      expect(model.userId, 'user_001');
      expect(model.username, 'TestPlayer');
      expect(model.avatarUrl, 'https://cdn.example.com/avatar.png');
      expect(model.bio, 'Hello world');
      expect(model.karmaPoints, 150);
      expect(model.gamerTier, 'Silver');
      expect(model.globalElo, 1250);
      expect(model.level, 7);
      expect(model.updatedAt, '2026-01-01T12:00:00Z');
      expect(model.hasProfile, true);
      expect(model.firstName, 'Test');
      expect(model.lastName, 'User');
      expect(model.dateOfBirth, '2000-01-01');
      expect(model.phoneNumber, '0909123456');
    });

    test('toJson serializes all fields including PII', () {
      const model = ProfileModel(
        userId: 'user_001',
        username: 'TestPlayer',
        avatarUrl: 'https://cdn.example.com/avatar.png',
        bio: 'Hello world',
        karmaPoints: 150,
        gamerTier: 'Silver',
        globalElo: 1250,
        level: 7,
        updatedAt: '2026-01-01T12:00:00Z',
        hasProfile: true,
        firstName: 'Test',
        lastName: 'User',
        dateOfBirth: '2000-01-01',
        phoneNumber: '0909123456',
      );

      final json = model.toJson();

      expect(json['userId'], 'user_001');
      expect(json['username'], 'TestPlayer');
      expect(json['firstName'], 'Test');
      expect(json['lastName'], 'User');
      expect(json['phoneNumber'], '0909123456');
      expect(json['hasProfile'], true);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'userId': 'user_001',
        'username': 'TestPlayer',
        'globalElo': 1200,
        'level': 1,
        'hasProfile': false,
      };

      final model = ProfileModel.fromJson(json);

      expect(model.userId, 'user_001');
      expect(model.avatarUrl, isNull);
      expect(model.firstName, isNull);
      expect(model.phoneNumber, isNull);
    });
  });

  group('CreateProfileRequestModel', () {
    test('all fields are optional (per backend contract)', () {
      const model = CreateProfileRequestModel();

      expect(model.bio, isNull);
      expect(model.firstName, isNull);
      expect(model.lastName, isNull);
      expect(model.dateOfBirth, isNull);
      expect(model.phoneNumber, isNull);
    });

    test('fromJson / toJson round-trip', () {
      const model = CreateProfileRequestModel(
        bio: 'Test bio',
        firstName: 'John',
        lastName: 'Doe',
        dateOfBirth: '1990-05-15',
        phoneNumber: '0912345678',
      );

      final json = model.toJson();
      final restored = CreateProfileRequestModel.fromJson(json);

      expect(restored.bio, 'Test bio');
      expect(restored.firstName, 'John');
      expect(restored.lastName, 'Doe');
    });
  });

  group('UpdateProfileRequestModel', () {
    test('fromJson / toJson round-trip', () {
      const model = UpdateProfileRequestModel(
        bio: 'Updated bio',
        firstName: 'Jane',
        lastName: 'Smith',
        dateOfBirth: '1995-03-20',
        globalElo: '1300',
        level: 8,
      );

      final json = model.toJson();
      final restored = UpdateProfileRequestModel.fromJson(json);

      expect(restored.bio, 'Updated bio');
      expect(restored.firstName, 'Jane');
      expect(restored.lastName, 'Smith');
      expect(restored.globalElo, '1300');
      expect(restored.level, 8);
    });
  });

  group('UpdateAvatarRequestModel', () {
    test('fromJson / toJson round-trip', () {
      const model = UpdateAvatarRequestModel(
        avatarUrl: 'https://cdn.example.com/new_avatar.png',
      );

      final json = model.toJson();
      final restored = UpdateAvatarRequestModel.fromJson(json);

      expect(restored.avatarUrl, 'https://cdn.example.com/new_avatar.png');
    });
  });

  group('UpdateLocationRequestModel', () {
    test('fromJson / toJson round-trip', () {
      const model = UpdateLocationRequestModel(
        latitude: 10.7769,
        longitude: 106.7008,
        source: 0, // Gps
      );

      final json = model.toJson();
      final restored = UpdateLocationRequestModel.fromJson(json);

      expect(restored.latitude, 10.7769);
      expect(restored.longitude, 106.7008);
      expect(restored.source, 0);
    });

    test('source 1 represents manual location', () {
      const model = UpdateLocationRequestModel(
        latitude: 21.0285,
        longitude: 105.8542,
        source: 1, // Manual
      );

      final json = model.toJson();
      final restored = UpdateLocationRequestModel.fromJson(json);

      expect(restored.source, 1);
    });
  });

  group('PlayerLocationModel', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'latitude': 10.7769,
        'longitude': 106.7008,
        'updatedAt': '2026-01-01T12:00:00Z',
        'source': 0,
        'hasLocation': true,
      };

      final model = PlayerLocationModel.fromJson(json);

      expect(model.latitude, 10.7769);
      expect(model.longitude, 106.7008);
      expect(model.source, 0);
      expect(model.hasLocation, true);

      final serialized = model.toJson();
      expect(serialized['latitude'], 10.7769);
      expect(serialized['source'], 0);
    });
  });

  group('KarmaHistoryModel', () {
    test('fromJson / toJson round-trip', () {
      final json = {
        'userId': 'user_001',
        'username': 'TestPlayer',
        'karmaPoints': 200,
        'gamerTier': 'Gold',
        'avatarUrl': 'https://cdn.example.com/avatar.png',
        'updatedAt': '2026-01-01T12:00:00Z',
      };

      final model = KarmaHistoryModel.fromJson(json);

      expect(model.userId, 'user_001');
      expect(model.karmaPoints, 200);
      expect(model.gamerTier, 'Gold');

      final serialized = model.toJson();
      expect(serialized['karmaPoints'], 200);
    });
  });

  group('UpdateProgressRequestModel', () {
    test('fromJson / toJson round-trip', () {
      const model = UpdateProgressRequestModel(
        globalElo: 1300,
        level: 8,
      );

      final json = model.toJson();
      final restored = UpdateProgressRequestModel.fromJson(json);

      expect(restored.globalElo, 1300);
      expect(restored.level, 8);
    });
  });
}
