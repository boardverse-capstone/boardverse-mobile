import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../data/models/create_profile_request_model.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(const ProfileInitial());

  Future<void> getProfile() async {
    emit(const ProfileLoading());

    final result = await repository.getProfile();

    result.fold(
      (failure) {
        if (failure is ServerFailure && failure.statusCode == 404) {
          emit(ProfileNotFound(message: failure.message));
        } else {
          emit(ProfileFailure(message: failure.message));
        }
      },
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> createProfile({
    required String gamerTag,
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    emit(const ProfileLoading());

    final request = CreateProfileRequestModel(
      gamerTag: gamerTag,
      bio: bio,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      phoneNumber: phoneNumber,
    );

    final result = await repository.createProfile(request);

    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }
}
