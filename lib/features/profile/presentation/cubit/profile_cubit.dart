import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart';

import 'package:boardverse_mobile/core/error/failures.dart';
import 'package:boardverse_mobile/features/profile/domain/entities/profile_entity.dart';
import 'package:boardverse_mobile/features/profile/domain/repositories/profile_repository.dart';
import 'package:boardverse_mobile/features/profile/presentation/cubit/profile_state.dart';

export 'package:boardverse_mobile/features/profile/presentation/cubit/profile_state.dart';

/// Cubit quản lý state của màn hình Profile.
///
/// Tách nhỏ theo 4 nhóm nghiệp vụ:
/// - Profile CRUD (getProfile, createProfile, updateProfile, deleteProfile)
/// - Avatar (updateAvatar)
/// - Location (getLocation, updateLocation, deleteLocation)
/// - Karma & Progress (getKarmaHistory, updateProgress)
class ProfileCubit extends Cubit<ProfileState> {
  final ProfileRepository repository;

  ProfileCubit({required this.repository}) : super(const ProfileInitial());

  /// Resets the cubit to its initial state. Used when the user logs out
  /// so a fresh profile fetch happens on the next login.
  void reset() {
    if (isClosed) return;
    emit(const ProfileInitial());
  }

  // ─── Profile CRUD ───────────────────────────────────────────────────────

  Future<void> getProfile() => _runProfileOperation(
        operation: () => repository.getProfile(),
      );

  Future<void> createProfile({
    required String bio,
    required String firstName,
    required String lastName,
    required String dateOfBirth,
    required String phoneNumber,
  }) =>
      _runProfileOperation(
        operation: () => repository.createProfile(
          bio: bio.isEmpty ? null : bio,
          firstName: firstName.isEmpty ? null : firstName,
          lastName: lastName.isEmpty ? null : lastName,
          dateOfBirth: dateOfBirth.isEmpty ? null : dateOfBirth,
          phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
        ),
      );

  Future<void> updateProfile({
    String? bio,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
  }) =>
      _runProfileOperation(
        operation: () => repository.updateProfile(
          bio: bio,
          firstName: firstName,
          lastName: lastName,
          dateOfBirth: dateOfBirth,
        ),
      );

  Future<void> deleteProfile() async {
    emit(const ProfileLoading());
    final result = await repository.deleteProfile();
    if (isClosed) return;
    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (_) => emit(const ProfileDeleted()),
    );
  }

  // ─── Avatar ─────────────────────────────────────────────────────────────

  Future<void> updateAvatar(String avatarUrl) =>
      _runProfileOperation(operation: () => repository.updateAvatar(avatarUrl));

  // ─── Location ───────────────────────────────────────────────────────────

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

  // ─── Karma & Progress ───────────────────────────────────────────────────

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

  // ─── Pipeline ───────────────────────────────────────────────────────────

  /// Public-facing "full-screen" operations: emit `ProfileLoading` first,
  /// then either `ProfileLoaded` or `ProfileFailure`.
  Future<void> _runProfileOperation({
    required Future<Either<Failure, ProfileEntity>> Function() operation,
  }) async {
    emit(const ProfileLoading());

    final result = await operation();
    if (isClosed) return;

    result.fold(
      (failure) => emit(ProfileFailure(message: failure.message)),
      (profile) => emit(ProfileLoaded(profile: profile)),
    );
  }
}
