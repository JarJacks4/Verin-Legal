// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> bucketByWeekday(List<ItemsRecord> items) async {
  // Add your function code here!
  const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  final counts = List<int>.filled(7, 0);
  for (final item in items) {
    final weekday=item.recievedAt!.weekday;
   // final weekday = item.receivedAt!.weekday; // 1 = Monday .. 7 = Sunday
    counts[weekday - 1] += 1;
  }
  return List.generate(7, (i) => {'day': labels[i], 'count': counts[i]});
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
