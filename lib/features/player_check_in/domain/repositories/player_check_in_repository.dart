import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/player_scan_result_entity.dart';

/// Repository cho player-initiated check-in (BR §21A.7 — PlayerCheckInController).
///
/// Tách riêng khỏi `ReservationRepository` vì endpoint `/api/check-in/scan-qr`
/// thuộc controller riêng (`PlayerCheckInController`) và có semantics khác
/// (`token` do POS cấp, một lần, không thuộc canonical check-in flow).
abstract class PlayerCheckInRepository {
  /// Player gửi token 16-char in hoa (alphanumeric, loại trừ 0/1/I/O) cho
  /// backend → nhận về thông tin ActiveSession vừa khởi tạo.
  ///
  /// Idempotent cho cùng (player, token): re-scan trả về cùng result.
  /// Tuy nhiên backend trả 409 nếu token đã được consume bởi user khác.
  Future<Either<Failure, PlayerScanResultEntity>> scanToken({
    required String token,
  });

  /// Validate format token trước khi gửi request, tránh 400 noisy.
  /// Token phải đúng 16 ký tự, chỉ chứa [A-Z2-9] (loại trừ 0/1/I/O).
  static bool isValidTokenFormat(String? raw) {
    if (raw == null) return false;
    final token = raw.trim().toUpperCase();
    if (token.length != 16) return false;
    final regex = RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{16}$');
    return regex.hasMatch(token);
  }

  /// Normalize token: trim + uppercase. Trả về null nếu rỗng.
  static String? normalize(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim().toUpperCase();
    return cleaned.isEmpty ? null : cleaned;
  }
}
