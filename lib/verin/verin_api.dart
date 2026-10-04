// Verin Legal — calls into the Cloud Functions in firebase/functions/verin.
//
// Unlike FlutterFlow's makeCloudCall (which swallows errors and returns {}),
// every method here throws a VerinApiException with a message that's safe to
// show the user, so a failed upload or Clio push is never mistaken for success.

import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

class VerinApiException implements Exception {
  VerinApiException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}

class VerinApi {
  static Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data, {
    Duration timeout = const Duration(seconds: 70),
  }) async {
    try {
      final res = await FirebaseFunctions.instance
          .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
          .call(data);
      final d = res.data;
      return d is Map ? Map<String, dynamic>.from(d) : <String, dynamic>{};
    } on FirebaseFunctionsException catch (e) {
      throw VerinApiException(
        (e.message == null || e.message!.isEmpty) ? 'Request failed (${e.code}).' : e.message!,
        code: e.code,
      );
    } catch (e) {
      throw VerinApiException('Request failed: $e');
    }
  }

  // ---------------------------------------------------------------- evidence

  /// Uploads one screenshot to a matter. The server stores the original bytes,
  /// hashes them, adds the receipt to the matter's hash chain, and extracts
  /// the message thread with Claude. Returns
  /// { receiptId, status, messageCount, platform, errors, itemHash, entryHash,
  ///   chainSeq, isDuplicate }.
  static Future<Map<String, dynamic>> ingestScreenshot({
    required String matterId,
    required Uint8List bytes,
    required String fileName,
    String clientSide = 'right',
  }) {
    return _call(
      'ingestScreenshot',
      {
        'matterId': matterId,
        'imageBase64': base64Encode(bytes),
        'fileName': fileName,
        'clientSide': clientSide,
      },
      timeout: const Duration(seconds: 180),
    );
  }

  /// Re-runs extraction on an existing receipt (e.g. after a failure).
  static Future<Map<String, dynamic>> retryExtraction(String receiptId, {String clientSide = 'right'}) {
    return _call(
      'extractThreadMessages',
      {'collection': 'Receipts', 'docId': receiptId, 'clientSide': clientSide},
      timeout: const Duration(seconds: 180),
    );
  }

  /// Recomputes the matter's hash chain server-side. Returns
  /// { ok, totalEntries, verifiedEntries, legacyEntries, head, storedHead,
  ///   headMatches, brokenAt, reason }.
  static Future<Map<String, dynamic>> verifyMatterChain(String matterId) =>
      _call('verifyMatterChain', {'matterId': matterId});

  /// Builds the matter's record PDF (certificate of preparation, exhibit index,
  /// thread transcript, hash-chain appendix) server-side and stores it.
  /// Returns { storagePath, downloadUrl, sha256, generatedAt, fileName }.
  static Future<Map<String, dynamic>> exportMatterRecord(String matterId) =>
      _call('exportMatterRecord', {'matterId': matterId}, timeout: const Duration(seconds: 120));

  // ---------------------------------------------------------------- Clio

  /// Returns the Clio authorize URL to open in the browser.
  static Future<String> clioAuthStart() async {
    final r = await _call('clioAuthStart', {});
    final url = r['url'];
    if (url is! String || url.isEmpty) throw VerinApiException('Clio did not return a sign-in link.');
    return url;
  }

  static Future<void> clioDisconnect() => _call('clioDisconnect', {});

  /// Each result: { id, displayNumber, description, status, clientName }.
  static Future<List<Map<String, dynamic>>> clioSearchMatters(String query) async {
    final r = await _call('clioSearchMatters', {'query': query});
    final list = r['matters'];
    if (list is! List) return [];
    return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
  }

  static Future<Map<String, dynamic>> clioLinkMatter({required String matterId, required String clioMatterId}) =>
      _call('clioLinkMatter', {'matterId': matterId, 'clioMatterId': clioMatterId});

  /// Uploads a file already in Firebase Storage into the linked Clio matter.
  static Future<Map<String, dynamic>> clioPushDocument({
    required String matterId,
    required String storagePath,
    String? documentName,
  }) =>
      _call(
        'clioPushDocument',
        {'matterId': matterId, 'storagePath': storagePath, if (documentName != null) 'documentName': documentName},
        timeout: const Duration(seconds: 120),
      );
}
