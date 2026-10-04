// Verin Legal — small formatting helpers shared by hand-written screens.

import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

String fmtDate(DateTime? d) => d == null ? '' : DateFormat('MMM d, y').format(d);

String fmtDateTime(DateTime? d) => d == null ? '' : DateFormat('MMM d, y · h:mm a').format(d);

String fmtShortDateTime(DateTime? d) => d == null ? '' : DateFormat('M/d h:mm a').format(d);

/// "3 minutes ago" / "in 2 days". Empty string when [d] is null.
String fmtRelative(DateTime? d) => d == null ? '' : timeago.format(d, allowFromNow: true);

/// 492 -> "8:12", 3725 -> "1:02:05".
String fmtDuration(int seconds) {
  if (seconds <= 0) return '0:00';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// First 10 + last 6 characters of a hex hash.
String shortHash(String h) {
  if (h.length <= 20) return h;
  return '${h.substring(0, 10)}…${h.substring(h.length - 6)}';
}

/// "Elena Whitmore" -> "EW". Falls back to the first letter of an email.
String initialsFor(String name, {String email = ''}) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) {
    return email.isNotEmpty ? email[0].toUpperCase() : '?';
  }
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts.first[0] + parts.last[0]).toUpperCase();
}

String pluralize(int n, String singular, [String? plural]) =>
    '$n ${n == 1 ? singular : (plural ?? '${singular}s')}';

/// Median of a list of numbers; null when empty.
double? median(List<num> values) {
  if (values.isEmpty) return null;
  final v = values.map((e) => e.toDouble()).toList()..sort();
  final mid = v.length ~/ 2;
  return v.length.isOdd ? v[mid] : (v[mid - 1] + v[mid]) / 2.0;
}
