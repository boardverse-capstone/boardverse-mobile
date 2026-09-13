import 'package:intl/intl.dart';

/// Centralized date/time formatting utilities for the entire application.
///
/// All DateTime → String conversions for UI display should go through this
/// class to ensure consistent formatting across the app.
///
/// Usage:
///
/// ```dart
/// DateFormatter.timeOnly(dateTime)        // "14:30"
/// DateFormatter.dateOnly(dateTime)        // "24/08/2026"
/// DateFormatter.dateTime(dateTime)        // "14:30 • 24/08"
/// DateFormatter.fullDate(dateTime)       // "Chủ nhật, 24/08/2026"
/// DateFormatter.fullDateTime(dateTime)    // "14:30 • 24/08/2026"
/// DateFormatter.dateTimeSeconds(dateTime) // "14:30 • 24/08/2026"
/// DateFormatter.timeAgo(dateTime)         // "2 giờ trước"
/// ```
///
/// For locales other than Vietnamese, use the raw `DateFormat` constructor
/// with the desired locale string.
class DateFormatter {
  DateFormatter._();

  /// Vietnamese locale identifier used throughout the app.
  static const String viLocale = 'vi';

  /// Time only: "14:30"
  static final _timeFormat = DateFormat('HH:mm');

  /// Date only: "24/08/2026"
  static final _dateFormat = DateFormat('dd/MM/yyyy');

  /// Date + time compact: "14:30 • 24/08"
  static final _dateTimeFormat = DateFormat('HH:mm • dd/MM');

  /// Full date with weekday (Vietnamese): "Chủ nhật, 24/08/2026"
  static final _fullDateFormat = DateFormat('EEEE, dd/MM/yyyy', viLocale);

  /// Full date + time: "14:30 • 24/08/2026"
  static final _fullDateTimeFormat = DateFormat('HH:mm • dd/MM/yyyy');

  /// ─── Formatters ────────────────────────────────────────────────────────

  /// "14:30"
  static String timeOnly(DateTime dt) => _timeFormat.format(dt.toLocal());

  /// "24/08/2026"
  static String dateOnly(DateTime dt) => _dateFormat.format(dt.toLocal());

  /// "14:30 • 24/08"
  static String dateTime(DateTime dt) =>
      _dateTimeFormat.format(dt.toLocal());

  /// "Chủ nhật, 24/08/2026" (Vietnamese weekday)
  static String fullDate(DateTime dt) => _fullDateFormat.format(dt.toLocal());

  /// "14:30 • 24/08/2026"
  static String fullDateTime(DateTime dt) =>
      _fullDateTimeFormat.format(dt.toLocal());

  /// Alias for [fullDateTime] — kept for backward compatibility.
  static String dateTimeSeconds(DateTime dt) => fullDateTime(dt);

  /// ─── Relative time ─────────────────────────────────────────────────────

  /// Formats `time` as a Vietnamese relative string.
  ///
  /// Returns "X ngày trước", "X giờ trước", "X phút trước", or "Vừa xong".
  /// The optional `now` parameter supports deterministic testing.
  static String timeAgo(DateTime time, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(time);
    if (diff.inDays > 0) return '${diff.inDays} ngày trước';
    if (diff.inHours > 0) return '${diff.inHours} giờ trước';
    if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    return 'Vừa xong';
  }

  /// ─── HH:mm from HH:mm:ss ───────────────────────────────────────────────

  /// Strips seconds from an "HH:mm:ss" string, returning "HH:mm".
  ///
  /// Used when the server returns time as a full-day time string (e.g.
  /// `preferredEndTime: "19:30:00"`) but the UI only needs hour and minute.
  static String stripSeconds(String? hhmmSS) {
    if (hhmmSS == null || hhmmSS.isEmpty) return '';
    final parts = hhmmSS.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return hhmmSS;
  }
}
