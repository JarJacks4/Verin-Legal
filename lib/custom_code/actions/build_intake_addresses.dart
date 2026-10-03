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

Future<dynamic> buildIntakeAddresses(String token) async {
  // Add your function code here!
  return {
    'email': '${token.toLowerCase()}@intake.verinrecords.com',
    'sms': '+1 (317) 555-01${token.substring(0, 2)}',
    'whatsapp': '+1 (317) 555-01${token.substring(0, 2)}',
  };
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the `</>` button on the right!
