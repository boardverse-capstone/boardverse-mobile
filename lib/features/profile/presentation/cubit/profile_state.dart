import 'package:equatable/equatable.dart';
import '../../domain/entities/karma_history_entity.dart';
import '../../domain/entities/player_location_entity.dart';
import '../../domain/entities/profile_entity.dart';

sealed class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileEntity profile;

  const ProfileLoaded({required this.profile});

  @override
  List<Object?> get props => [profile];
}

class ProfileNotFound extends ProfileState {
  final String message;

  const ProfileNotFound({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileFailure extends ProfileState {
  final String message;

  const ProfileFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class ProfileDeleted extends ProfileState {
  const ProfileDeleted();
}

class ProfileLocationLoaded extends ProfileState {
  final PlayerLocationEntity location;

  const ProfileLocationLoaded({required this.location});

  @override
  List<Object?> get props => [location];
}

class ProfileLocationDeleted extends ProfileState {
  const ProfileLocationDeleted();
}

class ProfileKarmaLoaded extends ProfileState {
  final KarmaHistoryEntity karma;

  const ProfileKarmaLoaded({required this.karma});

  @override
  List<Object?> get props => [karma];
}
