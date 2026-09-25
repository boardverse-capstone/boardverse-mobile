import 'package:equatable/equatable.dart';

/// Cafe gần nhất có chứa game được gợi ý (chỉ cho top-1 game).
class NearbyCafeForGameEntity extends Equatable {
  final String cafeId;
  final String cafeName;
  final String cafeAddress;
  final double distanceKm;
  final List<String> availableGameIds;

  const NearbyCafeForGameEntity({
    required this.cafeId,
    required this.cafeName,
    required this.cafeAddress,
    required this.distanceKm,
    required this.availableGameIds,
  });

  @override
  List<Object?> get props => [
        cafeId, cafeName, cafeAddress, distanceKm, availableGameIds,
      ];
}
