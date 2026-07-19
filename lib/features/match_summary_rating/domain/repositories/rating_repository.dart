import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/rating_entity.dart';

abstract class RatingRepository {
  Future<Either<Failure, void>> submitKarmaRating(
    String sessionId,
    Map<String, List<String>> playerRatings,
  );

  Future<Either<Failure, EloResult>> submitMatchResult(
    String sessionId,
    MatchResult result,
  );

  Future<Either<Failure, List<KarmaTag>>> getAvailableKarmaTags();
}
