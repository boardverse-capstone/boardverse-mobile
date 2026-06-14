import 'package:equatable/equatable.dart';

class CafeEntity extends Equatable {
  final String id;
  final String name;
  final String address;
  final String imageUrl;
  final double distanceKm;
  final int availableTables;
  final bool hasGameInStock;
  final int? estimatedWaitMinutes;
  final double rating;
  final List<String> availableGameIds;

  const CafeEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.distanceKm,
    required this.availableTables,
    required this.hasGameInStock,
    this.estimatedWaitMinutes,
    required this.rating,
    required this.availableGameIds,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        imageUrl,
        distanceKm,
        availableTables,
        hasGameInStock,
        estimatedWaitMinutes,
        rating,
        availableGameIds,
      ];
}
