// Texts from numbers no matter knows yet. They are already stored and hashed
// (server side); a person picks the matter and Verin files them there.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_api.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart' show firmMattersStream;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

class UnroutedText {
  UnroutedText(this.id, Map<String, dynamic> d)
      : from = (d['from'] as String?) ?? '',
        body = (d['body'] as String?) ?? '',
        media = d['media'] is List ? (d['media'] as List).length : 0,
        at = (d['at'] as Timestamp?)?.toDate();
  final String id, from, body;
  final int media;
  final DateTime? at;
}

Stream<List<UnroutedText>> unroutedTextsStream() => FirebaseFirestore.instance
    .collection('UnroutedIntake')
    .where('firmID', isEqualTo: currentFirmId())
    .where('status', isEqualTo: 'open')
    .orderBy('at', descending: true)
    .limit(50)
    .snapshots()
    .map((s) => s.docs.map((d) => UnroutedText(d.id, d.data())).toList());

String prettyPhone(String e164) {
  final m = RegExp(r'^\+1(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '(${m[1]}) ${m[2]}-${m[3]}';
}

class UnroutedTexts extends StatefulWidget {
  const UnroutedTexts({super.key});

  @override
  State<UnroutedTexts> createState() => _UnroutedTextsState();
}

class _UnroutedTextsState extends State<UnroutedTexts> {
  late final Stream<List<UnroutedText>> _items = unroutedTextsStream();
  List<MattersRecord> _matterList = const [];
  late final _mattersSub = firmMattersStream().listen((m) {
    if (mounted) setState(() => _matterList = m);
  });

  @override
  void initState() {
    super.initState();
    _mattersSub;
  }

  @override
  void dispose() {
    _mattersSub.cancel();
    super.dispose();
  }
  final Set<String> _busy = {};

  Future<void> _file(UnroutedText t) async {
    final open = _matterList.where((m) => m.status != 'Closed').toList();
    final list = open.isEmpty ? _matterList : open;
    if (list.isEmpty) {
      showVToast(context, 'Create a matter first', error: true);
      return;
    }
    var pick = list.first;
    var remember = true;
    final ok = await showVDialog<bool>(
      context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('File this text', style: VT.h2(ctx, size: 18.0)),
            const SizedBox(height: 6.0),
            Text('From ${prettyPhone(t.from)}. It is hashed and added to the matter\'s record as received.', style: VT.muted(ctx, size: 13.0)),
            const SizedBox(height: 16.0),
            VSelect<MattersRecord>(
              label: 'Matter',
              value: pick,
              items: list,
              labelFor: (m) => [m.title.isEmpty ? 'Untitled matter' : m.title, if (m.clientName.isNotEmpty) m.clientName].join(' · '),
              onChanged: (m) => set(() => pick = m),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                VSwitch(value: remember, onChanged: (v) => set(() => remember = v)),
                const SizedBox(width: 8.0),
                Expanded(child: Text('File future texts from this number here automatically', style: VT.body(ctx, size: 13.0))),
              ],
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
                const SizedBox(width: 8.0),
                VButton(label: 'File to matter', icon: Icons.check, onPressed: () => Navigator.of(ctx).pop(true)),
              ],
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy.add(t.id));
    try {
      await VerinApi.assignUnrouted(t.id, matterId: pick.reference.id, remember: remember);
      if (mounted) showVToast(context, 'Filed to ${pick.title.isEmpty ? 'the matter' : pick.title}');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not file it', error: true, description: e is VerinApiException ? e.message : '$e');
    } finally {
      if (mounted) setState(() => _busy.remove(t.id));
    }
  }

  Future<void> _dismiss(UnroutedText t) async {
    setState(() => _busy.add(t.id));
    try {
      await VerinApi.assignUnrouted(t.id, dismiss: true);
    } catch (e) {
      if (mounted) showVToast(context, 'Could not dismiss', error: true, description: '$e');
    } finally {
      if (mounted) setState(() => _busy.remove(t.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<UnroutedText>>(
      stream: _items,
      builder: (context, snap) {
        final items = snap.data ?? const <UnroutedText>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('TEXTS FROM NUMBERS NO MATTER KNOWS', style: VT.eyebrow(context)),
              const SizedBox(height: 4.0),
              Text('Already stored and hashed. Choose the matter they belong to.', style: VT.muted(context, size: 13.0)),
              const SizedBox(height: 12.0),
              Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(VR.card), border: Border.all(color: c.border)),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                        decoration: BoxDecoration(color: c.card, border: i == 0 ? null : Border(top: BorderSide(color: c.border))),
                        child: Row(
                          children: [
                            VIconCircle(icon: Icons.sms_outlined, size: 34.0, iconSize: 16.0),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(prettyPhone(items[i].from), style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                                  Text(
                                    [
                                      if (items[i].body.trim().isNotEmpty) '“${items[i].body.trim()}”',
                                      if (items[i].media > 0) '${items[i].media} picture${items[i].media == 1 ? '' : 's'}',
                                      if (items[i].at != null) fmtWhen(items[i].at),
                                    ].join(' · '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: VT.muted(context, size: 12.5),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            VButton(
                              label: 'Dismiss',
                              kind: VButtonKind.link,
                              size: VButtonSize.sm,
                              onPressed: _busy.contains(items[i].id) ? null : () => _dismiss(items[i]),
                            ),
                            const SizedBox(width: 6.0),
                            VButton(
                              label: 'File to matter',
                              kind: VButtonKind.tonal,
                              size: VButtonSize.sm,
                              loading: _busy.contains(items[i].id),
                              onPressed: _busy.contains(items[i].id) ? null : () => _file(items[i]),
                            ),
                          ],
                        ),
                      ),
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
