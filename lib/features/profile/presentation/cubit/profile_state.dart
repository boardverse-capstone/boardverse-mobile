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
  final PlayerLocationEntity? location;
  final KarmaHistoryEntity? karma;
  final String? supplementaryError;

  const ProfileLoaded({
    required this.profile,
    this.location,
    this.karma,
    this.supplementaryError,
  });

  @override
  List<Object?> get props => [profile, location, karma, supplementaryError];
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

  /// Thông báo backend trả về kèm theo (VD: "Cập nhật vị trí hiện tại
  /// thành công."). `null` khi state được emit từ `getLocation` — chỉ
  /// `updateLocation` mới có message vì API spec chỉ trả về sau PUT.
  final String? message;

  const ProfileLocationLoaded({required this.location, this.message});

  @override
  List<Object?> get props => [location, message];
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
