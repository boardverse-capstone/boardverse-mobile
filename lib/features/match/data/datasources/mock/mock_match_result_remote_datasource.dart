import 'dart:async';
import 'dart:math';

import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../domain/entities/match_consensus_entity.dart';
import '../base/match_result_remote_datasource.dart';

/// Mock in-memory state cho module Match (Elo consensus).
///
/// State machine giả lập:
/// - Khi `submitMatchResult()` được gọi, tăng `submittedCount` 1.
/// - Khi `submittedCount == requiredCount` → resolve consensus:
///     • nếu tất cả `Draw`                    → Finalized (Draw).
///     • nếu đúng 1 `Win` + còn lại `Loss`     → Finalized (Win/Loss).
///     • các TH khác                          → Conflict (chờ submit lại).
///
/// UI dev có thể reset qua [resetState].
class MockMatchResultRemoteDatasource implements MatchResultRemoteDatasource {
  MockMatchResultRemoteDatasource();

  static final Map<String, _LobbyConsensus> _store = {};
  static final _rng = Random();

  /// Reset state cho 1 lobby — chỉ dùng trong test/dev.
  static void resetState(String lobbyId) => _store.remove(lobbyId);

  /// Tạo sample state cho lobby — gọi khi UI cần `GET` nhưng chưa có submit nào.
  _LobbyConsensus _ensure(String lobbyId) {
    final existing = _store[lobbyId];
    if (existing != null) return existing;
    final fresh = _LobbyConsensus(
      lobbyId: lobbyId,
      gameTemplateId: 'bg_mock_001',
      gameName: 'Catan',
      requiredCount: 4,
    );
    _store[lobbyId] = fresh;
    return fresh;
  }

  @override
  Future<Either<Failure, MatchConsensusEntity>> getMatchResult(
    String lobbyId,
  ) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final c = _ensure(lobbyId);
    return Right(c.toEntity());
  }

  @override
  Future<Either<Failure, MatchSubmissionResultEntity>> submitMatchResult({
    required String lobbyId,
    required MatchOutcome outcome,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final c = _ensure(lobbyId);
    if (c.consensusStatus == MatchConsensusStatus.finalized) {
      return const Left(
        ServerFailure(
          message: 'Trận đấu đã được chốt, không thể gửi lại.',
          statusCode: 409,
        ),
      );
    }
    if (c.submittedCount >= c.requiredCount) {
      return const Left(
        ServerFailure(
          message: 'Đủ số người gửi, không thể gửi thêm.',
          statusCode: 409,
        ),
      );
    }
    // Mock: ghi nhận 1 submission với userId ngẫu nhiên.
    final userId = 'user_${_rng.nextInt(9000) + 1000}';
    c.submissions.add(
      _Submission(userId: userId, username: 'Player $userId', outcome: outcome),
    );
    c.submittedCount += 1;

    // Nếu vừa đủ số lượng → resolve consensus.
    if (c.submittedCount >= c.requiredCount) {
      final distinct = c.submissions.map((s) => s.outcome).toSet();
      if (distinct.length == 1 && distinct.contains(MatchOutcome.draw)) {
        c.consensusStatus = MatchConsensusStatus.finalized;
      } else {
        final wins = c.submissions.where((s) => s.outcome == MatchOutcome.win);
        final losses = c.submissions.where((s) => s.outcome == MatchOutcome.loss);
        if (wins.length == 1 && losses.length == c.requiredCount - 1) {
          c.consensusStatus = MatchConsensusStatus.finalized;
        } else {
          c.consensusStatus = MatchConsensusStatus.conflict;
          c.conflictReason =
              'Kết quả không đồng nhất — cần nhập lại (Wins=${wins.length}, Losses=${losses.length})';
        }
      }
      if (c.consensusStatus == MatchConsensusStatus.finalized) {
        c.matchHistoryId =
            'MATCH_HIST_${lobbyId}_${DateTime.now().millisecondsSinceEpoch}';
        // Mock Elo updates — tính theo công thức rút gọn ±16.
        c.eloUpdates.clear();
        for (final s in c.submissions) {
          final isWin = s.outcome == MatchOutcome.win;
          final isDraw = s.outcome == MatchOutcome.draw;
          final delta = isDraw ? 0 : (isWin ? 16 : -16);
          c.eloUpdates.add(
            _Elo(
              userId: s.userId,
              reportedOutcome: s.outcome,
              eloBefore: 1200,
              eloAfter: 1200 + delta,
              eloDelta: delta,
            ),
          );
        }
      }
    }

    return Right(c.toSubmissionResultEntity());
  }

  @override
  Stream<MatchConsensusEntity> watchMatchResult(String lobbyId) {
    // Mock đơn giản: chỉ emit snapshot duy nhất rồi đóng stream.
    // Phase sau có thể đẩy event `consensus-changed` qua Timer.periodic để
    // mô phỏng các member khác submit dần dần.
    final controller = StreamController<MatchConsensusEntity>();
    Future.microtask(() async {
      final res = await getMatchResult(lobbyId);
      res.fold((_) => null, (snapshot) {
        controller.add(snapshot);
      });
      await controller.close();
    });
    return controller.stream;
  }
}

// ─── Internal store types ────────────────────────────────────────────────

class _LobbyConsensus {
  final String lobbyId;
  final String gameTemplateId;
  final String gameName;
  final int requiredCount;
  final List<_Submission> submissions = [];
  int submittedCount = 0;
  MatchConsensusStatus consensusStatus = MatchConsensusStatus.awaitingSubmissions;
  String? conflictReason;
  String? matchHistoryId;
  final List<_Elo> eloUpdates = [];

  _LobbyConsensus({
    required this.lobbyId,
    required this.gameTemplateId,
    required this.gameName,
    required this.requiredCount,
  });

  bool get supportsMatchResults => true;

  List<MatchOutcomeChoice> get availableOutcomes => const [
        MatchOutcomeChoice(outcome: MatchOutcome.win, label: 'Thắng'),
        MatchOutcomeChoice(outcome: MatchOutcome.loss, label: 'Thua'),
        MatchOutcomeChoice(outcome: MatchOutcome.draw, label: 'Hòa'),
      ];

  MatchConsensusEntity toEntity() => MatchConsensusEntity(
        lobbyId: lobbyId,
        gameTemplateId: gameTemplateId,
        gameName: gameName,
        supportsMatchResults: supportsMatchResults,
        consensusStatus: consensusStatus,
        submittedCount: submittedCount,
        requiredCount: requiredCount,
        conflictReason: conflictReason,
        availableOutcomes: availableOutcomes,
        submissions: submissions
            .map(
              (s) => MatchSubmission(
                userId: s.userId,
                username: s.username,
                outcome: s.outcome,
                isCurrentUser: false,
              ),
            )
            .toList(),
      );

  MatchSubmissionResultEntity toSubmissionResultEntity() =>
      MatchSubmissionResultEntity(
        lobbyId: lobbyId,
        consensusStatus: consensusStatus,
        submittedCount: submittedCount,
        requiredCount: requiredCount,
        matchHistoryId: matchHistoryId,
        eloUpdates: eloUpdates
            .map(
              (e) => EloUpdateEntity(
                userId: e.userId,
                reportedOutcome: e.reportedOutcome,
                eloBefore: e.eloBefore,
                eloAfter: e.eloAfter,
                eloDelta: e.eloDelta,
              ),
            )
            .toList(),
      );
}

class _Submission {
  final String userId;
  final String username;
  final MatchOutcome outcome;
  _Submission({
    required this.userId,
    required this.username,
    required this.outcome,
  });
}

class _Elo {
  final String userId;
  final MatchOutcome reportedOutcome;
  final int eloBefore;
  final int eloAfter;
  final int eloDelta;
  _Elo({
    required this.userId,
    required this.reportedOutcome,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
  });
}
