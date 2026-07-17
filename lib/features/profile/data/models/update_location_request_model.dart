import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_location_request_model.freezed.dart';
part 'update_location_request_model.g.dart';

/// Request body for PUT /api/userprofile/me/location.
@freezed
abstract class UpdateLocationRequestModel with _$UpdateLocationRequestModel {
  const factory UpdateLocationRequestModel({
    required double latitude,
    required double longitude,
    /// 0 = Gps (device), 1 = Manual (map picker)
    required int source,
  }) = _UpdateLocationRequestModel;

  factory UpdateLocationRequestModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateLocationRequestModelFromJson(json);
}
