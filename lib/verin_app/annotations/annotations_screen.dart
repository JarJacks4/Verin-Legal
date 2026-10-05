// Annotations — every note the firm has added to reconstructed threads, in
// one place: filter by tag, matter, author or text; edit or remove your own;
// jump back to the message in its thread; copy a filtered set for a brief.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matter/annotations.dart';
import '../matters/matters_screen.dart' show openMatter;
import '../onboarding/tour.dart';
import '../onboarding/tours.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';
import '../widgets/motion.dart';

class FirmAnnotation {
  FirmAnnotation(this.a, Map<String, dynamic> d)
      : matterRef = d['matterId'] as DocumentReference?,
        messageText = '${d['messageText'] ?? ''}',
        updatedAt = (d['updatedAt'] as Timestamp?)?.toDate();

  final Annotation a;
  final DocumentReference? matterRef;
  final String messageText;
  final DateTime? updatedAt;

  bool get mine => a.authorUid == currentUserUid;
}

Stream<List<FirmAnnotation>> firmAnnotationsStream() => FirebaseFirestore.instance
    .collection('Annotations')
    .where('firmID', isEqualTo: currentFirmId())
    .limit(2000)
    .snapshots()
    .map((s) => s.docs.map((d) => FirmAnnotation(Annotation(d.reference, d.data()), d.data())).toList()
      ..sort((x, y) => (y.a.createdAt ?? DateTime(2100)).compareTo(x.a.createdAt ?? DateTime(2100))));

enum _Who { mine, everyone }

class AnnotationsScreen extends StatefulWidget {
  const AnnotationsScreen({super.key});

  @override
  State<AnnotationsScreen> createState() => _AnnotationsScreenState();
}

class _AnnotationsScreenState extends State<AnnotationsScreen> {
  late final Stream<List<FirmAnnotation>> _notes = firmAnnotationsStream();
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  final _q = TextEditingController();
  _Who _who = _Who.mine;
  AnnTag? _tag;
  String _matter = ''; // matter path, '' = all
  String? _editing; // annotation path being edited

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  List<FirmAnnotation> _filter(List<FirmAnnotation> all) {
    final q = _q.text.trim().toLowerCase();
    return all.where((n) {
      if (_who == _Who.mine && !n.mine) return false;
      if (_tag != null && n.a.tag != _tag) return false;
      if (_matter.isNotEmpty && n.matterRef?.path != _matter) return false;
      if (q.isNotEmpty && !'${n.a.text} ${n.messageText} ${n.a.authorName}'.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
  }

  String _asText(List<FirmAnnotation> list, Map<String, MattersRecord> byPath) {
    final b = StringBuffer();
    String? last;
    for (final n in list) {
      final m = byPath[n.matterRef?.path];
      final title = m == null ? 'Matter' : (m.title.isEmpty ? 'Untitled matter' : m.title);
      if (title != last) {
        if (last != null) b.writeln();
        b.writeln(title.toUpperCase());
        last = title;
      }
      b.writeln('• [${n.a.tag.label}] ${n.a.text}');
      if (n.messageText.isNotEmpty) b.writeln('  Message: “${n.messageText}”');
      b.writeln('  — ${n.a.authorName.isEmpty ? 'Staff' : n.a.authorName}, ${fmtWhen(n.a.createdAt)}');
    }
    return b.toString();
  }

  Future<void> _delete(FirmAnnotation n) async {
    final ok = await showVDialog<bool>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Delete this annotation?', style: VT.h2(ctx, size: 18.0)),
          const SizedBox(height: 8.0),
          Text('The message and the record are not affected — only your note is removed.', style: VT.muted(ctx, size: 13.0)),
          const SizedBox(height: 18.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VButton(label: 'Cancel', kind: VButtonKind.secondary, onPressed: () => Navigator.of(ctx).pop(false)),
              const SizedBox(width: 8.0),
              VButton(label: 'Delete', kind: VButtonKind.danger, onPressed: () => Navigator.of(ctx).pop(true)),
            ],
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deleteAnnotation(n.a);
      if (mounted) showVToast(context, 'Annotation deleted');
    } catch (e) {
      if (mounted) showVToast(context, 'Could not delete', error: true, description: '$e');
    }
  }

  @override
  Widget build(BuildContext context) => TourLauncher(tourId: 'annotations', steps: annotationsTour, child: _page(context));

  Widget _page(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<MattersRecord>>(
      stream: _matters,
      builder: (context, ms) {
        final matters = ms.data ?? const <MattersRecord>[];
        final byPath = {for (final m in matters) m.reference.path: m};
        return StreamBuilder<List<FirmAnnotation>>(
          stream: _notes,
          builder: (context, snap) {
            final all = snap.data ?? const <FirmAnnotation>[];
            final scope = _who == _Who.mine ? all.where((n) => n.mine).toList() : all;
            final list = _filter(all);
            final count = {for (final t in AnnTag.values) t: scope.where((n) => n.a.tag == t).length};
            final usedMatters = matters.where((m) => all.any((n) => n.matterRef?.path == m.reference.path)).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40.0, 36.0, 40.0, 48.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        runSpacing: 16.0,
                        spacing: 16.0,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 620.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Annotations', style: VT.h1(context, size: 30.0)),
                                const SizedBox(height: 4.0),
                                Text('Notes added to messages in reconstructed threads. They are the firm\'s work product and never change the record.',
                                    style: VT.muted(context)),
                              ],
                            ),
                          ),
                          TourTarget(
                            id: 'ann_copy',
                            child: VButton(
                              label: 'Copy ${list.length == 1 ? '1 note' : '${list.length} notes'}',
                              icon: Icons.content_copy,
                              kind: VButtonKind.tonal,
                              onPressed: list.isEmpty
                                  ? null
                                  : () async {
                                      await Clipboard.setData(ClipboardData(text: _asText(list, byPath)));
                                      if (context.mounted) showVToast(context, 'Copied — paste into a brief or email');
                                    },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24.0),

                      // Tag tiles double as filters.
                      TourTarget(
                        id: 'ann_tags',
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final cols = box.maxWidth >= 720.0 ? 4 : 2;
                            final w = (box.maxWidth - 12.0 * (cols - 1)) / cols;
                            return Wrap(
                              spacing: 12.0,
                              runSpacing: 12.0,
                              children: [
                                for (final t in [AnnTag.key, AnnTag.followup, AnnTag.question, AnnTag.note])
                                  SizedBox(
                                    width: w,
                                    child: _TagTile(
                                      tag: t,
                                      count: count[t] ?? 0,
                                      selected: _tag == t,
                                      onTap: () => setState(() => _tag = _tag == t ? null : t),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      TourTarget(
                        id: 'ann_filters',
                        child: Wrap(
                          spacing: 12.0,
                          runSpacing: 12.0,
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            SizedBox(
                              width: 220.0,
                              child: VSegmented<_Who>(
                                value: _who,
                                options: _Who.values,
                                labelFor: (w) => w == _Who.mine ? 'Mine' : 'Everyone',
                                onChanged: (w) => setState(() => _who = w),
                              ),
                            ),
                            SizedBox(
                              width: 260.0,
                              child: VSelect<String>(
                                value: usedMatters.any((m) => m.reference.path == _matter) ? _matter : '',
                                items: ['', ...usedMatters.map((m) => m.reference.path)],
                                labelFor: (p) => p.isEmpty ? 'All matters' : (byPath[p]?.title.isNotEmpty == true ? byPath[p]!.title : 'Untitled matter'),
                                onChanged: (p) => setState(() => _matter = p),
                              ),
                            ),
                            SizedBox(
                              width: 300.0,
                              child: TextField(
                                controller: _q,
                                onChanged: (_) => setState(() {}),
                                style: VT.body(context),
                                cursorColor: c.teal,
                                decoration: vInputDecoration(
                                  context,
                                  hint: 'Search notes, messages or people',
                                  prefix: Icon(Icons.search, size: 16.0, color: c.mutedFg),
                                ).copyWith(fillColor: c.card),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),

                      if (snap.hasError)
                        VErrorBox(message: 'Annotations could not be loaded: ${snap.error}')
                      else if (!snap.hasData)
                        const VLoading()
                      else if (list.isEmpty)
                        VEmptyState(
                          icon: Icons.sticky_note_2_outlined,
                          title: all.isEmpty ? 'No annotations yet' : 'Nothing matches',
                          message: all.isEmpty
                              ? 'Open a matter, go to Thread, and use “Annotate” on any message to add a note. It will show up here.'
                              : 'Try another tag, matter or search, or switch to Everyone.',
                        )
                      else
                        TourTarget(
                          id: 'ann_list',
                          child: VFadeSwitch(
                            switchKey: '${_who.name}|${_tag?.name}|$_matter',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                for (final n in list)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: _NoteCard(
                                      note: n,
                                      matter: byPath[n.matterRef?.path],
                                      editing: _editing == n.a.ref.path,
                                      onEdit: () => setState(() => _editing = n.a.ref.path),
                                      onCancel: () => setState(() => _editing = null),
                                      onSaved: () => setState(() => _editing = null),
                                      onDelete: () => _delete(n),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TagTile extends StatelessWidget {
  const _TagTile({required this.tag, required this.count, required this.selected, required this.onTap});

  final AnnTag tag;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final fg = tag.color(c);
    return VHover(
      onTap: onTap,
      builder: (context, hovered) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: VMotion.standard,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: selected ? tag.bg(c) : c.card,
          borderRadius: BorderRadius.circular(VR.card),
          border: Border.all(color: selected ? fg : (hovered ? fg.withValues(alpha: 0.5) : c.border), width: selected ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 8.0, height: 8.0, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
                const SizedBox(width: 8.0),
                Expanded(child: Text(tag.label, style: VT.body(context, size: 12.5, weight: FontWeight.w600, color: fg))),
                if (selected) Icon(Icons.filter_alt, size: 14.0, color: fg),
              ],
            ),
            const SizedBox(height: 8.0),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: count.toDouble()),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text('${v.round()}', style: VT.h1(context, size: 26.0)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.note,
    required this.matter,
    required this.editing,
    required this.onEdit,
    required this.onCancel,
    required this.onSaved,
    required this.onDelete,
  });

  final FirmAnnotation note;
  final MattersRecord? matter;
  final bool editing;
  final VoidCallback onEdit;
  final VoidCallback onCancel;
  final VoidCallback onSaved;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final a = note.a;
    final fg = a.tag.color(c);
    final title = matter == null ? 'Matter' : (matter!.title.isEmpty ? 'Untitled matter' : matter!.title);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(VR.card),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0.0, top: 0.0, bottom: 0.0, width: 4.0, child: ColoredBox(color: fg)),
          Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 14.0, 12.0, 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        VBadge(label: a.tag.label, bg: a.tag.bg(c), fg: fg, bold: true),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 12.5, weight: FontWeight.w600, color: c.mutedFg)),
                        ),
                        if (a.canEdit && !editing) ...[
                          VIconButton(icon: Icons.edit_outlined, size: 15.0, tooltip: 'Edit', onPressed: onEdit),
                          VIconButton(icon: Icons.delete_outline, size: 15.0, tooltip: 'Delete', onPressed: onDelete),
                        ],
                      ],
                    ),
                    if (note.messageText.isNotEmpty) ...[
                      const SizedBox(height: 10.0),
                      Container(
                        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 8.0),
                        decoration: BoxDecoration(color: c.background, borderRadius: BorderRadius.circular(10.0)),
                        child: Text('“${note.messageText}”', maxLines: 4, overflow: TextOverflow.ellipsis, style: VT.serif(context, size: 13.5, weight: FontWeight.w400)),
                      ),
                    ],
                    const SizedBox(height: 10.0),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: VMotion.standard,
                      alignment: Alignment.topLeft,
                      child: editing
                          ? AnnotationComposer(
                              initial: a,
                              onCancel: onCancel,
                              onSave: (text, tag) async {
                                try {
                                  await updateAnnotation(a, text: text, tag: tag);
                                  onSaved();
                                } catch (e) {
                                  if (context.mounted) showVToast(context, 'Could not save', error: true, description: '$e');
                                }
                              },
                            )
                          : SizedBox(width: double.infinity, child: Text(a.text, style: VT.body(context, size: 14.0, height: 1.55))),
                    ),
                    const SizedBox(height: 10.0),
                    Row(
                      children: [
                        VAvatar(initials: _initials(a.authorName), size: 22.0),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            '${note.mine ? 'You' : (a.authorName.isEmpty ? 'Staff' : a.authorName)} · ${fmtWhen(a.createdAt)}${note.updatedAt != null ? ' · edited' : ''}',
                            style: VT.muted(context, size: 12.0),
                          ),
                        ),
                        if (matter != null)
                          VButton(
                            label: 'Open in thread',
                            icon: Icons.forum_outlined,
                            kind: VButtonKind.link,
                            size: VButtonSize.sm,
                            onPressed: () => openMatter(context, matter!, tab: 'thread'),
                          ),
                      ],
                    ),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '·';
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}
