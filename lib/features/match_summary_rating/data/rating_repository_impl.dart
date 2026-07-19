import 'package:dartz/dartz.dart';

import '../../../core/error/failures.dart';
import '../domain/entities/rating_entity.dart';
import '../domain/repositories/rating_repository.dart';
import 'datasources/mock_rating_datasource.dart';

class RatingRepositoryImpl implements RatingRepository {
  RatingRepositoryImpl();

  @override
  Future<Either<Failure, void>> submitKarmaRating(
    String sessionId,
    Map<String, List<String>> playerRatings,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi gửi đánh giá: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, EloResult>> submitMatchResult(
    String sessionId,
    MatchResult result,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      final eloResult = switch (result) {
        MatchResult.win => MockRatingDatasource.mockEloResultWin,
        MatchResult.lose => MockRatingDatasource.mockEloResultLose,
        MatchResult.draw => MockRatingDatasource.mockEloResultDraw,
      };
      return Right(eloResult.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Lỗi gửi kết quả: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<KarmaTag>>> getAvailableKarmaTags() async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      return Right(
        MockRatingDatasource.mockKarmaRatingTags
            .map((t) => t.toEntity())
            .toList(),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Lỗi lấy danh sách tag: ${e.toString()}'),
      );
    }
  }
}
