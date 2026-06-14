import 'package:equatable/equatable.dart';

class BoardGameEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int minPlayers;
  final int maxPlayers;
  final int estimatedMinutes;
  final String category;
  final List<String> components;
  final List<String> mechanics;
  final double rating;

  const BoardGameEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.minPlayers,
    required this.maxPlayers,
    required this.estimatedMinutes,
    required this.category,
    required this.components,
    required this.mechanics,
    required this.rating,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        minPlayers,
        maxPlayers,
        estimatedMinutes,
        category,
        components,
        mechanics,
        rating,
      ];
}
