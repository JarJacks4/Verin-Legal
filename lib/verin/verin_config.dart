// Verin Legal — app-wide constants for hand-written code.

import '/auth/firebase_auth/auth_util.dart';

/// The firm every matter is filed under while the app is single-tenant.
/// The Matters list and the Cloud Functions' DEFAULT_FIRM_ID use the same
/// value; change all three together (or add `firmID` to users docs).
const String kDefaultFirmId = 'harbow-law';

/// The current user's firm: users/{uid}.firmID when present, else the default.
String currentFirmId() {
  final data = currentUserDocument?.snapshotData;
  final v = data == null ? null : (data['firmID'] ?? data['firmId']);
  return (v is String && v.trim().isNotEmpty) ? v.trim() : kDefaultFirmId;
}

/// Industry baseline record lag (days), shown as a reference line (guide §1e).
const int kBaselineRecordLagDays = 218;

/// Below this extraction confidence a message is flagged for review.
const double kLowConfidence = 0.75;

/// Largest screenshot the extraction function accepts.
const int kMaxScreenshotBytes = 7 * 1024 * 1024;
