// Thread annotations — the Make's <AnnotationComposer> and annotation cards.
//
// An annotation is the firm's work product attached to one reconstructed
// message: a tag and a note. They live in their own Annotations collection,
// scoped to the firm, and never touch the receipt, its hash or the chain.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';

enum AnnTag { note, key, followup, question }

extension AnnTagStyle on AnnTag {
  String get id => name;

  String get label => switch (this) {
        AnnTag.note => 'Note',
        AnnTag.key => 'Key evidence',
        AnnTag.followup => 'Follow up',
        AnnTag.question => 'Question',
      };

  Color color(VColors c) => switch (this) {
        AnnTag.note => c.tealDeep,
        AnnTag.key => c.verified,
        AnnTag.followup => c.pending,
        AnnTag.question => c.broken,
      };

  Color bg(VColors c) => this == AnnTag.note ? c.secondary : color(c).withValues(alpha: 0.14);

  static AnnTag parse(Object? v) => AnnTag.values.firstWhere((t) => t.name == v, orElse: () => AnnTag.note);
}

class Annotation {
  Annotation(this.ref, Map<String, dynamic> d)
      : messageKey = '${d['messageKey'] ?? ''}',
        text = '${d['text'] ?? ''}',
        tag = AnnTagStyle.parse(d['tag']),
        authorUid = '${d['authorUid'] ?? ''}',
        authorName = '${d['authorName'] ?? ''}',
        createdAt = (d['createdAt'] as Timestamp?)?.toDate();

  final DocumentReference ref;
  final String messageKey;
  final String text;
  final AnnTag tag;
  final String authorUid;
  final String authorName;
  final DateTime? createdAt;

  bool get canEdit => authorUid == currentUserUid || VUser.current().isAdmin;
}

final _col = FirebaseFirestore.instance.collection('Annotations');

/// Stable id for a reconstructed message: its receipt and position in it
/// (the record keeps the first copy's id, so notes stay attached).
String messageKeyOf(TEntry e) => e.key;

/// The matter's annotations grouped by message key, oldest first.
Stream<Map<String, List<Annotation>>> matterAnnotationsStream(DocumentReference matterRef) => _col
        .where('matterId', isEqualTo: matterRef)
        .where('firmID', isEqualTo: currentFirmId())
        .snapshots()
        .map((s) {
      final out = <String, List<Annotation>>{};
      for (final d in s.docs) {
        final a = Annotation(d.reference, d.data());
        out.putIfAbsent(a.messageKey, () => []).add(a);
      }
      for (final l in out.values) {
        l.sort((a, b) => (a.createdAt ?? DateTime(2100)).compareTo(b.createdAt ?? DateTime(2100)));
      }
      return out;
    });

Future<void> addAnnotation({
  required DocumentReference matterRef,
  required TEntry entry,
  required String text,
  required AnnTag tag,
}) =>
    _col.add({
      'firmID': currentFirmId(),
      'matterId': matterRef,
      'receiptId': FirebaseFirestore.instance.collection('Receipts').doc(entry.rid),
      'messageKey': messageKeyOf(entry),
      'messageIndex': entry.index,
      // A copy of the message text, so a note still reads sensibly if the
      // screenshot is ever read again and messages shift.
      'messageText': entry.text.length > 500 ? entry.text.substring(0, 500) : entry.text,
      'text': text,
      'tag': tag.id,
      'authorUid': currentUserUid,
      'authorName': VUser.current().name,
      'createdAt': FieldValue.serverTimestamp(),
    });

Future<void> updateAnnotation(Annotation a, {required String text, required AnnTag tag}) =>
    a.ref.update({'text': text, 'tag': tag.id, 'updatedAt': FieldValue.serverTimestamp()});

Future<void> deleteAnnotation(Annotation a) => a.ref.delete();

class AnnotationComposer extends StatefulWidget {
  const AnnotationComposer({super.key, this.initial, required this.onSave, required this.onCancel});

  final Annotation? initial;
  final Future<void> Function(String text, AnnTag tag) onSave;
  final VoidCallback onCancel;

  @override
  State<AnnotationComposer> createState() => _AnnotationComposerState();
}

class _AnnotationComposerState extends State<AnnotationComposer> {
  late final _text = TextEditingController(text: widget.initial?.text ?? '');
  late AnnTag _tag = widget.initial?.tag ?? AnnTag.note;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final t = _text.text.trim();
    if (t.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(t, _tag);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.teal), borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              for (final t in AnnTag.values)
                Semantics(
                  selected: _tag == t,
                  button: true,
                  child: VHover(
                    onTap: () => setState(() => _tag = t),
                    builder: (context, hovered) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _tag == t ? t.color(c) : t.bg(c),
                        borderRadius: BorderRadius.circular(999.0),
                      ),
                      child: Text(t.label,
                          style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: _tag == t ? c.card : t.color(c))),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
              const SingleActivator(LogicalKeyboardKey.enter, meta: true): _save,
              const SingleActivator(LogicalKeyboardKey.escape): widget.onCancel,
            },
            child: TextField(
              controller: _text,
              autofocus: true,
              minLines: 3,
              maxLines: 8,
              maxLength: 4000,
              onChanged: (_) => setState(() {}),
              style: VT.body(context, size: 13.0),
              cursorColor: c.teal,
              decoration: vInputDecoration(
                context,
                hint: 'Add context for the file: why this message matters, what to verify, who to ask…',
                radius: 8.0,
              ).copyWith(counterText: ''),
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            children: [
              Expanded(child: Text('Ctrl/⌘ + Enter to save', style: VT.muted(context, size: 10.0))),
              VButton(label: 'Cancel', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: widget.onCancel),
              const SizedBox(width: 8.0),
              VButton(
                label: widget.initial != null ? 'Save changes' : 'Add annotation',
                size: VButtonSize.sm,
                loading: _saving,
                onPressed: _text.text.trim().isEmpty ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AnnotationCard extends StatelessWidget {
  const AnnotationCard({super.key, required this.annotation, required this.onEdit, required this.onDelete});

  final Annotation annotation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final a = annotation;
    final accent = a.tag.color(c);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3.0, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VBadge(label: a.tag.label, bg: a.tag.bg(c), fg: accent, size: 10.0),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${a.authorName.isEmpty ? 'Someone' : a.authorName} · ${a.createdAt == null ? 'just now' : fmtWhen(a.createdAt)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VT.muted(context, size: 10.0),
                          ),
                        ),
                        if (a.canEdit) ...[
                          VHover(
                            onTap: onEdit,
                            builder: (context, hovered) => Text('Edit',
                                style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: c.tealDeep)
                                    .copyWith(decoration: hovered ? TextDecoration.underline : null)),
                          ),
                          const SizedBox(width: 8.0),
                          Tooltip(
                            message: 'Delete annotation',
                            child: VHover(
                              onTap: onDelete,
                              builder: (context, hovered) =>
                                  Icon(Icons.close, size: 14.0, color: hovered ? c.foreground : c.mutedFg),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(a.text, style: VT.body(context, size: 13.0, height: 1.35)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
