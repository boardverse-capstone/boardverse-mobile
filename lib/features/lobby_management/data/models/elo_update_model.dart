import 'package:equatable/equatable.dart';

/// Model cho Elo update.
class EloUpdateModel extends Equatable {
  final String odId;
  final String reportedOutcome;
  final int eloBefore;
  final int eloAfter;
  final int eloDelta;

  const EloUpdateModel({
    required this.odId,
    required this.reportedOutcome,
    required this.eloBefore,
    required this.eloAfter,
    required this.eloDelta,
  });

  factory EloUpdateModel.fromJson(Map<String, dynamic> json) {
    return EloUpdateModel(
      odId: (json['userId'] ?? '').toString(),
      reportedOutcome: (json['reportedOutcome'] ?? 'Win').toString(),
      eloBefore: (json['eloBefore'] as num?)?.toInt() ?? 0,
      eloAfter: (json['eloAfter'] as num?)?.toInt() ?? 0,
      eloDelta: (json['eloDelta'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': odId,
    'reportedOutcome': reportedOutcome,
    'eloBefore': eloBefore,
    'eloAfter': eloAfter,
    'eloDelta': eloDelta,
  };

  @override
  List<Object?> get props => [odId, reportedOutcome, eloBefore, eloAfter, eloDelta];
}

/// Enum cho trạng thái consensus.
enum MatchConsensusStatus {
  awaitingSubmissions,
  conflict,
  finalized;

  static MatchConsensusStatus fromString(String? value) {
    if (value == null) return MatchConsensusStatus.awaitingSubmissions;
    final normalized = value.toLowerCase().trim();
    switch (normalized) {
      case 'awaitingsubmissions':
      case 'awaiting_submissions':
        return MatchConsensusStatus.awaitingSubmissions;
      case 'conflict':
        return MatchConsensusStatus.conflict;
      case 'finalized':
        return MatchConsensusStatus.finalized;
      default:
        return MatchConsensusStatus.awaitingSubmissions;
    }
  }
}

/// Model cho response của submit kết quả trận đấu.
class MatchResultSubmitResponseModel extends Equatable {
  final String lobbyId;
  final MatchConsensusStatus consensusStatus;
  final int submittedCount;
  final int requiredCount;
  final String? matchHistoryId;
  final List<EloUpdateModel> eloUpdates;

  const MatchResultSubmitResponseModel({
    required this.lobbyId,
    required this.consensusStatus,
    required this.submittedCount,
    required this.requiredCount,
    this.matchHistoryId,
    this.eloUpdates = const [],
  });

  factory MatchResultSubmitResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    final eloUpdatesRaw = data['eloUpdates'] as List<dynamic>? ?? [];
    final eloUpdates = eloUpdatesRaw
        .map((e) => EloUpdateModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return MatchResultSubmitResponseModel(
      lobbyId: (data['lobbyId'] ?? '').toString(),
      consensusStatus: MatchConsensusStatus.fromString(data['consensusStatus'] as String?),
      submittedCount: (data['submittedCount'] as num?)?.toInt() ?? 0,
      requiredCount: (data['requiredCount'] as num?)?.toInt() ?? 0,
      matchHistoryId: data['matchHistoryId'] as String?,
      eloUpdates: eloUpdates,
    );
  }

  Map<String, dynamic> toJson() => {
    'lobbyId': lobbyId,
    'consensusStatus': consensusStatus.name,
    'submittedCount': submittedCount,
    'requiredCount': requiredCount,
    'matchHistoryId': matchHistoryId,
    'eloUpdates': eloUpdates.map((e) => e.toJson()).toList(),
  };

  bool get isFinalized => consensusStatus == MatchConsensusStatus.finalized;

  @override
  List<Object?> get props => [
    lobbyId,
    consensusStatus,
    submittedCount,
    requiredCount,
    matchHistoryId,
    eloUpdates,
  ];
}
