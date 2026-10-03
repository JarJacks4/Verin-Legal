// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<List<dynamic>> mergeThreadMessages(List<ReceiptsRecord> receipts) async {
  final merged = <Map<String, dynamic>>[];

  for (final r in receipts) {
    for (final raw in (r.threadMessages)) {
      final msg = Map<String, dynamic>.from(raw as Map);
      msg['isFromClient'] = msg['speaker'] == 'client';
      merged.add(msg);
    }
  }

  merged.sort((a, b) {
    final aLabel = (a['timestampLabel'] as String?) ?? '';
    final bLabel = (b['timestampLabel'] as String?) ?? '';
    if (aLabel.isEmpty && bLabel.isEmpty) return 0;
    if (aLabel.isEmpty) return -1;
    if (bLabel.isEmpty) return 1;
    return aLabel.compareTo(bLabel);
  });

  return merged;
}
