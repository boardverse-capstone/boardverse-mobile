import 'package:equatable/equatable.dart';

import '../../domain/entities/cafe_detail_entity.dart';

abstract class CafeDetailState extends Equatable {
  const CafeDetailState();

  @override
  List<Object?> get props => [];
}

class CafeDetailInitial extends CafeDetailState {}

class CafeDetailLoading extends CafeDetailState {}

class CafeDetailLoaded extends CafeDetailState {
  final CafeDetailEntity cafe;

  const CafeDetailLoaded(this.cafe);

  @override
  List<Object?> get props => [cafe];
}

class CafeDetailError extends CafeDetailState {
  final String message;

  const CafeDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
