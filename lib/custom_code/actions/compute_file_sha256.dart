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
// Paste into: Custom Code -> Actions -> + Add Action -> name it
// computeFileSha256. Needs one dependency added first:
//   Custom Code -> Dependencies (or your project's pubspec section) ->
//   add "crypto" (any recent 3.x version).
// Then in this action's own "Imports" tab, add:
//   import 'package:crypto/crypto.dart';
//
// What it does: hashes a staged file's bytes at intake, the same way every
// other evidence path in this project (email/SMS/WhatsApp ingestion,
// manual screenshot upload) is expected to produce an item_hash — this is
// the manual-upload-during-matter-creation version of that same step.

import 'package:crypto/crypto.dart';

Future<String> computeFileSha256(FFUploadedFile file) async {
  final bytes = file.bytes;
  if (bytes == null) {
    throw Exception(
        'computeFileSha256: file has no bytes to hash — check the Upload File widget is set to keep bytes in memory, not just a path.');
  }
  return sha256.convert(bytes).toString();
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
