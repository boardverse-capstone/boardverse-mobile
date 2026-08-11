import 'package:boardverse_mobile/features/tournament/domain/entities/leaderboard_entity.dart';

/// Leaderboard entry model for API response mapping.
class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int globalElo;
  final int karma;
  final int tournamentsPlayed;
  final int tournamentsWon;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.globalElo,
    required this.karma,
    required this.tournamentsPlayed,
    required this.tournamentsWon,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    // Display name: backend trả `username`; fallback các alias khác.
    String displayName = 'Người chơi';
    final walkIn = _readString(json, const ['walkInDisplayName'], '');
    final username = _readString(json, const ['username'], '');
    if (walkIn.isNotEmpty) {
      displayName = walkIn;
    } else if (username.isNotEmpty) {
      displayName = username;
    } else {
      displayName = _readString(json, const [
        'displayName',
        'fullName',
        'name',
      ], 'Người chơi');
    }

    return LeaderboardEntryModel(
      rank: _readInt(json, const ['rank', 'position'], 0),
      userId: _readString(json, const ['userId', 'oderId'], ''),
      displayName: displayName,
      avatarUrl: _readNullableString(json, const ['avatarUrl', 'avatar']),
      globalElo: _readInt(json, const [
        'globalElo',
        'elo',
        'tournamentElo',
      ], 1500),
      karma: _readInt(json, const ['karma', 'karmaPoints'], 0),
      tournamentsPlayed: _readInt(json, const [
        'tournamentsPlayed',
        'matchesPlayed',
      ], 0),
      tournamentsWon: _readInt(json, const ['tournamentsWon', 'matchesWon'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'displayName': displayName,
      'avatarUrl': avatarUrl,
      'globalElo': globalElo,
      'karma': karma,
      'tournamentsPlayed': tournamentsPlayed,
      'tournamentsWon': tournamentsWon,
    };
  }

  LeaderboardEntryEntity toEntity() {
    return LeaderboardEntryEntity(
      rank: rank,
      userId: userId,
      displayName: displayName,
      avatarUrl: avatarUrl,
      globalElo: globalElo,
      karma: karma,
      tournamentsPlayed: tournamentsPlayed,
      tournamentsWon: tournamentsWon,
    );
  }
}

int _readInt(Map<String, dynamic> json, List<String> keys, int fallback) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys,
  String fallback,
) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return fallback;
}

String? _readNullableString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
  }
  return null;
}
