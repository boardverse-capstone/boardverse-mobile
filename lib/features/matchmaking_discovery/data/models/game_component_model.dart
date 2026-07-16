import '../../domain/entities/game_component_entity.dart';

class GameComponentModel {
  final String id;
  final String componentName;
  final int defaultQuantity;

  const GameComponentModel({
    required this.id,
    required this.componentName,
    required this.defaultQuantity,
  });

  factory GameComponentModel.fromJson(Map<String, dynamic> json) {
    return GameComponentModel(
      id: json['id'] as String,
      componentName: json['componentName'] as String,
      defaultQuantity: (json['defaultQuantity'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'componentName': componentName,
      'defaultQuantity': defaultQuantity,
    };
  }

  GameComponentEntity toEntity() => GameComponentEntity(
        id: id,
        componentName: componentName,
        defaultQuantity: defaultQuantity,
      );
}
