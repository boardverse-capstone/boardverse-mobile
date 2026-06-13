import 'package:equatable/equatable.dart';

/// Pure domain entity representing an authenticated user.
///
/// Created by decoding the JWT claims after a successful login.
class UserEntity extends Equatable {
  final String userId;
  final String username;
  final String email;
  final String role;

  const UserEntity({
    required this.userId,
    required this.username,
    required this.email,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, username, email, role];
}
