import 'dart:math';

/// Generates a cryptographically random string, suitable for use as an
/// idempotency key.
///
/// Length: 32–36 characters (alphanumeric), well within the 8–128 limit.
/// Each invocation produces a unique value with negligible collision risk
/// (≈ 1 in 2.8×10¹⁴).
String generateIdempotencyKey() {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  const length = 36;

  final random = Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}
