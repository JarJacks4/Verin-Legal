// Verin Legal — email/password sign-up and sign-in used by the auth pages.
// Each returns null on success or a message to show under the form.

import 'package:firebase_auth/firebase_auth.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

import '../verin_api.dart';
import 'auth_shell.dart';

Future<String?> verinSignUp({
  required String email,
  required String password,
  required String fullName,
  required String firmName,
  required String role,
  String inviteId = '',
}) async {
  try {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) return 'Account could not be created. Please try again.';

    try {
      await user.updateDisplayName(fullName.trim());
    } catch (_) {/* cosmetic only */}

    await maybeCreateUser(user);
    final ref = UsersRecord.collection.doc(user.uid);
    await ref.set(
      {
        ...createUsersRecordData(
          email: user.email ?? email.trim(),
          displayName: fullName.trim(),
          uid: user.uid,
          lawFirm: inviteId.isEmpty ? firmName.trim() : null,
        ),
        // Job title. Firm membership and access role are set by the server.
        'title': role.trim(),
      },
      SetOptions(merge: true),
    );
    // Creates the firm (or joins the inviting one). If this fails the app's
    // firm gate retries and shows what went wrong.
    await ensureFirmSetup(
      force: true,
      firmName: firmName,
      fullName: fullName,
      title: role,
      inviteId: inviteId,
    );
    currentUserDocument = await UsersRecord.getDocumentOnce(ref);
    SignupDraft.clear();
    return null;
  } on FirebaseAuthException catch (e) {
    return authErrorMessage(e.code, e.message);
  } on FirebaseException catch (e) {
    // Account exists but the profile write failed (rules / network).
    return 'Your account was created, but saving your profile failed (${e.code}). '
        'Sign in and update your profile from the menu.';
  } catch (e) {
    return 'Account could not be created: $e';
  }
}

Future<String?> verinSignIn({required String email, required String password}) async {
  try {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user;
    if (user == null) return 'Sign-in failed. Please try again.';
    await maybeCreateUser(user);
    _setup = null; // new session: let the firm gate run setup again
    return null;
  } on FirebaseAuthException catch (e) {
    return authErrorMessage(e.code, e.message);
  } catch (e) {
    return 'Sign-in failed: $e';
  }
}

Future<String?>? _setup;
String? _setupFor;

/// Makes sure the signed-in account belongs to a firm (see setupAccount in
/// the Cloud Functions). Runs at most once per session unless [force]d;
/// concurrent callers share one request. Returns null on success or a
/// message to show.
Future<String?> ensureFirmSetup({
  bool force = false,
  String firmName = '',
  String fullName = '',
  String title = '',
  String inviteId = '',
}) {
  final uid = currentUserUid;
  if (uid.isEmpty) return Future.value('Sign in first.');
  if (!force && _setup != null && _setupFor == uid) return _setup!;
  _setupFor = uid;
  final doc = currentUserDocument;
  final f = () async {
    try {
      await VerinApi.setupAccount(
        firmName: firmName.isNotEmpty ? firmName : (doc?.lawFirm ?? ''),
        fullName: fullName,
        title: title,
        inviteId: inviteId,
      );
      return null;
    } on VerinApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Could not set up your firm workspace: $e';
    }
  }();
  _setup = f;
  // A failure shouldn't stick for the whole session.
  f.then((err) {
    if (err != null && identical(_setup, f)) _setup = null;
  });
  return f;
}

Future<String?> verinResetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    return null;
  } on FirebaseAuthException catch (e) {
    return authErrorMessage(e.code, e.message);
  }
}
