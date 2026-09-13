import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import 'datasources/karma_rating_remote_datasource.dart';
import '../domain/entities/rating_entity.dart';
import '../domain/repositories/rating_repository.dart';

/// Triển khai [RatingRepository] gọi UserRatingController thật theo
/// spec `.agents/docs/apis_docs/user-ratings.md`.
///
/// Phiên bản này THAY THẾ mock cũ (mock_rating_datasource.dart):
/// - `getKarmaRatingContext` → GET /api/v1/users/ratings/karma/lobbies/{lobbyId}
/// - `submitKarmaRatings` → POST /api/v1/users/ratings/karma
///
/// 3 method deprecated (ELO/MatchResult) chỉ trả về [ServerFailure] để
/// call site không crash — đã được thay thế bằng API thật ở
/// `/api/v1/matches/results` (xem `lib/features/tournament`).
class RatingRepositoryImpl implements RatingRepository {
  final KarmaRatingRemoteDatasource _datasource;

  RatingRepositoryImpl({required this._datasource});

  @override
  Future<Either<Failure, KarmaRatingContextEntity>> getKarmaRatingContext(
    String lobbyId,
  ) {
    return _datasource.getContext(lobbyId);
  }

  @override
  Future<Either<Failure, SubmitKarmaRatingsResultEntity>> submitKarmaRatings({
    required String lobbyId,
    required List<KarmaRatingEntry> entries,
  }) {
    return _datasource.submitRatings(lobbyId: lobbyId, entries: entries);
  }

  // ─── Deprecated methods (backward compat) ─────────────────────────

  @override
  Future<Either<Failure, void>> submitKarmaRating(
    String sessionId,
    Map<String, List<String>> playerRatings,
  ) async {
    return const Left<Failure, void>(
      ServerFailure(
        message: 'API này đã được thay thế bằng submitKarmaRatings().',
      ),
    );
  }

  @override
  Future<Either<Failure, EloResult>> submitMatchResult(
    String sessionId,
    MatchResult result,
  ) async {
    return const Left<Failure, EloResult>(
      ServerFailure(
        message: 'API này đã được thay thế bằng /api/v1/matches/results.',
      ),
    );
  }

  @override
  Future<Either<Failure, List<KarmaTag>>> getAvailableKarmaTags() async {
    return const Left<Failure, List<KarmaTag>>(
      ServerFailure(
        message:
            'API này đã được thay thế bằng getKarmaRatingContext().availableTags.',
      ),
    );
  }
}
