import 'elo_history_entity.dart';

/// `GET /tournaments/my-elo-history` trả về một OBJECT (không phải array):
///
/// ```json
/// {
///   "userId": "...",
///   "username": "...",
///   "currentElo": 1200,
///   "history": [
///     { "tournamentId": "...", "eloBefore": 1200, ... },
///     ...
///   ]
/// }
/// ```
///
/// Entity này mirror đúng shape đó để cubit có thể trích xuất summary
/// (currentElo) + danh sách [EloHistoryEntity].
class MyEloHistoryResponse {
  final String userId;
  final String username;
  final int currentElo;
  final List<EloHistoryEntity> history;

  const MyEloHistoryResponse({
    required this.userId,
    required this.username,
    required this.currentElo,
    required this.history,
  });
}
