import 'package:equatable/equatable.dart';

import 'personalized_board_game_entity.dart';
import 'user_game_preference_entity.dart';
import 'nearby_cafe_for_game_entity.dart';
import 'open_lobby_summary_entity.dart';

/// Response entity cho Solo Personalized Discovery.
///
/// Wrapper chứa danh sách games + user profile (nếu có).
class SoloPersonalizedResponseEntity extends Equatable {
  final List<PersonalizedBoardGameEntity> games;
  final UserGamePreferenceEntity? userProfile;

  /// Tổng số games match filter (trước khi giới hạn pageSize).
  final int totalCount;

  /// Cafe gần nhất có game (chỉ cho top-1 game).
  final NearbyCafeForGameEntity? nearestCafe;

  /// Danh sách lobby đang mở cho game top-1.
  final List<OpenLobbySummaryEntity> openLobbies;

  const SoloPersonalizedResponseEntity({
    required this.games,
    this.userProfile,
    required this.totalCount,
    this.nearestCafe,
    this.openLobbies = const [],
  });

  /// User có đủ saved games để personalize không (≥3).
  bool get hasPersonalization => userProfile != null;

  @override
  List<Object?> get props => [
        games, userProfile, totalCount, nearestCafe, openLobbies,
      ];
}
