import '../../domain/entities/cafe_entity.dart';

class CafeModel {
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

  const CafeModel({
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

  factory CafeModel.fromJson(Map<String, dynamic> json) {
    return CafeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      imageUrl: json['imageUrl'] as String,
      distanceKm: (json['distanceKm'] as num).toDouble(),
      availableTables: json['availableTables'] as int,
      hasGameInStock: json['hasGameInStock'] as bool,
      estimatedWaitMinutes: json['estimatedWaitMinutes'] as int?,
      rating: (json['rating'] as num).toDouble(),
      availableGameIds: List<String>.from(json['availableGameIds'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'imageUrl': imageUrl,
      'distanceKm': distanceKm,
      'availableTables': availableTables,
      'hasGameInStock': hasGameInStock,
      'estimatedWaitMinutes': estimatedWaitMinutes,
      'rating': rating,
      'availableGameIds': availableGameIds,
    };
  }

  CafeEntity toEntity() => CafeEntity(
        id: id,
        name: name,
        address: address,
        imageUrl: imageUrl,
        distanceKm: distanceKm,
        availableTables: availableTables,
        hasGameInStock: hasGameInStock,
        estimatedWaitMinutes: estimatedWaitMinutes,
        rating: rating,
        availableGameIds: availableGameIds,
      );
}
