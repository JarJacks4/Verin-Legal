// Verin Legal — pick a screenshot file (bytes + name) on web, desktop or mobile.

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class PickedImage {
  PickedImage(this.name, this.bytes);
  final String name;
  final Uint8List bytes;
}

/// Opens the system file picker for images. Returns an empty list if the user
/// cancels. Files whose bytes couldn't be read are skipped.
Future<List<PickedImage>> pickScreenshots({bool allowMultiple = true}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'gif'],
    allowMultiple: allowMultiple,
    withData: true,
  );
  if (result == null) return const [];
  final out = <PickedImage>[];
  for (final f in result.files) {
    final b = f.bytes;
    if (b != null && b.isNotEmpty) out.add(PickedImage(f.name, b));
  }
  return out;
}
