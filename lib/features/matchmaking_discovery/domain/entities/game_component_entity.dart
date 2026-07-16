import 'package:equatable/equatable.dart';

/// Linh kiện trong hộp board game — map từ `components[]` trong response
/// của `GET /api/v1/board-games/{id}` (hoặc `{id}/details`).
class GameComponentEntity extends Equatable {
  final String id;
  final String componentName;
  final int defaultQuantity;

  const GameComponentEntity({
    required this.id,
    required this.componentName,
    required this.defaultQuantity,
  });

  @override
  List<Object?> get props => [id, componentName, defaultQuantity];
}
