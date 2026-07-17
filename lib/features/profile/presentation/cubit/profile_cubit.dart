import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/profile_repository.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(const ProfileInitial());

  Future<void> getProfile() async {
    emit(const ProfileLoading());

    final result = await repository.getProfile();

    if (isClosed) return;
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

    // Fields are optional per backend contract; send null when empty so the
    // API receives only what was actually provided.
    final result = await repository.createProfile(
      bio: bio.isEmpty ? null : bio,
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
      dateOfBirth: dateOfBirth.isEmpty ? null : dateOfBirth,
      phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> updateProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  }) async {
    emit(const ProfileLoading());

    final result = await repository.updateProfile(
      bio: bio,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> updateAvatar(String avatarUrl) async {
    emit(const ProfileLoading());

    final result = await repository.updateAvatar(avatarUrl);

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }

  Future<void> deleteProfile() async {
    emit(const ProfileLoading());

    final result = await repository.deleteProfile();

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (_) => emit(const ProfileDeleted()),
    );
  }

  Future<void> getLocation() async {
    final result = await repository.getLocation();

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (location) => emit(ProfileLocationLoaded(location: location)),
    );
  }

  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    required int source,
  }) async {
    final result = await repository.updateLocation(
      latitude: latitude,
      longitude: longitude,
      source: source,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (location) => emit(ProfileLocationLoaded(location: location)),
    );
  }

  Future<void> deleteLocation() async {
    final result = await repository.deleteLocation();

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (_) => emit(const ProfileLocationDeleted()),
    );
  }

  Future<void> getKarmaHistory() async {
    final result = await repository.getKarmaHistory();

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (karma) => emit(ProfileKarmaLoaded(karma: karma)),
    );
  }

  Future<void> updateProgress({
    required int globalElo,
    required int level,
  }) async {
    final result = await repository.updateProgress(
      globalElo: globalElo,
      level: level,
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }
}
