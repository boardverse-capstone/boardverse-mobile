import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/karma_history_entity.dart';
import '../entities/player_location_entity.dart';
import '../entities/profile_entity.dart';

/// Repository interface for the User Profile feature.
///
/// All parameters are primitives or domain entities — no Data layer types
/// are referenced here to respect Clean Architecture boundaries.
abstract class ProfileRepository {
  /// GET /api/userprofile
  Future<Either<Failure, ProfileEntity>> getProfile();

  /// POST /api/userprofile — create profile for the first time.
  Future<Either<Failure, ProfileEntity>> createProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  });

  /// PUT /api/userprofile — partial update.
  Future<Either<Failure, ProfileEntity>> updateProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  });

  /// PUT /api/userprofile/me/avatar
  Future<Either<Failure, ProfileEntity>> updateAvatar(String avatarUrl);

  /// DELETE /api/userprofile — soft-delete.
  Future<Either<Failure, void>> deleteProfile();

  /// GET /api/userprofile/me/location
  Future<Either<Failure, PlayerLocationEntity>> getLocation();

  /// PUT /api/userprofile/me/location
  Future<Either<Failure, PlayerLocationEntity>> updateLocation({
    required double latitude,
    required double longitude,
    required int source,
  });

  /// DELETE /api/userprofile/me/location
  Future<Either<Failure, void>> deleteLocation();

  /// GET /api/userprofile/me/karma-history
  Future<Either<Failure, KarmaHistoryEntity>> getKarmaHistory();

  /// POST /api/userprofile/progress — update ELO/level after match result.
  Future<Either<Failure, ProfileEntity>> updateProgress({
    required int globalElo,
    required int level,
  });
}
