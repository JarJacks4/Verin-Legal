// Thread tab — port of the Make's <ThreadTab>: every message the AI read
// from screenshots / screen recordings, merged into one conversation, with
// per-message annotations (the firm's notes; never part of the record).

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/thread_merge.dart';

import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../data/model.dart';
import 'annotations.dart';
import 'manual_entry_drawer.dart';
import 'receipt_detail_drawer.dart';

class ThreadTab extends StatefulWidget {
  const ThreadTab({super.key, required this.matter, required this.receipts});

  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<ThreadTab> createState() => _ThreadTabState();
}

class _ThreadTabState extends State<ThreadTab> {
  late Stream<Map<String, List<Annotation>>> _notes = matterAnnotationsStream(widget.matter.reference);
  String? _composing; // message key with an open composer
  DocumentReference? _editing; // annotation being edited
  bool _onlyAnnotated = false;

  @override
  void didUpdateWidget(covariant ThreadTab old) {
    super.didUpdateWidget(old);
    if (old.matter.reference.path != widget.matter.reference.path) {
      _notes = matterAnnotationsStream(widget.matter.reference);
    }
  }

  String _sourceLabel(ThreadEntry e) {
    final r = e.receipt;
    final name = r.fileName.isNotEmpty ? r.fileName : r.headline;
    return '$name · #${e.indexInReceipt + 1}';
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
    return StreamBuilder<Map<String, List<Annotation>>>(
      stream: _notes,
      builder: (context, snap) => _build(context, snap.data ?? const {}),
    );
  }

  Widget _build(BuildContext context, Map<String, List<Annotation>> notes) {
    final c = VC.of(context);
    final matter = widget.matter;
    final receipts = widget.receipts;
    final entries = mergeThread(receipts.where((r) => !r.isDuplicate).toList());
    final all = entries.where((e) => !e.isRepeat).toList();
    final repeats = entries.length - all.length;
    final pending = receipts.where((r) => r.extractionState == 'pending').length;
    final total = notes.values.fold<int>(0, (n, l) => n + l.length);
    final visible = _onlyAnnotated
        ? all.where((e) => !e.isHeader && (notes[messageKeyOf(e)]?.isNotEmpty ?? false)).toList()
        : all;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text('Thread reconstruction', style: VT.h2(context, size: 20.0))),
        if (all.isNotEmpty) ...[
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

    if (all.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 4.0),
          Text(
            'Overlapping screenshots merged into one continuous thread. Each message cites its source.',
            style: VT.muted(context),
          ),
          const SizedBox(height: 24.0),
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

    final threadNotes = <String>[
      if (repeats > 0)
        '$repeats overlapping message${repeats == 1 ? '' : 's'} appeared in more than one screenshot and ${repeats == 1 ? 'is' : 'are'} shown once.',
      for (final e in all)
        if (e.isGap && !e.isHeader)
          'Contiguity could not be proved before "${_clip(e.text)}" (${_sourceLabel(e)}).',
      for (final e in all)
        if (!e.isHeader && e.timestampLabel.trim().isEmpty && e.isLowConfidence)
          'No visible timestamp on "${_clip(e.text)}"; order inferred from position only.',
      if (pending > 0) 'Still reading $pending item${pending == 1 ? '' : 's'}.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 4.0),
        Text(
          "Overlapping screenshots merged into one continuous thread. Each message cites its source; where contiguity can't be proved, the gap is shown as its own entry rather than joined silently.",
          style: VT.muted(context),
        ),
        const SizedBox(height: 8.0),
        Row(
          children: [
            Icon(Icons.lock_outline, size: 11.0, color: c.mutedFg),
            const SizedBox(width: 6.0),
            Expanded(
              child: Text('Annotations are your work product. They sit beside the evidence and never alter the hashed record.',
                  style: VT.muted(context, size: 12.0)),
            ),
          ],
        ),
        const SizedBox(height: 24.0),
        if (_onlyAnnotated && visible.isEmpty)
          const VEmptyState(
            compact: true,
            icon: Icons.edit_outlined,
            title: 'No annotations yet',
            message: 'Use the pen beside any message to add a note.',
          ),
        for (final e in visible) ...[
          if (!_onlyAnnotated && e.isGap && !e.isHeader) const _GapRow(),
          if (e.isHeader)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: Center(child: Text(e.text, style: VT.muted(context, size: 11.0))),
            )
          else
            _message(context, e, notes[messageKeyOf(e)] ?? const []),
        ],
        if (threadNotes.isNotEmpty && !_onlyAnnotated) ...[
          const SizedBox(height: 8.0),
          VPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final n in threadNotes) Text('· $n', style: VT.body(context, size: 12.0, height: 1.6))],
            ),
          ),
        ],
      ],
    );
  }

  Widget _message(BuildContext context, ThreadEntry e, List<Annotation> notes) {
    final c = VC.of(context);
    final matter = widget.matter;
    final mine = e.isFromClient;
    final key = messageKeyOf(e);
    final composing = _composing == key;
    final speaker = mine ? (matter.clientName.isNotEmpty ? matter.clientName.split(' ').first : 'Client') : 'Other party';

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
          Text(e.text, style: VT.body(context, height: 1.35, color: mine ? c.primaryFg : c.foreground)),
        ],
      ),
    );
    if (notes.isNotEmpty) {
      // Annotated: a pending-colored ring, offset from the bubble.
      bubble = Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          border: Border.all(color: c.pending, width: 1.5),
          borderRadius: BorderRadius.circular(VR.card + 3.5),
        ),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: notes.isNotEmpty ? c.pending.withValues(alpha: 0.14) : c.secondary,
            ),
            child: notes.isNotEmpty
                ? Text('${notes.length}', style: VT.body(context, size: 11.0, weight: FontWeight.w700, color: c.pending))
                : Icon(Icons.edit_outlined, size: 12.0, color: c.tealDeep),
          ),
        ),
      ),
    );

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
                children: mine
                    ? [pen, const SizedBox(width: 8.0), Flexible(child: bubble)]
                    : [Flexible(child: bubble), const SizedBox(width: 8.0), pen],
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
                      onTap: () => showReceiptDrawer(context, receipt: e.receipt, matter: matter),
                      builder: (context, hovered) => Text(
                        '${e.timestampLabel.trim().isEmpty ? 'no timestamp' : e.timestampLabel} · ${_sourceLabel(e)}',
                        style: VT.body(context, size: 10.0, color: hovered ? c.teal : c.mutedFg),
                      ),
                    ),
                    if (e.isLowConfidence) const StateBadge(state: VItemState.uncertain),
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
                    if (await _run(() => addAnnotation(matterRef: matter.reference, entry: e, text: text, tag: tag), 'Annotation added') &&
                        mounted) {
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

  static String _clip(String s) {
    final t = s.trim().replaceAll('\n', ' ');
    return t.length > 40 ? '${t.substring(0, 40)}…' : t;
  }
}

class _GapRow extends StatelessWidget {
  const _GapRow();

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 16.0),
      child: Row(
        children: [
          const Expanded(child: VHairline()),
          const SizedBox(width: 12.0),
          VBadge(label: 'Gap', icon: Icons.warning_amber_rounded, bg: c.pendingBg, fg: c.pending),
          const SizedBox(width: 12.0),
          const Expanded(child: VHairline()),
        ],
      ),
    );
  }
}
