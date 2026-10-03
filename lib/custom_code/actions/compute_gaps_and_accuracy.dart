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

Future<dynamic> computeGapsAndAccuracy(List<ItemsRecord> allItems) async {
  // Add your function code here!
  var gaps = 0;
  var confidenceSum = 0.0;
  var confidenceCount = 0;
  for (final item in allItems) {
    for (final msg in item.threadMessages) {
      if (msg.isHeader) continue;
      if (msg.isGap) gaps += 1;
      confidenceSum += msg.confidence;
      confidenceCount += 1;
    }
  }
  final avgAccuracy =
      confidenceCount == 0 ? 0.0 : confidenceSum / confidenceCount;
  return {'gaps': gaps, 'avgAccuracy': avgAccuracy};
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
