import 'package:equatable/equatable.dart';

import '../../domain/entities/entities.dart';

/// State cho `ReservationListCubit`.
/// Sealed cho type-safety khi switch trong BlocBuilder.
sealed class ReservationListState extends Equatable {
  const ReservationListState();

  @override
  List<Object?> get props => [];
}

class ReservationListInitial extends ReservationListState {
  const ReservationListInitial();
}

class ReservationListLoading extends ReservationListState {
  const ReservationListLoading();
}

class ReservationListLoaded extends ReservationListState {
  final List<ReservationEntity> items;
  final bool? hostedByMe;

  const ReservationListLoaded({required this.items, this.hostedByMe});

  @override
  List<Object?> get props => [items, hostedByMe];
}

class ReservationListFailure extends ReservationListState {
  final String message;
  const ReservationListFailure({required this.message});

  @override
  List<Object?> get props => [message];
}