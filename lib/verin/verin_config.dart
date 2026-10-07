// Verin Legal — app-wide constants for hand-written code.

import '/auth/firebase_auth/auth_util.dart';

/// The signed-in user's firm (users/{uid}.firmID, set by the setupAccount
/// Cloud Function). Empty until setup finishes — never a shared default, so
/// queries made too early simply match nothing.
String currentFirmId() {
  final data = currentUserDocument?.snapshotData;
  final v = data == null ? null : data['firmID'];
  return (v is String && v.trim().isNotEmpty) ? v.trim() : '';
}

/// Industry baseline record lag (days), shown as a reference line (guide §1e).
const int kBaselineRecordLagDays = 218;

/// Below this extraction confidence a message is flagged for review.
const double kLowConfidence = 0.75;

/// Largest screenshot the extraction function accepts.
const int kMaxScreenshotBytes = 7 * 1024 * 1024;

/// Public legal pages on the marketing site, and the version a new account
/// accepts at sign-up (users/{uid}.termsVersion). Bump when the terms change.
const String kTermsUrl = 'https://www.verinlegal.com/terms';
const String kPrivacyUrl = 'https://www.verinlegal.com/privacy';
const String kTermsVersion = '2026-10';

/// Where firm staff reach Verin Legal support.
const String kSupportEmail = 'support@verinlegal.com';
