import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:boardverse_mobile/features/tournament/domain/repositories/tournament_repository.dart';
import 'my_registrations_state.dart';

/// Cubit for managing "My Registrations" list with status filter.
class MyRegistrationsCubit extends Cubit<MyRegistrationsState> {
  final TournamentRepository _repository;
  MyRegistrationsFilter _currentFilter = MyRegistrationsFilter.all;

  MyRegistrationsCubit({required this._repository})
      : super(const MyRegistrationsInitial());

  /// Current filter applied to the list.
  MyRegistrationsFilter get currentFilter => _currentFilter;

  /// Loads my registrations using the supplied filter (defaults to all).
  Future<void> loadMyRegistrations({
    MyRegistrationsFilter filter = MyRegistrationsFilter.all,
  }) async {
    _currentFilter = filter;
    emit(MyRegistrationsLoading(currentFilter: filter));

    final result = await _repository.getMyRegistrations(
      status: filter.toBackendStatus(),
    );

    result.fold(
      (failure) => emit(MyRegistrationsError(
        message: failure.message,
        activeFilter: filter,
      )),
      (tournaments) {
        tournaments.sort((a, b) => b.startTime.compareTo(a.startTime));
        emit(MyRegistrationsLoaded(
          tournaments: tournaments,
          activeFilter: filter,
        ));
      },
    );
  }

  /// Switches to a new filter and reloads.
  Future<void> applyFilter(MyRegistrationsFilter filter) async {
    if (filter == _currentFilter && state is MyRegistrationsLoaded) {
      return;
    }
    await loadMyRegistrations(filter: filter);
  }

  /// Refreshes the current view.
  Future<void> refresh() async {
    await loadMyRegistrations(filter: _currentFilter);
  }
}