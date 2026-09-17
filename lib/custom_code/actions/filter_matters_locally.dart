// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<MattersRecord>> filterMattersLocally(
  List<MattersRecord> mattersList,
  String searchText,
) async {
  // Add your function code here!
  if (searchText.isEmpty) return mattersList;
  final q = searchText.toLowerCase();
  return mattersList
      .where((m) =>
          m.clientName.toLowerCase().contains(q) ||
          m.matterName.toLowerCase().contains(q))
      .toList();
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
