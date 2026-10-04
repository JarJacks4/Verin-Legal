// Holds the signed-in app until the account belongs to a firm.
//
// Every screen scopes its queries to the user's firmID, and the security
// rules refuse anything else, so nothing below this gate is built until
// users/{uid}.firmID exists. If it doesn't yet (an interrupted sign-up, or an
// account from before firms were separated), the gate asks setupAccount to
// finish the job. The subtree is keyed by firm so it rebuilds if that changes.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/auth/auth_actions.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import 'app_shell.dart' show signOutAndLeave;

class FirmGate extends StatefulWidget {
  const FirmGate({super.key, required this.child});

  final Widget child;

  @override
  State<FirmGate> createState() => _FirmGateState();
}

class _FirmGateState extends State<FirmGate> {
  late final Stream<UsersRecord?> _user = currentUserStream();
  bool _asked = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Once per session even when the firm is set: runs the one-time data
    // migration for firms created before separation.
    ensureFirmSetup().then((err) {
      if (mounted && err != null) setState(() => _error = err);
    });
    _asked = true;
  }

  Future<void> _retry() async {
    setState(() => _error = null);
    final err = await ensureFirmSetup(force: true);
    if (mounted && err != null) setState(() => _error = err);
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<UsersRecord?>(
      stream: _user,
      builder: (context, snap) {
        final data = snap.data?.snapshotData;
        final v = data == null ? null : data['firmID'];
        final firmId = v is String ? v.trim() : '';
        if (firmId.isNotEmpty) {
          // Screens below read the firm through currentFirmId(); make sure the
          // global user record is this fresh one before they build.
          if (snap.data != null) currentUserDocument = snap.data;
          return KeyedSubtree(key: ValueKey('firm:$firmId'), child: widget.child);
        }
        return Scaffold(
          backgroundColor: c.background,
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420.0),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _error == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const VLoading(),
                          Text(_asked ? 'Setting up your firm workspace…' : 'Loading…', style: VT.muted(context)),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          VErrorBox(message: _error!),
                          const SizedBox(height: 16.0),
                          VButton(label: 'Try again', fullWidth: true, onPressed: _retry),
                          const SizedBox(height: 8.0),
                          VButton(label: 'Sign out', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => signOutAndLeave(context)),
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
