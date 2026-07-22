import '../../domain/entities/match_result_entity.dart';

/// Model cho API response của match result.
class MatchResultModel {
  final String lobbyId;
  final String gameTemplateId;
  final String gameName;
  final bool supportsMatchResults;
  final ConsensusStatus consensusStatus;
  final int submittedCount;
  final int requiredCount;
  final String? conflictReason;
  final List<MatchOutcome> availableOutcomes;
  final List<MatchSubmissionModel> submissions;

  const MatchResultModel({
    required this.lobbyId,
    required this.gameTemplateId,
    required this.gameName,
    required this.supportsMatchResults,
    required this.consensusStatus,
    required this.submittedCount,
    required this.requiredCount,
    this.conflictReason,
    required this.availableOutcomes,
    required this.submissions,
  });

  factory MatchResultModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    // Parse available outcomes
    final outcomesRaw = data['availableOutcomes'] as List<dynamic>? ?? [];
    final availableOutcomes = outcomesRaw
        .map((o) => MatchOutcome.fromString(o['outcome'] as String?))
        .toList();

    // Parse submissions
    final submissionsRaw = data['submissions'] as List<dynamic>? ?? [];
    final submissions = submissionsRaw
        .map((s) => MatchSubmissionModel.fromJson(s as Map<String, dynamic>))
        .toList();

    return MatchResultModel(
      lobbyId: (data['lobbyId'] ?? '').toString(),
      gameTemplateId: (data['gameTemplateId'] ?? '').toString(),
      gameName: (data['gameName'] ?? 'Board Game').toString(),
      supportsMatchResults: data['supportsMatchResults'] as bool? ?? false,
      consensusStatus: ConsensusStatus.fromString(data['consensusStatus'] as String?),
      submittedCount: (data['submittedCount'] as num?)?.toInt() ?? 0,
      requiredCount: (data['requiredCount'] as num?)?.toInt() ?? 0,
      conflictReason: data['conflictReason'] as String?,
      availableOutcomes: availableOutcomes,
      submissions: submissions,
    );
  }

  MatchResultEntity toEntity() => MatchResultEntity(
    lobbyId: lobbyId,
    gameTemplateId: gameTemplateId,
    gameName: gameName,
    supportsMatchResults: supportsMatchResults,
    consensusStatus: consensusStatus,
    submittedCount: submittedCount,
    requiredCount: requiredCount,
    conflictReason: conflictReason,
    availableOutcomes: availableOutcomes,
    submissions: submissions.map((s) => s.toEntity()).toList(),
  );
}

/// Model cho một submission.
class MatchSubmissionModel {
  final String odId;
  final String username;
  final MatchOutcome? outcome;
  final bool isCurrentUser;

  const MatchSubmissionModel({
    required this.odId,
    required this.username,
    this.outcome,
    required this.isCurrentUser,
  });

  factory MatchSubmissionModel.fromJson(Map<String, dynamic> json) {
    return MatchSubmissionModel(
      odId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? 'Người chơi').toString(),
      outcome: MatchOutcome.fromString(json['outcome'] as String?),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': odId,
    'username': username,
    'outcome': outcome?.value,
    'isCurrentUser': isCurrentUser,
  };

  MatchSubmissionEntity toEntity() => MatchSubmissionEntity(
    odId: odId,
    username: username,
    outcome: outcome,
    isCurrentUser: isCurrentUser,
  );
}
