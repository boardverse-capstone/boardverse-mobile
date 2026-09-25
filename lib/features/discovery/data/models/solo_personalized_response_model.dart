import 'package:equatable/equatable.dart';

/// Model cho user preference profile.
class UserGamePreferenceModel extends Equatable {
  final String userId;
  final List<String> topCategoryIds;
  final double averageWeight;
  final double averageDuration;
  final int savedGameCount;

  const UserGamePreferenceModel({
    required this.userId,
    required this.topCategoryIds,
    required this.averageWeight,
    required this.averageDuration,
    required this.savedGameCount,
  });

  factory UserGamePreferenceModel.fromJson(Map<String, dynamic> json) {
    return UserGamePreferenceModel(
      userId: json['userId'] as String,
      topCategoryIds: (json['topCategoryIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      averageWeight: (json['averageWeight'] as num?)?.toDouble() ?? 0,
      averageDuration: (json['averageDuration'] as num?)?.toDouble() ?? 0,
      savedGameCount: json['savedGameCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        userId, topCategoryIds, averageWeight, averageDuration, savedGameCount,
      ];
}

/// Model cho personalized game trong Solo Personalized response.
class PersonalizedBoardGameModel extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String? description;
  final int minPlayers;
  final int maxPlayers;
  final int playTimeMinutes;
  final double? weight;
  final List<String> categories;
  final double baseScore;
  final double personalizationBoost;
  final double playHistoryPenalty;
  final double personalizedScore;
  final String? matchReason;
  final bool isSaved;
  final bool hasOpenLobby;
  final String? openLobbyId;

  const PersonalizedBoardGameModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.description,
    required this.minPlayers,
    required this.maxPlayers,
    required this.playTimeMinutes,
    this.weight,
    required this.categories,
    required this.baseScore,
    required this.personalizationBoost,
    required this.playHistoryPenalty,
    required this.personalizedScore,
    this.matchReason,
    required this.isSaved,
    required this.hasOpenLobby,
    this.openLobbyId,
  });

  factory PersonalizedBoardGameModel.fromJson(Map<String, dynamic> json) {
    return PersonalizedBoardGameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['thumbnailUrl'] as String? ?? json['imageUrl'] as String?,
      description: json['description'] as String?,
      minPlayers: json['minPlayers'] as int,
      maxPlayers: json['maxPlayers'] as int,
      playTimeMinutes: json['playTimeMinutes'] as int? ?? json['playTime'] as int? ?? 60,
      weight: (json['weight'] ?? json['bggWeight']) != null
          ? (json['weight'] ?? json['bggWeight'] as num).toDouble()
          : null,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e is String ? e : e['name'] as String? ?? '')
              .toList() ??
          [],
      baseScore: (json['baseScore'] as num?)?.toDouble() ?? 0,
      personalizationBoost:
          (json['personalizationBoost'] as num?)?.toDouble() ?? 0,
      playHistoryPenalty:
          (json['playHistoryPenalty'] as num?)?.toDouble() ?? 0,
      personalizedScore:
          (json['personalizedScore'] as num?)?.toDouble() ?? 0,
      matchReason: json['matchReason'] as String?,
      isSaved: json['isSaved'] as bool? ?? false,
      hasOpenLobby: json['hasOpenLobby'] as bool? ?? false,
      openLobbyId: json['openLobbyId'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id, name, imageUrl, description, minPlayers, maxPlayers,
        playTimeMinutes, weight, categories, baseScore,
        personalizationBoost, playHistoryPenalty, personalizedScore,
        matchReason, isSaved, hasOpenLobby, openLobbyId,
      ];
}

/// Model cho nearest cafe.
class NearbyCafeForGameModel extends Equatable {
  final String cafeId;
  final String cafeName;
  final String cafeAddress;
  final double distanceKm;
  final List<String> availableGameIds;

  const NearbyCafeForGameModel({
    required this.cafeId,
    required this.cafeName,
    required this.cafeAddress,
    required this.distanceKm,
    required this.availableGameIds,
  });

  factory NearbyCafeForGameModel.fromJson(Map<String, dynamic> json) {
    return NearbyCafeForGameModel(
      cafeId: json['cafeId'] as String,
      cafeName: json['cafeName'] as String,
      cafeAddress: json['cafeAddress'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      availableGameIds: (json['availableGames'] as List<dynamic>? ??
              json['availableGameIds'] as List<dynamic>? ??
              [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  @override
  List<Object?> get props => [cafeId, cafeName, cafeAddress, distanceKm, availableGameIds];
}

/// Model cho open lobby summary.
class OpenLobbySummaryModel extends Equatable {
  final String lobbyId;
  final String lobbyName;
  final int currentMembers;
  final int maxMembers;
  final DateTime? scheduledStartTime;

  const OpenLobbySummaryModel({
    required this.lobbyId,
    required this.lobbyName,
    required this.currentMembers,
    required this.maxMembers,
    this.scheduledStartTime,
  });

  factory OpenLobbySummaryModel.fromJson(Map<String, dynamic> json) {
    return OpenLobbySummaryModel(
      lobbyId: json['lobbyId'] as String,
      lobbyName: json['lobbyName'] as String? ?? 'Phòng chờ',
      currentMembers: json['currentMembers'] as int? ?? json['memberCount'] as int? ?? 0,
      maxMembers: json['maxMembers'] as int? ?? 0,
      scheduledStartTime: json['scheduledStartTime'] != null
          ? DateTime.tryParse(json['scheduledStartTime'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
        lobbyId, lobbyName, currentMembers, maxMembers, scheduledStartTime,
      ];
}

/// Wrapper response cho Solo Personalized.
class SoloPersonalizedResponseModel extends Equatable {
  final List<PersonalizedBoardGameModel> games;
  final UserGamePreferenceModel? userProfile;
  final int totalCount;
  final NearbyCafeForGameModel? nearestCafe;
  final List<OpenLobbySummaryModel> openLobbies;

  const SoloPersonalizedResponseModel({
    required this.games,
    this.userProfile,
    required this.totalCount,
    this.nearestCafe,
    required this.openLobbies,
  });

  factory SoloPersonalizedResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final gamesList = data['games'] as List<dynamic>? ?? [];
    return SoloPersonalizedResponseModel(
      games: gamesList
          .map((e) => PersonalizedBoardGameModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      userProfile: data['userProfile'] != null
          ? UserGamePreferenceModel.fromJson(
              data['userProfile'] as Map<String, dynamic>)
          : null,
      totalCount: data['totalCount'] as int? ?? gamesList.length,
      nearestCafe: data['nearestCafe'] != null
          ? NearbyCafeForGameModel.fromJson(
              data['nearestCafe'] as Map<String, dynamic>)
          : null,
      openLobbies: (data['openLobbies'] as List<dynamic>?)
              ?.map((e) => OpenLobbySummaryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        games, userProfile, totalCount, nearestCafe, openLobbies,
      ];
}
