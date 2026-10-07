import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> saveTextFile(String fileName, String text, {String mime = 'text/plain'}) async {
  // UTF-8 byte-order mark so Excel reads accented names correctly.
  final bytes = utf8.encode('﻿$text');
  final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: '$mime;charset=utf-8'));
  final url = web.URL.createObjectURL(blob);
  final a = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = fileName;
  web.document.body?.append(a);
  a.click();
  a.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
