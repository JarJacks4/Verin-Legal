// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<dynamic> summarizeItems(List<ItemsRecord> allItems) async {
  // Add your function code here!
  return {
    'received': allItems.length,
    'processed': allItems.where((i) => i.state == 'processed').length,
    'uncertain': allItems.where((i) => i.state == 'uncertain').length,
  };
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
