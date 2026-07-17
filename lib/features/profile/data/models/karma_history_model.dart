import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/karma_history_entity.dart';

part 'karma_history_model.freezed.dart';
part 'karma_history_model.g.dart';

/// Response model for GET /api/userprofile/me/karma-history.
@freezed
abstract class KarmaHistoryModel with _$KarmaHistoryModel {
  const factory KarmaHistoryModel({
    required String userId,
    required String username,
    required int karmaPoints,
    required String gamerTier,
    String? avatarUrl,
    String? updatedAt,
  }) = _KarmaHistoryModel;

  factory KarmaHistoryModel.fromJson(Map<String, dynamic> json) =>
      _$KarmaHistoryModelFromJson(json);
}

extension KarmaHistoryModelX on KarmaHistoryModel {
  KarmaHistoryEntity toEntity() => KarmaHistoryEntity(
        userId: userId,
        username: username,
        karmaPoints: karmaPoints,
        gamerTier: gamerTier,
        avatarUrl: avatarUrl,
        updatedAt: updatedAt,
      );
}
