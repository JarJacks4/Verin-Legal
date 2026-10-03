// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Verin Legal — FlutterFlow Custom Action
// Paste into: Custom Code -> Actions -> + Add Action, name it
// bucketEvidenceVolumeByMonth. No extra packages needed.
//
// Backs the Admin Portal Dashboard's "Evidence Volume" bar chart
// (Complete FlutterFlow Build Guide §5.2) — buckets every receipt by the
// month it was received and counts them, in the small shape a chart
// widget can actually bind to.
//
// Returns a List<String>, one entry per month in chronological order,
// each formatted as "label|count" (e.g. "Feb 2026|41"). Split each
// string on "|" wherever your chart widget's data-point config needs the
// two halves separately — the exact binding mechanics depend on which
// chart widget/plugin you're using, so this deliberately stops at
// producing clean, sorted data rather than assuming a specific widget's
// input shape.
//
// Deliberately has no shared top-level class or constant with
// bucketRecordLagTrendByMonth.dart, even though they're closely related —
// two custom actions defining the same top-level name is exactly the
// "duplicate declaration" bug already hit once in this project's Figma
// build (the Recharts/Babel crash fixed in Version 31). Keeping each
// action fully self-contained avoids that here.

Future<List<String>> bucketEvidenceVolumeByMonth(
    List<ReceiptsRecord> receipts) async {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];

  final counts = <String, int>{};
  for (final r in receipts) {
    final d = r.receivedAt;
    if (d == null) continue;
    final key = '${d.year}-${d.month.toString().padLeft(2, '0')}';
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final sortedKeys = counts.keys.toList()..sort();
  return sortedKeys.map((key) {
    final parts = key.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    return '${months[month - 1]} $year|${counts[key]}';
  }).toList();
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
