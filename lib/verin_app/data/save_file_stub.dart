/// Returns false where the platform can't save a file; the caller copies.
Future<bool> saveTextFile(String fileName, String text, {String mime = 'text/plain'}) async => false;
