import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens_model.freezed.dart';
part 'auth_tokens_model.g.dart';

/// Represents the `data` field returned by login / refresh-token endpoints.
///
/// ```json
/// {
///   "token": "jwt-access-token",
///   "refreshToken": "refresh-token"
/// }
/// ```
@freezed
abstract class AuthTokensModel with _$AuthTokensModel {
  const factory AuthTokensModel({
    required String token,
    required String refreshToken,
  }) = _AuthTokensModel;

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensModelFromJson(json);
}
