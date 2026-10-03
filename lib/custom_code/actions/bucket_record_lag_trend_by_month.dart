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
// bucketRecordLagTrendByMonth. No extra packages needed.
//
// Backs the Admin Portal Dashboard's "Record Lag Trend" line chart
// (Complete FlutterFlow Build Guide §5.2) — same median-gap math as
// computeRecordLagDays (Figma-to-FlutterFlow Integration Guide §6.5), but
// bucketed by month instead of collapsed into one firm-wide number, so
// the chart can show a real trend over time rather than a single point.
//
// The "before Verin" comparison line the Figma design shows alongside
// this isn't computed here — 218 days is a fixed industry-baseline
// constant (Complete FlutterFlow Build Guide §5.6), not something this
// function derives, so render it as a flat reference line at that
// constant value rather than a second real data series.
//
// Returns a List<String>, one entry per month that has at least one
// qualifying receipt, chronologically ordered, formatted as
// "label|medianDays" (e.g. "Feb 2026|19"). Same self-contained,
// no-shared-top-level-declarations approach as
// bucketEvidenceVolumeByMonth.dart, for the same reason.

Future<List<String>> bucketRecordLagTrendByMonth(
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

  final gapsByMonth = <String, List<int>>{};
  for (final r in receipts) {
    final resolved = r.resolvedDate;
    final received = r.receivedAt;
    if (resolved == null || received == null) continue;
    final key = '${received.year}-${received.month.toString().padLeft(2, '0')}';
    gapsByMonth
        .putIfAbsent(key, () => [])
        .add(received.difference(resolved).inDays.abs());
  }

  final sortedKeys = gapsByMonth.keys.toList()..sort();
  return sortedKeys.map((key) {
    final gaps = gapsByMonth[key]!..sort();
    final mid = gaps.length ~/ 2;
    final median = gaps.length.isOdd
        ? gaps[mid]
        : ((gaps[mid - 1] + gaps[mid]) / 2).round();
    final parts = key.split('-');
    final year = parts[0];
    final month = int.parse(parts[1]);
    return '${months[month - 1]} $year|$median';
  }).toList();
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
