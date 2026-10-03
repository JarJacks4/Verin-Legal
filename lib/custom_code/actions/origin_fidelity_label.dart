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
// originFidelityLabel. No extra packages needed.
//
// Backs the Spec §8 compliant sentence in the video receipt detail drawer
// (Figma-to-FlutterFlow Integration Guide §6.2/§6.4) — maps the raw
// origin_fidelity enum value to the plain-word phrase that sentence
// interpolates. Named in that guide's §6.4 wiring notes but never written
// out until now.

Future<String> originFidelityLabel(String? originFidelity) async {
  switch (originFidelity) {
    case 'as_sent':
      return 'sent exactly as recorded';
    case 'transcoded_in_transit':
      return 'transcoded during transit';
    default:
      return 'undetermined';
  }
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
