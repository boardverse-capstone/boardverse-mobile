import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// States emitted by [AuthCubit].
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state — no auth operation in progress.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An auth operation is currently in progress.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Login succeeded and the user entity has been built from JWT claims.
class AuthSuccess extends AuthState {
  final UserEntity user;

  const AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

/// An auth operation failed. [message] comes from the backend envelope
/// and should be displayed directly to the user.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Registration completed successfully.
class AuthRegistered extends AuthState {
  final String message;

  const AuthRegistered({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Email verification (OTP) sent successfully.
class AuthEmailVerificationSent extends AuthState {
  final String message;

  const AuthEmailVerificationSent({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Email verified (OTP confirmed) successfully.
class AuthEmailVerified extends AuthState {
  final String message;

  const AuthEmailVerified({required this.message});

  @override
  List<Object?> get props => [message];
}
