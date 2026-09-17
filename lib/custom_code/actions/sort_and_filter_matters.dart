// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<MattersRecord>> sortAndFilterMatters(
  List<MattersRecord> matters,
  String statusFilter,
  String matterTypeFilter,
  String sortOption,
) async {
  // Add your function code here!
  var result = matters.where((m) {
    final statusOk = statusFilter == 'All' || m.status == statusFilter;
    final typeOk =
        matterTypeFilter == 'All Types' || m.matterType == matterTypeFilter;
    return statusOk && typeOk;
  }).toList();

  switch (sortOption) {
    case 'Oldest First':
      result.sort((a, b) => a.openedAt.compareTo(b.openedAt));
      break;
    case 'Client Name (A-Z)':
      result.sort((a, b) => a.clientName.compareTo(b.clientName));
      break;
    case 'Newest First':
    default:
      result.sort((a, b) => b.openedAt.compareTo(a.openedAt));
  }
  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
