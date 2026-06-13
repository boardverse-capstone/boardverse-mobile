import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../data/models/create_profile_request_model.dart';

abstract class ProfileRepository {
  Future<Either<Failure, ProfileEntity>> getProfile();
  Future<Either<Failure, ProfileEntity>> createProfile(CreateProfileRequestModel request);
}
