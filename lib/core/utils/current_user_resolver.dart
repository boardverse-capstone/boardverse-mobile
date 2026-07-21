import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

/// JWT claim keys used by the .NET backend (XML Soap format).
class _JwtClaimKeys {
  static const String nameIdentifier =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier';
  static const String name =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/name';
  static const String email =
      'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress';
}

/// Reads the current user's id from the stored JWT access token.
///
/// Returns null when no token is stored, the token is expired, or the
/// `nameIdentifier` claim is missing. Decoded lazily so callers in widgets
/// don't pay the cost upfront.
class CurrentUserResolver {
  final FlutterSecureStorage _storage;

  CurrentUserResolver(this._storage);

  static const String _accessTokenKey = 'access_token';

  Future<String?> resolveUserId() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return null;
    if (JwtDecoder.isExpired(token)) return null;

    try {
      final claims = JwtDecoder.decode(token);
      return claims[_JwtClaimKeys.nameIdentifier] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveEmail() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return null;
    if (JwtDecoder.isExpired(token)) return null;

    try {
      final claims = JwtDecoder.decode(token);
      return claims[_JwtClaimKeys.email] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<String?> resolveUsername() async {
    final token = await _storage.read(key: _accessTokenKey);
    if (token == null || token.isEmpty) return null;
    if (JwtDecoder.isExpired(token)) return null;

    try {
      final claims = JwtDecoder.decode(token);
      return claims[_JwtClaimKeys.name] as String?;
    } catch (_) {
      return null;
    }
  }
}