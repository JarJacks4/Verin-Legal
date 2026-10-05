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
      final raw = (e.message ?? '').trim();
      // A callable that isn't deployed (or crashed before answering) reaches
      // the browser as a bare "internal" / "not-found"; say what that means.
      if ((e.code == 'internal' && (raw.isEmpty || raw.toLowerCase() == 'internal')) || (e.code == 'not-found' && raw.toLowerCase() == 'not found')) {
        throw VerinApiException(
          "The Verin server didn't answer ($name). Deploy the backend functions (firebase deploy --only functions) and try again.",
          code: e.code,
        );
      }
      throw VerinApiException(raw.isEmpty ? 'Request failed (${e.code}).' : raw, code: e.code);
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

  /// Files evidence that the app has already uploaded to Storage under
  /// intake/{uid}/... (or a physical item with no file). The server hashes the
  /// exact bytes, moves them under the matter, timestamps the hash (RFC 3161),
  /// appends the receipt to the matter's hash chain, and queues AI reading.
  /// Returns { receiptId, itemHash, entryHash, chainSeq, isDuplicate }.
  static Future<Map<String, dynamic>> ingestEvidence({
    required String matterId,
    required String kind,
    String? uploadPath,
    String? fileName,
    String? contentType,
    String channel = 'upload',
    String fromLabel = '',
    String? dateReceived,
    String description = '',
    String custodyNotes = '',
    String clientSide = 'right',
  }) {
    return _call(
      'ingestEvidence',
      {
        'matterId': matterId,
        'kind': kind,
        if (uploadPath != null) 'uploadPath': uploadPath,
        if (fileName != null) 'fileName': fileName,
        if (contentType != null) 'contentType': contentType,
        'channel': channel,
        'fromLabel': fromLabel,
        if (dateReceived != null) 'dateReceived': dateReceived,
        'description': description,
        'custodyNotes': custodyNotes,
        'clientSide': clientSide,
      },
      timeout: const Duration(seconds: 540),
    );
  }

  /// Runs AI reading again for one receipt (failed or deferred items).
  static Future<Map<String, dynamic>> reprocessReceipt(String receiptId, {String clientSide = 'right', bool forceTranscription = false}) =>
      _call(
        'reprocessReceipt',
        {'receiptId': receiptId, 'clientSide': clientSide, 'forceTranscription': forceTranscription},
        timeout: const Duration(seconds: 540),
      );

  /// Builds the standalone-verifiable record archive (manifest.json,
  /// exhibits/, certificate.pdf, README.txt) and returns { downloadUrl,
  /// fileName, sha256, items }.
  static Future<Map<String, dynamic>> exportRecordZip(String matterId) =>
      _call('exportRecordZip', {'matterId': matterId}, timeout: const Duration(seconds: 540));

  /// Integration report PDF for one matter: { downloadUrl, fileName, sha256 }.
  static Future<Map<String, dynamic>> exportIntegrationReport(String matterId) =>
      _call('exportIntegrationReport', {'matterId': matterId}, timeout: const Duration(seconds: 120));

  /// Every matter's manifest in one ZIP: { downloadUrl, fileName, matters }.
  static Future<Map<String, dynamic>> exportFirmData() =>
      _call('exportFirmData', {}, timeout: const Duration(seconds: 540));

  /// Rebuilds a matter's reconstructed thread now (normally automatic).
  static Future<Map<String, dynamic>> refreshMatterRecord(String matterId) =>
      _call('refreshMatterRecord', {'matterId': matterId}, timeout: const Duration(seconds: 300));

  /// Produces a draft production: Bates-stamped exhibits, index and ZIP.
  static Future<Map<String, dynamic>> produceExhibits({required String matterId, required String productionId}) =>
      _call('produceExhibits', {'matterId': matterId, 'productionId': productionId}, timeout: const Duration(seconds: 540));

  // ---------------------------------------------------------------- account

  /// Attaches the signed-in account to a firm: joins the firm that invited
  /// this email, or creates a new firm with [firmName]. Returns
  /// { firmId, role, created, joined }.
  static Future<Map<String, dynamic>> setupAccount({String? firmName, String? fullName, String? title, String? inviteId}) =>
      _call('setupAccount', {
        if ((firmName ?? '').trim().isNotEmpty) 'firmName': firmName!.trim(),
        if ((fullName ?? '').trim().isNotEmpty) 'fullName': fullName!.trim(),
        if ((title ?? '').trim().isNotEmpty) 'title': title!.trim(),
        if ((inviteId ?? '').trim().isNotEmpty) 'inviteId': inviteId!.trim(),
      }, timeout: const Duration(seconds: 120));

  /// Deletes the signed-in account (the firm's records stay). Needs a sign-in
  /// within the last few minutes — reauthenticate first.
  static Future<void> deleteAccount() => _call('deleteAccount', {});

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
