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
      result.sort((a, b) =>
          (a.openedAt ?? DateTime(0)).compareTo(b.openedAt ?? DateTime(0)));
      break;
    case 'Client Name (A-Z)':
      result.sort((a, b) => a.clientName.compareTo(b.clientName));
      break;
    case 'Newest First':
    default:
      result.sort((a, b) =>
          (b.openedAt ?? DateTime(0)).compareTo(a.openedAt ?? DateTime(0)));
  }
  return result;
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
