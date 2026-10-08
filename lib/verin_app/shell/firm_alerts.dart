// What sits between the shell and every page:
//
//   two-step requirement   when the firm requires two-step sign-in and this
//                          account has not set it up (#31)
//   firm alerts            provisioning failures (#15), sends that were too
//                          large or could not be collected (#29), deliveries
//                          that failed (#16) — until someone marks them done

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../auth/two_step.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';

class FirmGates extends StatefulWidget {
  const FirmGates({super.key, required this.firm, required this.child});

  final FirmAccountRecord? firm;
  final Widget child;

  @override
  State<FirmGates> createState() => _FirmGatesState();
}

class _FirmGatesState extends State<FirmGates> {
  Future<bool>? _twoStep;

  bool get _required => widget.firm?.snapshotData['requireTwoStep'] == true;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.firm != null) FirmAlertsBanner(firm: widget.firm!),
        Expanded(child: widget.child),
      ],
    );
    if (!_required) return body;
    _twoStep ??= hasTwoStep();
    return FutureBuilder<bool>(
      future: _twoStep,
      builder: (context, s) {
        if (!s.hasData) return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
        if (s.data == true) return body;
        return TwoStepRequired(
          onDone: () => setState(() {
            _twoStep = hasTwoStep();
          }),
          onSignOut: () async {
            final router = GoRouter.of(context);
            router.prepareAuthEvent();
            await authManager.signOut();
            router.clearRedirectLocation();
            router.goNamed('FirmWorkspaceSignIn');
          },
        );
      },
    );
  }
}

class FirmAlert {
  FirmAlert(this.ref, Map<String, dynamic> d)
      : kind = d['kind'] is String ? d['kind'] as String : '',
        message = d['message'] is String ? d['message'] as String : '',
        severity = d['severity'] is String ? d['severity'] as String : 'warning',
        count = d['count'] is num ? (d['count'] as num).toInt() : 1;

  final DocumentReference ref;
  final String kind, message, severity;
  final int count;
}

class FirmAlertsBanner extends StatefulWidget {
  const FirmAlertsBanner({super.key, required this.firm});

  final FirmAccountRecord firm;

  @override
  State<FirmAlertsBanner> createState() => _FirmAlertsBannerState();
}

class _FirmAlertsBannerState extends State<FirmAlertsBanner> {
  late Stream<List<FirmAlert>> _alerts = _stream();
  bool _open = false;

  Stream<List<FirmAlert>> _stream() => widget.firm.reference
      .collection('alerts')
      .where('resolved', isEqualTo: false)
      .limit(20)
      .snapshots()
      .map((s) => s.docs.map((d) => FirmAlert(d.reference, d.data())).toList());

  @override
  void didUpdateWidget(covariant FirmAlertsBanner old) {
    super.didUpdateWidget(old);
    if (old.firm.reference.path != widget.firm.reference.path) _alerts = _stream();
  }

  Future<void> _resolve(FirmAlert a) async {
    try {
      await a.ref.update({'resolved': true, 'resolvedByUid': currentUserUid, 'resolvedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      if (mounted) showVToast(context, 'Could not mark it done', error: true, description: '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<FirmAlert>>(
      stream: _alerts,
      builder: (context, s) {
        final list = s.data ?? const <FirmAlert>[];
        if (list.isEmpty) return const SizedBox.shrink();
        final error = list.any((a) => a.severity == 'error');
        final tone = error ? c.broken : c.pending;
        return Container(
          decoration: BoxDecoration(color: tone.withValues(alpha: 0.08), border: Border(bottom: BorderSide(color: tone.withValues(alpha: 0.3)))),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InkWell(
                onTap: () => setState(() => _open = !_open),
                child: Row(
                  children: [
                    Icon(Icons.notification_important_outlined, size: 16.0, color: tone),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        list.length == 1 ? list.first.message : '${list.length} things need attention',
                        maxLines: _open ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: VT.body(context, size: 12.5, color: c.foreground),
                      ),
                    ),
                    if (list.length == 1)
                      TextButton(onPressed: () => _resolve(list.first), child: Text('Done', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: tone)))
                    else
                      Icon(_open ? Icons.expand_less : Icons.expand_more, size: 18.0, color: tone),
                  ],
                ),
              ),
              if (_open && list.length > 1)
                for (final a in list)
                  Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text('${a.message}${a.count > 1 ? ' (${a.count}×)' : ''}', style: VT.body(context, size: 12.0))),
                        TextButton(onPressed: () => _resolve(a), child: Text('Done', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: tone))),
                      ],
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
