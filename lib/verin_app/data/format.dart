// Date formatting matching the Make (en-US: "Jul 22, 2026, 6:14 PM").

String fmtWhen(DateTime? d) {
  if (d == null) return '—';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final mm = d.minute.toString().padLeft(2, '0');
  return '${months[d.month - 1]} ${d.day}, ${d.year}, $h:$mm ${d.hour < 12 ? 'AM' : 'PM'}';
}

String fmtDay(DateTime? d) {
  if (d == null) return '—';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// "October 4, 2026"
String fmtLongDay(DateTime? d) {
  if (d == null) return '—';
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}

/// "6:14 PM"
String fmtTime(DateTime? d) {
  if (d == null) return '—';
  final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
  return '$h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'}';
}

String fmtBytes(int b) {
  if (b <= 0) return '—';
  if (b >= 1024 * 1024 * 1024) return '${(b / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  if (b >= 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  return '${(b / 1024).toStringAsFixed(0)} KB';
}
