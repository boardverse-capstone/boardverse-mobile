import 'package:equatable/equatable.dart';
import '../../domain/entities/rating_entity.dart';

sealed class RatingState extends Equatable {
  const RatingState();

  @override
  List<Object?> get props => [];
}

class RatingInitial extends RatingState {
  const RatingInitial();
}

class RatingLoading extends RatingState {
  const RatingLoading();
}

class KarmaRating extends RatingState {
  final List<RatingPlayer> playersToRate;
  final List<KarmaTag> availableTags;
  final Map<String, List<String>> playerRatings;

  const KarmaRating({
    required this.playersToRate,
    required this.availableTags,
    required this.playerRatings,
  });

  @override
  List<Object?> get props => [playersToRate, availableTags, playerRatings];
}

class MatchResultEntry extends RatingState {
  final bool isWaitingConsensus;

  const MatchResultEntry({
    this.isWaitingConsensus = false,
  });

  @override
  List<Object?> get props => [isWaitingConsensus];
}

class EloResultDisplay extends RatingState {
  final EloResult eloResult;

  const EloResultDisplay({required this.eloResult});

  @override
  List<Object?> get props => [eloResult];
}

class RatingComplete extends RatingState {
  const RatingComplete();
}

class RatingFailure extends RatingState {
  final String message;

  const RatingFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

class RatingPlayer {
  final String id;
  final String name;
  final String avatarUrl;
  final List<String> selectedTagIds;

  const RatingPlayer({
    required this.id,
    required this.name,
    required this.avatarUrl,
    this.selectedTagIds = const [],
  });

  RatingPlayer copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    List<String>? selectedTagIds,
  }) {
    return RatingPlayer(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      selectedTagIds: selectedTagIds ?? this.selectedTagIds,
    );
  }
}
