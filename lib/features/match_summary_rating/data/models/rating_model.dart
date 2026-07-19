import '../../domain/entities/rating_entity.dart';

enum MatchResultModel { win, lose, draw }

class KarmaTagModel {
  final String id;
  final String name;
  final String icon;
  final bool isPositive;
  final bool isSelected;

  const KarmaTagModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.isPositive,
    this.isSelected = false,
  });

  factory KarmaTagModel.fromJson(Map<String, dynamic> json) {
    return KarmaTagModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      isPositive: json['isPositive'] as bool,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'isPositive': isPositive,
      'isSelected': isSelected,
    };
  }

  KarmaTag toEntity() => KarmaTag(
    id: id,
    name: name,
    icon: icon,
    isPositive: isPositive,
    isSelected: isSelected,
  );
}

class EloResultModel {
  final String sessionId;
  final MatchResultModel result;
  final int eloChange;
  final int currentElo;
  final int newElo;

  const EloResultModel({
    required this.sessionId,
    required this.result,
    required this.eloChange,
    required this.currentElo,
    required this.newElo,
  });

  factory EloResultModel.fromJson(Map<String, dynamic> json) {
    return EloResultModel(
      sessionId: json['sessionId'] as String,
      result: MatchResultModel.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => MatchResultModel.draw,
      ),
      eloChange: json['eloChange'] as int,
      currentElo: json['currentElo'] as int,
      newElo: json['newElo'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'result': result.name,
      'eloChange': eloChange,
      'currentElo': currentElo,
      'newElo': newElo,
    };
  }

  EloResult toEntity() => EloResult(
    sessionId: sessionId,
    result: _resultToEntity(result),
    eloChange: eloChange,
    currentElo: currentElo,
    newElo: newElo,
  );

  static MatchResult _resultToEntity(MatchResultModel result) {
    switch (result) {
      case MatchResultModel.win:
        return MatchResult.win;
      case MatchResultModel.lose:
        return MatchResult.lose;
      case MatchResultModel.draw:
        return MatchResult.draw;
    }
  }
}

class RatingPlayerModel {
  final String id;
  final String name;
  final String avatarUrl;

  const RatingPlayerModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });

  factory RatingPlayerModel.fromJson(Map<String, dynamic> json) {
    return RatingPlayerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'avatarUrl': avatarUrl};
  }
}
