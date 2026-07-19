import '../../domain/entities/friend_entity.dart';

class FriendModel {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final bool isInLobby;

  const FriendModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isOnline,
    this.isInLobby = false,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
      isOnline: json['isOnline'] as bool,
      isInLobby: json['isInLobby'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'isInLobby': isInLobby,
    };
  }

  FriendEntity toEntity() => FriendEntity(
    id: id,
    name: name,
    avatarUrl: avatarUrl,
    isOnline: isOnline,
    isInLobby: isInLobby,
  );
}
