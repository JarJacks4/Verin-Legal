// Thread tab — the Make's <ThreadTab> over the server-reconstructed record
// (functions/verin/thread): overlapping screenshots woven into one
// conversation, dates resolved only as far as the screenshots allow, the
// names each side appears under, and a gap wherever continuity can't be
// proved. Each message opens its source in the verification view; each can
// carry the firm's annotations (work product, never part of the record).

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/corrections.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import 'annotations.dart';
import 'follow_ups.dart';
import 'manual_entry_drawer.dart';
import 'verification_view.dart';

class ThreadTab extends StatefulWidget {
  const ThreadTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends State<ThreadTab> {
  late Stream<ThreadDoc?> _thread = matterThreadStream(widget.matter.reference);
  late Stream<Map<String, List<Annotation>>> _notes = matterAnnotationsStream(widget.matter.reference);
  late Stream<Map<String, Map<String, Correction>>> _corr = matterCorrectionsStream(widget.matter.reference);
  String? _composing; // message key with an open composer
  DocumentReference? _editing; // annotation being edited
  bool _onlyAnnotated = false;
  bool _asked = false;
  bool _rebuilding = false;

  @override
  void didUpdateWidget(covariant ThreadTab old) {
    super.didUpdateWidget(old);
    if (old.matter.reference.path != widget.matter.reference.path) {
      _thread = matterThreadStream(widget.matter.reference);
      _notes = matterAnnotationsStream(widget.matter.reference);
      _corr = matterCorrectionsStream(widget.matter.reference);
      _asked = false;
    }
  }

  ReceiptsRecord? _receipt(String id) {
    for (final r in widget.receipts) {
      if (r.reference.id == id) return r;
    }
    return null;
  }

  Future<void> _rebuild() async {
    setState(() => _rebuilding = true);
    try {
      await VerinApi.refreshMatterRecord(widget.matter.reference.id);
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _rebuilding = false);
    }
  }

  /// Runs a save/delete; true when it worked (errors are shown as a toast).
  Future<bool> _run(Future<void> Function() op, String done) async {
    try {
      await op();
      if (mounted) showVToast(context, done);
      return true;
    } catch (e) {
      if (mounted) showVToast(context, 'Could not save the annotation', error: true, description: '$e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThreadDoc?>(
      stream: _thread,
      builder: (context, ts) => StreamBuilder<Map<String, List<Annotation>>>(
        stream: _notes,
        builder: (context, ns) => StreamBuilder<Map<String, Map<String, Correction>>>(
          stream: _corr,
          builder: (context, cs) => _build(context, ts, ns.data ?? const {}, cs.data ?? const {}),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, AsyncSnapshot<ThreadDoc?> ts, Map<String, List<Annotation>> notes, Map<String, Map<String, Correction>> corr) {
    final c = VC.of(context);
    final matter = widget.matter;
    final thread = ts.data;
    final hasMessages = widget.receipts.any((r) => r.threadMessages.isNotEmpty);
    final pending = widget.receipts.where((r) => r.extractionState == 'pending' || r.extractionState == 'running').length;
    final total = notes.values.fold<int>(0, (n, l) => n + l.length);

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text('Thread reconstruction', style: VT.h2(context, size: 20.0))),
        if (thread != null && thread.entries.isNotEmpty) ...[
          const SizedBox(width: 16.0),
          Opacity(
            opacity: total == 0 && !_onlyAnnotated ? 0.4 : 1.0,
            child: VHover(
              onTap: total == 0 && !_onlyAnnotated ? null : () => setState(() => _onlyAnnotated = !_onlyAnnotated),
              builder: (context, hovered) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                decoration: BoxDecoration(color: _onlyAnnotated ? c.teal : c.secondary, borderRadius: BorderRadius.circular(999.0)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 12.0, color: _onlyAnnotated ? c.primaryFg : c.tealDeep),
                    const SizedBox(width: 6.0),
                    Text(
                      '$total annotation${total == 1 ? '' : 's'}${_onlyAnnotated ? ' · showing only' : ''}',
                      style: VT.body(context, size: 12.0, weight: FontWeight.w500, color: _onlyAnnotated ? c.primaryFg : c.tealDeep),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );

    final intro = [
      header,
      const SizedBox(height: 4.0),
      Text(
        "Overlapping screenshots woven into one conversation, in the order they happened. Each message cites its source; where continuity can't be proved, the gap is shown rather than joined silently.",
        style: VT.muted(context),
      ),
      const SizedBox(height: 8.0),
      Row(
        children: [
          Icon(Icons.lock_outline, size: 11.0, color: c.mutedFg),
          const SizedBox(width: 6.0),
          Expanded(
            child: Text('Annotations and corrections are your work product. They sit beside the evidence and never alter the hashed record.',
                style: VT.muted(context, size: 12.0)),
          ),
        ],
      ),
      const SizedBox(height: 20.0),
    ];

    if (!hasMessages) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...intro,
          pending > 0
              ? VEmptyState(
                  icon: Icons.auto_awesome_outlined,
                  title: 'Reading $pending item${pending == 1 ? '' : 's'} now',
                  message: 'Messages appear here as soon as they are read — usually within a minute.',
                  action: const SizedBox(width: 22.0, height: 22.0, child: CircularProgressIndicator(strokeWidth: 2.0)),
                )
              : VEmptyState(
                  icon: Icons.layers_outlined,
                  title: 'No thread yet',
                  message: 'Add screenshots of texts, WhatsApp or email threads — or a screen recording — and the messages are read into one dated conversation here.',
                  action: VButton(
                    label: 'Add screenshots',
                    icon: Icons.image_outlined,
                    kind: VButtonKind.tonal,
                    size: VButtonSize.sm,
                    onPressed: () => showManualEntryDrawer(context, matter: matter),
                  ),
                ),
        ],
      );
    }

    if (thread == null) {
      // Matters filed before reconstruction moved to the server: build it now.
      if (!ts.hasError && ts.connectionState != ConnectionState.waiting && !_asked) {
        _asked = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _rebuild());
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...intro,
          ts.hasError
              ? VErrorBox(message: 'The thread could not be loaded: ${ts.error}')
              : const VEmptyState(
                  icon: Icons.layers_outlined,
                  title: 'Building the thread…',
                  message: 'Weaving the screenshots together, resolving dates and checking for gaps. This takes a few seconds.',
                  action: SizedBox(width: 22.0, height: 22.0, child: CircularProgressIndicator(strokeWidth: 2.0)),
                ),
        ],
      );
    }

    final visible = _onlyAnnotated
        ? thread.entries.where((e) => e.isMessage && (notes[e.key]?.isNotEmpty ?? false)).toList()
        : thread.entries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...intro,
        _statsStrip(context, thread, pending),
        if (thread.otherNames.isNotEmpty || thread.clientNames.length > 1) ...[
          const SizedBox(height: 12.0),
          _namesCard(context, thread),
        ],
        if (thread.notes.isNotEmpty && !_onlyAnnotated) ...[
          const SizedBox(height: 12.0),
          VPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FOR REVIEW', style: VT.eyebrow(context, size: 10.0)),
                const SizedBox(height: 6.0),
                for (final n in thread.notes) Text('· $n', style: VT.body(context, size: 12.0, height: 1.6)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24.0),
        if (_onlyAnnotated && visible.isEmpty)
          const VEmptyState(compact: true, icon: Icons.edit_outlined, title: 'No annotations yet', message: 'Use the pen beside any message to add a note.'),
        for (final e in visible)
          if (e.isGap)
            _gapRow(context, thread, e)
          else if (e.isHeader)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(child: Text(e.text, style: VT.muted(context, size: 11.0))),
            )
          else
            _message(context, e, notes[e.key] ?? const [], corr),
        if (thread.truncated)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text('Very long thread: some long messages are shortened here. Open the source to read them in full.', style: VT.muted(context, size: 11.0)),
          ),
      ],
    );
  }

  Widget _statsStrip(BuildContext context, ThreadDoc t, int pending) {
    final c = VC.of(context);
    Widget chip(String text, {Color? tone}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(color: (tone ?? c.mutedFg).withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999.0)),
          child: Text(text, style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: tone ?? c.foreground)),
        );
    final items = t.stat('items');
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        chip('${t.stat('messages')} messages from $items item${items == 1 ? '' : 's'}'),
        if (t.stat('repeatsFolded') > 0) chip('${t.stat('repeatsFolded')} repeats folded'),
        chip('${t.stat('gaps')} gap${t.stat('gaps') == 1 ? '' : 's'}', tone: t.stat('gaps') > 0 ? c.pending : c.verified),
        if (t.stat('undated') > 0) chip('${t.stat('undated')} undated', tone: c.pending),
        if (t.stat('uncertainDates') > 0) chip('${t.stat('uncertainDates')} dates inferred', tone: c.pending),
        if (t.stat('outOfOrder') > 0) chip('${t.stat('outOfOrder')} out of order', tone: c.broken),
        if (pending > 0) chip('reading $pending more…'),
        VHover(
          onTap: _rebuilding ? null : _rebuild,
          builder: (context, h) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(_rebuilding ? 'Rebuilding…' : 'Rebuild', style: VT.body(context, size: 11.0, color: h ? c.teal : c.tealDeep)),
          ),
        ),
      ],
    );
  }

  Widget _namesCard(BuildContext context, ThreadDoc t) {
    final c = VC.of(context);
    final unconfirmed = t.otherNames.where((p) => p.confirmedAs.isEmpty).length;
    String show(Participant p) => p.confirmedAs.isNotEmpty && p.confirmedAs != p.name ? '"${p.name}" → ${p.confirmedAs}' : '"${p.name}"';
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: unconfirmed > 0 && t.otherNames.length > 1 ? c.pending : c.border), borderRadius: BorderRadius.circular(VR.card)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.people_outline, size: 18.0, color: c.tealDeep),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('People in this thread', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
                const SizedBox(height: 4.0),
                if (t.otherNames.isNotEmpty)
                  Text('Other side appears as ${t.otherNames.map(show).join(', ')}', style: VT.body(context, size: 12.0, height: 1.5)),
                if (t.clientNames.isNotEmpty)
                  Text('Client appears as ${t.clientNames.map(show).join(', ')}', style: VT.muted(context, size: 12.0)),
                if (t.otherNames.length > 1 && unconfirmed > 0)
                  Text('Names are never merged on a guess — confirm which are the same person.', style: VT.body(context, size: 11.0, color: c.pending)),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          VButton(label: 'Confirm names', kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: () => _confirmNames(t)),
        ],
      ),
    );
  }

  Future<void> _confirmNames(ThreadDoc t) async {
    final saved = await showVDrawer<bool>(
      context,
      title: 'Who is who',
      width: 520.0,
      builder: (_) => _NamesForm(matter: widget.matter, thread: t),
    );
    if (saved == true && mounted) showVToast(context, 'Names saved', description: 'The thread is being rebuilt with them.');
  }

  Widget _gapRow(BuildContext context, ThreadDoc t, TEntry g) {
    final c = VC.of(context);
    Suggestion? ask;
    for (final s in t.suggestions) {
      if (s.key == g.key) ask = s;
    }
    final what = g.reason == 'cut_off' ? 'Cut off in the screenshot' : 'Continuity not proved';
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: VHairline()),
              const SizedBox(width: 12.0),
              VBadge(label: 'Gap · $what', icon: Icons.warning_amber_rounded, bg: c.pendingBg, fg: c.pending),
              const SizedBox(width: 12.0),
              const Expanded(child: VHairline()),
            ],
          ),
          if (ask != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: VButton(
                label: 'Ask the client for these messages',
                kind: VButtonKind.link,
                size: VButtonSize.sm,
                onPressed: () => showFollowUpComposer(context, matter: widget.matter, requests: [ask!]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, TEntry e, List<Annotation> notes, Map<String, Map<String, Correction>> corr) {
    final c = VC.of(context);
    final matter = widget.matter;
    final mine = e.isClient;
    final key = e.key;
    final composing = _composing == key;
    final r = _receipt(e.rid);
    final fix = corr[correctionTarget(e.rid, 'm', e.index)]?['text'];
    final speaker = mine
        ? (matter.clientName.isNotEmpty ? matter.clientName.split(' ').first : 'Client')
        : (e.person.isNotEmpty ? e.person : 'Other party');
    final source = r == null ? 'source' : '${r.fileName.isNotEmpty ? r.fileName : r.headline} · #${e.index + 1}';

    Widget bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: mine ? c.teal : c.card,
        border: mine ? null : Border.all(color: c.border),
        borderRadius: BorderRadius.circular(VR.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: 0.8,
            child: Text(speaker, style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: mine ? c.primaryFg : c.foreground)),
          ),
          const SizedBox(height: 2.0),
          Text(fix?.corrected ?? e.text, style: VT.body(context, height: 1.35, color: mine ? c.primaryFg : c.foreground)),
        ],
      ),
    );
    if (notes.isNotEmpty) {
      bubble = Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(border: Border.all(color: c.pending, width: 1.5), borderRadius: BorderRadius.circular(VR.card + 3.5)),
        child: bubble,
      );
    }

    final pen = Tooltip(
      message: 'Annotate',
      child: VHover(
        onTap: () => setState(() {
          _composing = composing ? null : key;
          _editing = null;
        }),
        builder: (context, hovered) => Opacity(
          opacity: hovered || notes.isNotEmpty || composing ? 1.0 : 0.4,
          child: Container(
            width: 28.0,
            height: 28.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: notes.isNotEmpty ? c.pending.withValues(alpha: 0.14) : c.secondary),
            child: notes.isNotEmpty
                ? Text('${notes.length}', style: VT.body(context, size: 11.0, weight: FontWeight.w700, color: c.pending))
                : Icon(Icons.edit_outlined, size: 12.0, color: c.tealDeep),
          ),
        ),
      ),
    );

    final flags = <(String, Color)>[
      if (e.has('date_uncertain')) ('date ${e.dateBasisLabel}', c.pending),
      if (e.has('year_inferred')) ('year inferred', c.pending),
      if (e.has('out_of_order')) ('dated before the line above', c.broken),
      if (e.has('name_unconfirmed')) ('name not confirmed', c.pending),
      if (e.has('hard_to_read')) ('hard to read', c.broken),
      if (fix != null) ('corrected', c.verified),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.76,
          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: mine ? [pen, const SizedBox(width: 8.0), Flexible(child: bubble)] : [Flexible(child: bubble), const SizedBox(width: 8.0), pen],
              ),
              const SizedBox(height: 4.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Wrap(
                  alignment: mine ? WrapAlignment.end : WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: [
                    VHover(
                      onTap: r == null ? null : () => showVerificationView(context, receipt: r, matter: matter, messageIndex: e.index),
                      builder: (context, hovered) => Text(
                        '${e.whenLabel} · $source${e.alsoIn.isNotEmpty ? ' · also in ${e.alsoIn.length}' : ''}',
                        style: VT.body(context, size: 10.0, color: hovered ? c.teal : c.mutedFg),
                      ),
                    ),
                    for (final (label, tone) in flags) VBadge(label: label, bg: tone.withValues(alpha: 0.12), fg: tone, size: 9.5),
                  ],
                ),
              ),
              for (final a in notes)
                if (_editing?.path == a.ref.path)
                  AnnotationComposer(
                    key: ValueKey('edit:${a.ref.path}'),
                    initial: a,
                    onCancel: () => setState(() => _editing = null),
                    onSave: (text, tag) async {
                      if (await _run(() => updateAnnotation(a, text: text, tag: tag), 'Annotation updated') && mounted) {
                        setState(() => _editing = null);
                      }
                    },
                  )
                else
                  AnnotationCard(
                    key: ValueKey(a.ref.path),
                    annotation: a,
                    onEdit: () => setState(() {
                      _editing = a.ref;
                      _composing = null;
                    }),
                    onDelete: () => _run(() => deleteAnnotation(a), 'Annotation removed'),
                  ),
              if (composing)
                AnnotationComposer(
                  key: ValueKey('new:$key'),
                  onCancel: () => setState(() => _composing = null),
                  onSave: (text, tag) async {
                    if (await _run(() => addAnnotation(matterRef: matter.reference, entry: e, text: text, tag: tag), 'Annotation added') && mounted) {
                      setState(() => _composing = null);
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Staff confirm which names are the same person. Saved on the matter as
/// participantAliases { personKey: display name }; the server rebuilds the
/// thread with them. A name left as itself is still "confirmed".
class _NamesForm extends StatefulWidget {
  const _NamesForm({required this.matter, required this.thread});
  final MattersRecord matter;
  final ThreadDoc thread;

  @override
  State<_NamesForm> createState() => _NamesFormState();
}

class _NamesFormState extends State<_NamesForm> {
  late final List<Participant> _people = [...widget.thread.otherNames, ...widget.thread.clientNames];
  late final Map<String, TextEditingController> _c = {
    for (final p in _people) p.key: TextEditingController(text: p.confirmedAs.isNotEmpty ? p.confirmedAs : _default(p)),
  };
  bool _busy = false;

  String _default(Participant p) {
    final isClient = widget.thread.clientNames.contains(p);
    if (isClient) return widget.matter.clientName.isNotEmpty ? widget.matter.clientName : p.name;
    // Suggest the most-used name on that side; staff change it if it's someone else.
    return widget.thread.otherNames.isNotEmpty ? widget.thread.otherNames.first.name : p.name;
  }

  @override
  void dispose() {
    for (final c in _c.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final aliases = {...participantAliases(widget.matter)};
    for (final p in _people) {
      final v = _c[p.key]!.text.trim();
      if (v.isEmpty) {
        aliases.remove(p.key);
      } else {
        aliases[p.key] = v;
      }
    }
    try {
      await widget.matter.reference.update({'participantAliases': aliases});
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showVToast(context, 'Could not save names: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    Widget row(Participant p) => Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Shown as "${p.name}" · ${p.count} message${p.count == 1 ? '' : 's'}', style: VT.body(context, size: 12.0, weight: FontWeight.w600)),
              const SizedBox(height: 6.0),
              VTextField(controller: _c[p.key]!, hint: 'Who this is'),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phones save the same person differently — "Mike", "Michael R.", a bare number. Give names that are the same person the same name; anything you leave different stays separate.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 20.0),
        if (widget.thread.otherNames.isNotEmpty) ...[
          Text('OTHER SIDE', style: VT.eyebrow(context, color: c.mutedFg)),
          const SizedBox(height: 10.0),
          for (final p in widget.thread.otherNames) row(p),
        ],
        if (widget.thread.clientNames.isNotEmpty) ...[
          const SizedBox(height: 6.0),
          Text('CLIENT', style: VT.eyebrow(context, color: c.mutedFg)),
          const SizedBox(height: 10.0),
          for (final p in widget.thread.clientNames) row(p),
        ],
        const SizedBox(height: 10.0),
        VButton(label: 'Save names', size: VButtonSize.lg, fullWidth: true, loading: _busy, onPressed: _save),
      ],
    );
  }
}
