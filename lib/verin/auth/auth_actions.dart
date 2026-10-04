// Verin Legal — email/password sign-up and sign-in used by the auth pages.
// Each returns null on success or a message to show under the form.

import 'package:firebase_auth/firebase_auth.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';

import '../verin_config.dart';
import 'auth_shell.dart';

Future<String?> verinSignUp({
  required String email,
  required String password,
  required String fullName,
  required String firmName,
  required String role,
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
          role: role.trim(),
          lawFirm: firmName.trim(),
        ),
        'firmID': kDefaultFirmId,
      },
      SetOptions(merge: true),
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
    return null;
  } on FirebaseAuthException catch (e) {
    return authErrorMessage(e.code, e.message);
  } catch (e) {
    return 'Sign-in failed: $e';
  }
}

Future<String?> verinResetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
    return null;
  } on FirebaseAuthException catch (e) {
    return authErrorMessage(e.code, e.message);
  }
}
