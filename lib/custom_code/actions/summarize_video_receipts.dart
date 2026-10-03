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
// summarizeVideoReceipts. No extra packages needed.
//
// Backs the video summary chip row on the matter header (Figma v29,
// Figma-to-FlutterFlow Integration Guide §6.3/§6.4) — count of video
// receipts, their total duration, and how many arrived already
// transcoded in transit, in one pass instead of three chained native
// aggregate actions. Named in that guide's §6.4 wiring notes but never
// written out until now.
//
// Returns a plain List<int> of exactly 3 values rather than a custom
// class, deliberately — a custom return class works in FlutterFlow, but
// it means FlutterFlow auto-generates a matching Data Type the moment you
// paste this in, and that's one more moving part than this needs. Bind
// the three chips directly to this result's indices:
//   result[0] -> video count           (e.g. "3 videos")
//   result[1] -> total duration seconds (format as minutes:seconds in the
//                chip's own text binding, e.g. "8:12 total")
//   result[2] -> transcoded-in-transit count (only show that chip when
//                this is greater than 0)

Future<List<int>> summarizeVideoReceipts(List<ReceiptsRecord> receipts) async {
  var count = 0;
  var totalDurationSeconds = 0;
  var transcodedInTransitCount = 0;

  for (final r in receipts) {
    if (r.itemKind != 'video') continue;
    count++;
    totalDurationSeconds += (r.durationSeconds ?? 0);
    if (r.originFidelity == 'transcoded_in_transit') transcodedInTransitCount++;
  }

  return [count, totalDurationSeconds, transcodedInTransitCount];
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
