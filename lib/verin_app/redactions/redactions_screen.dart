// Redactions — every personal detail Verin has flagged across the firm, in
// one place, plus the firm's own always-redact list.
//
// The old flow hid all of this inside a production: you could only see what
// was flagged by starting one, matter by matter. This page answers the two
// questions a firm actually asks — "what has Verin found?" and "what do we
// always want hidden?" — without starting anything.
//
// Nothing here alters an original. Flags are suggestions; masking happens when
// an extract, an exhibit set or a report is produced, and a person confirms
// before any of it leaves.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matter/exhibits_tab.dart' show sensitiveOf, categoryLabel;
import '../matters/matters_screen.dart' show openMatter;
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/motion.dart';
import 'video_redaction_screen.dart';

/// One flagged value, with the item and matter it came from.
class Flagged {
  Flagged({required this.receipt, required this.category, required this.text, required this.hasBox});

  final ReceiptsRecord receipt;
  final String category, text;

  /// Image flags are an area on the picture rather than a string.
  final bool hasBox;

  DocumentReference? get matterRef => receipt.matterId;
}

List<Flagged> flaggedIn(List<ReceiptsRecord> receipts) {
  final out = <Flagged>[];
  for (final r in receipts) {
    for (final s in sensitiveOf(r)) {
      final text = '${s['text'] ?? ''}'.trim();
      final hasBox = s['box'] != null;
      if (text.isEmpty && !hasBox) continue;
      out.add(Flagged(receipt: r, category: '${s['category'] ?? 'other'}', text: text, hasBox: hasBox));
    }
  }
  return out;
}

/// Shows enough of a value to recognise it, never the whole thing — this page
/// is a review screen, not somewhere to read SSNs off.
String preview(String s) {
  final t = s.trim();
  if (t.length <= 4) return '•' * t.length;
  return '${t.substring(0, 2)}${'•' * (t.length - 4).clamp(1, 10)}${t.substring(t.length - 2)}';
}

Stream<List<ReceiptsRecord>> _firmReceipts() => queryReceiptsRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
      limit: 400,
    );

class RedactionsScreen extends StatefulWidget {
  const RedactionsScreen({super.key});

  @override
  State<RedactionsScreen> createState() => _RedactionsScreenState();
}

class _RedactionsScreenState extends State<RedactionsScreen> {
  late final Stream<List<ReceiptsRecord>> _receipts = _firmReceipts();
  late final Stream<FirmAccountRecord?> _firm = firmAccountStream();
  String _filter = 'all';
  String _tab = 'flagged';

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<FirmAccountRecord?>(
      stream: _firm,
      builder: (context, fs) => StreamBuilder<List<ReceiptsRecord>>(
        stream: _receipts,
        builder: (context, rs) {
          final loading = !rs.hasData;
          final all = flaggedIn(rs.data ?? const []);
          final categories = {for (final f in all) f.category};
          final shown = _filter == 'all' ? all : all.where((f) => f.category == _filter).toList();

          // Grouped by matter: a paralegal works one case at a time.
          final byMatter = <String, List<Flagged>>{};
          for (final f in shown) {
            final key = f.matterRef?.path ?? 'none';
            byMatter.putIfAbsent(key, () => []).add(f);
          }

          return ListView(
            padding: vPagePadding(context),
            children: [
              Text('Redactions', style: VT.h1(context, size: 28.0)),
              const SizedBox(height: 4.0),
              Text(
                'Personal details Verin has flagged across your matters, and the terms you always want hidden. '
                'Originals are never altered — flagged text is masked when an extract, exhibit set or report is produced.',
                style: VT.muted(context),
              ),
              const SizedBox(height: 18.0),
              // One page, four views: redactions earn a single place in the
              // sidebar rather than sprawling across it.
              VSegmented<String>(
                value: _tab,
                options: const ['flagged', 'video', 'photo', 'document'],
                fontSize: 12.0,
                labelFor: (t) => const {
                  'flagged': 'Flagged',
                  'video': 'Video & audio',
                  'photo': 'Photos',
                  'document': 'Documents',
                }[t]!,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 22.0),
              if (_tab != 'flagged') ...[
                MediaRedactionList(kind: _tab, receipts: rs.data ?? const [], loading: loading),
                const SizedBox(height: 32.0),
              ],
              if (_tab == 'flagged') ...[
              AlwaysRedactCard(firm: fs.data),
              const SizedBox(height: 28.0),
              Row(
                children: [
                  Expanded(child: Text('FLAGGED IN YOUR MATTERS', style: VT.eyebrow(context))),
                  if (!loading) Text('${all.length} flagged', style: VT.muted(context, size: 12.0)),
                ],
              ),
              const SizedBox(height: 12.0),
              if (categories.length > 1) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    for (final cat in ['all', ...categories])
                      VHover(
                        onTap: () => setState(() => _filter = cat),
                        builder: (context, hovered) {
                          final on = _filter == cat;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: on ? c.primary : (hovered ? c.panel : c.secondary),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              cat == 'all' ? 'Everything' : categoryLabel(cat),
                              style: VT.body(context, size: 12.0, weight: FontWeight.w500, color: on ? c.primaryFg : c.foreground),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16.0),
              ],
              if (loading)
                for (var i = 0; i < 3; i++)
                  const Padding(padding: EdgeInsets.only(bottom: 10.0), child: VShimmer(height: 64.0, radius: 14.0))
              else if (all.isEmpty)
                VCard(
                  child: Column(
                    children: [
                      Icon(Icons.verified_user_outlined, size: 26.0, color: c.mutedFg),
                      const SizedBox(height: 10.0),
                      Text('Nothing flagged yet', style: VT.body(context, size: 14.0, weight: FontWeight.w600)),
                      const SizedBox(height: 4.0),
                      Text(
                        'Verin flags things like SSNs, account numbers and children\'s names as evidence arrives. '
                        'Anything it finds will appear here for review.',
                        textAlign: TextAlign.center,
                        style: VT.muted(context, size: 12.5),
                      ),
                    ],
                  ),
                )
              else
                for (final (i, entry) in byMatter.entries.indexed)
                  VReveal(
                    key: ValueKey(entry.key),
                    index: i,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MatterFlagsCard(matterRef: entry.value.first.matterRef, flags: entry.value),
                    ),
                  ),
              ],
              const SizedBox(height: 32.0),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Terms the firm always wants hidden, whatever Verin found on its own — a
/// child's name, a street, a case-specific alias.
class AlwaysRedactCard extends StatefulWidget {
  const AlwaysRedactCard({super.key, required this.firm});

  final FirmAccountRecord? firm;

  @override
  State<AlwaysRedactCard> createState() => _AlwaysRedactCardState();
}

class _AlwaysRedactCardState extends State<AlwaysRedactCard> {
  final _add = TextEditingController();
  bool _busy = false;

  List<String> get _terms {
    final v = widget.firm?.snapshotData['alwaysRedact'];
    return v is List ? v.whereType<String>().toList() : const [];
  }

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  Future<void> _save(List<String> next) async {
    final f = widget.firm;
    if (f == null) {
      showVToast(context, 'Your firm profile is still being set up', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await f.reference.update({'alwaysRedact': next});
      if (mounted) _add.clear();
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save', error: true, description: '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final terms = _terms;
    // Firm-wide, so only an admin sets it; everyone can see what is in force.
    final isAdmin = VUser.current().isAdmin;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16.0, color: c.tealDeep),
              const SizedBox(width: 8.0),
              Expanded(child: Text('Always redact', style: VT.body(context, size: 14.0, weight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            'Exact text that is masked everywhere it appears, in every matter — on top of what Verin flags on its own.',
            style: VT.muted(context, size: 12.0),
          ),
          const SizedBox(height: 14.0),
          if (terms.isNotEmpty) ...[
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final t in terms)
                  Container(
                    padding: const EdgeInsets.only(left: 12.0, right: 6.0, top: 5.0, bottom: 5.0),
                    decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(999)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(t, style: VT.body(context, size: 12.0)),
                        const SizedBox(width: 4.0),
                        if (isAdmin)
                          VHover(
                            onTap: _busy ? null : () => _save([...terms]..remove(t)),
                            builder: (context, hovered) => Icon(Icons.close, size: 13.0, color: hovered ? c.broken : c.mutedFg),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12.0),
          ],
          if (isAdmin)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _add,
                    style: VT.body(context, size: 13.0),
                    decoration: vInputDecoration(context, hint: 'A name, number or phrase to always hide'),
                    onSubmitted: (_) => _addTerm(),
                  ),
                ),
                const SizedBox(width: 8.0),
                VButton(label: 'Add', size: VButtonSize.sm, loading: _busy, onPressed: _addTerm),
              ],
            )
          else if (terms.isEmpty)
            Text('An admin can add terms here.', style: VT.muted(context, size: 12.0)),
        ],
      ),
    );
  }

  void _addTerm() {
    final t = _add.text.trim();
    if (t.length < 2) {
      showVToast(context, 'Type at least two characters', error: true);
      return;
    }
    final terms = _terms;
    if (terms.contains(t)) {
      _add.clear();
      return;
    }
    _save([...terms, t]);
  }
}

// ---------------------------------------------------------------------------

class MatterFlagsCard extends StatefulWidget {
  const MatterFlagsCard({super.key, required this.matterRef, required this.flags});

  final DocumentReference? matterRef;
  final List<Flagged> flags;

  @override
  State<MatterFlagsCard> createState() => _MatterFlagsCardState();
}

class _MatterFlagsCardState extends State<MatterFlagsCard> {
  // Held in state: a stream built in build() is a new object every time, so
  // StreamBuilder would drop and reopen the listener on every rebuild and the
  // name would flash back to its fallback.
  Stream<MattersRecord>? _matter;

  @override
  void initState() {
    super.initState();
    _bind();
  }

  @override
  void didUpdateWidget(covariant MatterFlagsCard old) {
    super.didUpdateWidget(old);
    if (old.matterRef?.path != widget.matterRef?.path) _bind();
  }

  void _bind() {
    final r = widget.matterRef;
    _matter = r == null ? null : MattersRecord.getDocument(r);
  }

  Future<void> _open(BuildContext context) async {
    final ref = widget.matterRef;
    if (ref == null) return;
    try {
      final m = await MattersRecord.getDocumentOnce(ref);
      if (context.mounted) openMatter(context, m, tab: 'exhibits');
    } catch (_) {
      if (context.mounted) showVToast(context, 'Could not open that matter', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final flags = widget.flags;
    final byCategory = <String, int>{};
    for (final f in flags) {
      byCategory[f.category] = (byCategory[f.category] ?? 0) + 1;
    }
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StreamBuilder<MattersRecord>(
                  stream: _matter,
                  builder: (context, s) => Text(
                    s.data?.matterName ?? 'Matter',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VT.body(context, size: 14.0, weight: FontWeight.w600),
                  ),
                ),
              ),
              VBadge(
                label: '${flags.length} flagged',
                bg: c.pending.withValues(alpha: 0.12),
                fg: c.pending,
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              for (final e in byCategory.entries)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg)),
                  child: Text('${categoryLabel(e.key)} · ${e.value}', style: VT.body(context, size: 11.5)),
                ),
            ],
          ),
          const SizedBox(height: 12.0),
          for (final f in flags.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Row(
                children: [
                  Icon(f.hasBox ? Icons.crop_square_outlined : Icons.text_fields_outlined, size: 13.0, color: c.mutedFg),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      f.hasBox && f.text.isEmpty ? 'An area of a picture' : preview(f.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VT.mono(context, size: 12.0),
                    ),
                  ),
                  Text(categoryLabel(f.category), style: VT.muted(context, size: 11.0)),
                ],
              ),
            ),
          if (flags.length > 4)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text('and ${flags.length - 4} more', style: VT.muted(context, size: 11.5)),
            ),
          const SizedBox(height: 6.0),
          VButton(
            label: 'Review and produce',
            icon: Icons.arrow_forward,
            kind: VButtonKind.link,
            size: VButtonSize.sm,
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Items of one kind that someone may need to redact, newest first.
///
/// Video and audio open the editor, where boxes are burned into the picture
/// and spans are silenced. Photos and documents are redacted inside a
/// production, where they are already part of an exhibit set — sending people
/// to a second place to do the same job would only split the habit.
class MediaRedactionList extends StatelessWidget {
  const MediaRedactionList({super.key, required this.kind, required this.receipts, required this.loading});

  final String kind;
  final List<ReceiptsRecord> receipts;
  final bool loading;

  static const _kinds = {
    'video': ['video', 'audio'],
    'photo': ['photo', 'screenshot', 'image'],
    'document': ['document', 'email'],
  };

  static const _blurb = {
    'video': 'Black out part of the picture and silence spans of the sound. The original is never altered — producing saves a new file with its own fingerprint.',
    'photo': 'Boxes are burned into the picture, so nothing under them survives. Photos are redacted while you build a production.',
    'document': 'Flagged text is removed wherever it appears, and pages with redactions are re-rendered so nothing survives underneath.',
  };

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final wanted = _kinds[kind] ?? const <String>[];
    final items = receipts.where((r) => wanted.contains(r.itemKind)).toList()
      ..sort((a, b) => (b.receivedAt ?? DateTime(2000)).compareTo(a.receivedAt ?? DateTime(2000)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_blurb[kind] ?? '', style: VT.muted(context, size: 12.5)),
        const SizedBox(height: 16.0),
        if (loading)
          for (var i = 0; i < 3; i++)
            const Padding(padding: EdgeInsets.only(bottom: 10.0), child: VShimmer(height: 58.0, radius: 14.0))
        else if (items.isEmpty)
          VCard(
            child: Column(
              children: [
                Icon(Icons.inbox_outlined, size: 24.0, color: c.mutedFg),
                const SizedBox(height: 8.0),
                Text('Nothing of this kind yet', style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                const SizedBox(height: 4.0),
                Text('Items will appear here as they arrive in your matters.',
                    textAlign: TextAlign.center, style: VT.muted(context, size: 12.0)),
              ],
            ),
          )
        else
          for (final (i, r) in items.take(40).indexed)
            VReveal(
              key: ValueKey(r.reference.path),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _MediaRow(receipt: r, openable: kind == 'video'),
              ),
            ),
      ],
    );
  }
}

class _MediaRow extends StatelessWidget {
  const _MediaRow({required this.receipt, required this.openable});

  final ReceiptsRecord receipt;
  final bool openable;

  Future<void> _open(BuildContext context) async {
    final ref = receipt.matterId;
    if (ref == null) return;
    try {
      final m = await MattersRecord.getDocumentOnce(ref);
      if (!context.mounted) return;
      if (openable) {
        await showVideoRedaction(context, matter: m, receipt: receipt);
      } else {
        openMatter(context, m, tab: 'exhibits');
      }
    } catch (_) {
      if (context.mounted) showVToast(context, 'Could not open that item', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final flags = sensitiveOf(receipt).length;
    return VCard(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 34.0,
            height: 34.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg)),
            child: Icon(
              switch (receipt.itemKind) {
                'video' => Icons.videocam_outlined,
                'audio' => Icons.mic_none_rounded,
                'document' => Icons.description_outlined,
                'email' => Icons.mail_outline_rounded,
                _ => Icons.photo_outlined,
              },
              size: 16.0,
              color: c.tealDeep,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(receipt.fileName.isEmpty ? receipt.headline : receipt.fileName,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                Text(
                  [
                    receipt.kindLabel,
                    if (receipt.receivedAt != null) 'received ${fmtWhen(receipt.receivedAt)}',
                    if (flags > 0) '$flags flagged',
                  ].join(' · '),
                  style: VT.muted(context, size: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10.0),
          if (flags > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: VBadge(label: 'Needs review', bg: c.pending.withValues(alpha: 0.12), fg: c.pending),
            ),
          VButton(
            label: openable ? 'Redact' : 'Open matter',
            icon: openable ? Icons.brush_outlined : Icons.arrow_forward,
            kind: VButtonKind.link,
            size: VButtonSize.sm,
            onPressed: () => _open(context),
          ),
        ],
      ),
    );
  }
}
