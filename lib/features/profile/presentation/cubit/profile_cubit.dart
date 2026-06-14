import 'package:flutter_bloc/flutter_bloc.dart';

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
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> createProfile({
    required String bio,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String phoneNumber,
  }) async {
    emit(const ProfileLoading());

    final request = CreateProfileRequestModel(
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
