import 'package:equatable/equatable.dart';

class RatingEntity extends Equatable {
  final String id;
  final String sessionId;
  final String playerId;
  final String playerName;
  final String avatarUrl;
  final List<KarmaTag> karmaTags;
  final int karmaScore;

  const RatingEntity({
    required this.id,
    required this.sessionId,
    required this.playerId,
    required this.playerName,
    required this.avatarUrl,
    required this.karmaTags,
    required this.karmaScore,
  });

  @override
  List<Object?> get props => [id, sessionId, playerId, playerName, avatarUrl, karmaTags, karmaScore];
}

class KarmaTag extends Equatable {
  final String id;
  final String name;
  final String icon;
  final bool isPositive;
  final bool isSelected;

  const KarmaTag({
    required this.id,
    required this.name,
    required this.icon,
    required this.isPositive,
    this.isSelected = false,
  });

  @override
  List<Object?> get props => [id, name, icon, isPositive, isSelected];
}

class EloResult extends Equatable {
  final String sessionId;
  final MatchResult result;
  final int eloChange;
  final int currentElo;
  final int newElo;

  const EloResult({
    required this.sessionId,
    required this.result,
    required this.eloChange,
    required this.currentElo,
    required this.newElo,
  });

  @override
  List<Object?> get props => [sessionId, result, eloChange, currentElo, newElo];
}

enum MatchResult { win, lose, draw }
