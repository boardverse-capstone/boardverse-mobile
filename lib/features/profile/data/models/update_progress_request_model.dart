import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_progress_request_model.freezed.dart';
part 'update_progress_request_model.g.dart';

/// Request body for POST /api/userprofile/progress.
///
/// Called by the match result flow when a game ends — not by the profile UI.
@freezed
abstract class UpdateProgressRequestModel with _$UpdateProgressRequestModel {
  const factory UpdateProgressRequestModel({
    required int globalElo,
    required int level,
  }) = _UpdateProgressRequestModel;

  factory UpdateProgressRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateProgressRequestModelFromJson(json);
}
