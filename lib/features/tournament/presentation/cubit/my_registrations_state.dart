import 'package:equatable/equatable.dart';

import 'package:boardverse_mobile/features/tournament/domain/entities/tournament_entity.dart';

/// Filter for "My Registrations" page.
enum MyRegistrationsFilter {
  all,
  registrationOpen,
  registrationClosed,
  ongoing,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MyRegistrationsFilter.all:
        return 'Tất cả';
      case MyRegistrationsFilter.registrationOpen:
        return 'Đã đăng ký';
      case MyRegistrationsFilter.registrationClosed:
        return 'Đóng đăng ký';
      case MyRegistrationsFilter.ongoing:
        return 'Đang thi đấu';
      case MyRegistrationsFilter.completed:
        return 'Hoàn thành';
      case MyRegistrationsFilter.cancelled:
        return 'Đã hủy';
    }
  }

  /// Maps to backend status string used as query parameter for
  /// `GET /my-registrations?status=`. Returns null for "all".
  String? toBackendStatus() {
    switch (this) {
      case MyRegistrationsFilter.all:
        return null;
      case MyRegistrationsFilter.registrationOpen:
        return 'RegistrationOpen';
      case MyRegistrationsFilter.registrationClosed:
        return 'RegistrationClosed';
      case MyRegistrationsFilter.ongoing:
        return 'OnGoing';
      case MyRegistrationsFilter.completed:
        return 'Completed';
      case MyRegistrationsFilter.cancelled:
        return 'Cancelled';
    }
  }
}

/// States for MyRegistrationsCubit.
sealed class MyRegistrationsState extends Equatable {
  const MyRegistrationsState();

  @override
  List<Object?> get props => [];
}

class MyRegistrationsInitial extends MyRegistrationsState {
  const MyRegistrationsInitial();
}

class MyRegistrationsLoading extends MyRegistrationsState {
  final MyRegistrationsFilter currentFilter;
  const MyRegistrationsLoading({this.currentFilter = MyRegistrationsFilter.all});

  @override
  List<Object?> get props => [currentFilter];
}

class MyRegistrationsLoaded extends MyRegistrationsState {
  final List<TournamentEntity> tournaments;
  final MyRegistrationsFilter activeFilter;

  const MyRegistrationsLoaded({
    required this.tournaments,
    required this.activeFilter,
  });

  @override
  List<Object?> get props => [tournaments, activeFilter];
}

class MyRegistrationsError extends MyRegistrationsState {
  final String message;
  final MyRegistrationsFilter activeFilter;
  final List<TournamentEntity> previousTournaments;

  const MyRegistrationsError({
    required this.message,
    required this.activeFilter,
    this.previousTournaments = const [],
  });

  @override
  List<Object?> get props => [message, activeFilter, previousTournaments];
}