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
// countScreenRecordingReceipts. No extra packages needed.
//
// Backs the third video-summary chip on the matter header (see
// summarizeVideoReceipts.dart, which backs chips 1 and 2) — a plain count
// of screen-recording receipts, kept as its own action rather than a
// fourth return value on summarizeVideoReceipts because a screen
// recording is its own itemKind, not a video sub-type, and folding it
// into that action's List<int> would make index 0/1/2 mean three
// unrelated things depending on which chip is reading it.
//
// Returns a single Integer. Bind chip 3 directly to this result, and
// only show that chip when the result is greater than 0 (same
// only-show-if-nonzero pattern already used for summarizeVideoReceipts'
// transcoded-in-transit count).

Future<int> countScreenRecordingReceipts(List<ReceiptsRecord> receipts) async {
  var count = 0;
  for (final r in receipts) {
    if (r.itemKind == 'screen_recording') count++;
  }
  return count;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
