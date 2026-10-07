// Evidence verification view (Differentiator 1).
//
// The original as received on one side, the reconstructed record on the
// other. Selecting a line highlights exactly where it came from — the box on
// the screenshot, the page of the PDF, the paragraph of the document, the
// moment in the recording — so a reviewer checks every word against its
// source. Uncertain dates, unconfirmed names and hard-to-read lines are
// flagged on each line. Reviewers can correct a reading; the original and the
// AI's reading are never changed.

import 'dart:async';

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/corrections.dart';
import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

/// Opens the side-by-side view for one receipt, optionally focused on a
/// message (by on-screen index) or a statement.
Future<void> showVerificationView(
  BuildContext context, {
  required ReceiptsRecord receipt,
  required MattersRecord matter,
  int? messageIndex,
  int? statementIndex,
}) =>
    showVDrawer<void>(
      context,
      title: 'Verify against the original',
      width: 1180.0,
      scroll: false,
      builder: (_) => VerificationView(receipt: receipt, matter: matter, messageIndex: messageIndex, statementIndex: statementIndex),
    );

/// One checkable line: an extracted message or a key passage.
class _Item {
  _Item({required this.type, required this.index, required this.raw});
  final String type; // 'm' message, 's' statement
  final int index;
  final Map<String, dynamic> raw;

  String get text => '${raw['text'] ?? ''}';
  SourceBox? get box => SourceBox.from(raw['box']);
  int get page => raw['page'] is num ? (raw['page'] as num).toInt() : 0;
  int? get atSeconds => raw['atSeconds'] is num ? (raw['atSeconds'] as num).toInt() : null;
  String get sender => '${raw['senderName'] ?? ''}';
  double get read => raw['confidence'] is num ? (raw['confidence'] as num).toDouble() : 1.0;
  bool get isClient => '${raw['speaker'] ?? ''}'.toLowerCase() == 'client';
  String get kind => '${raw['kind'] ?? ''}';
  String get label => '${raw['timestampLabel'] ?? ''}';
}

class VerificationView extends StatefulWidget {
  const VerificationView({super.key, required this.receipt, required this.matter, this.messageIndex, this.statementIndex});

  final ReceiptsRecord receipt;
  final MattersRecord matter;
  final int? messageIndex;
  final int? statementIndex;

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  late final List<_Item> _items = _buildItems();
  late int _sel = _initialSelection();
  late final Stream<ThreadDoc?> _thread = matterThreadStream(widget.matter.reference);
  late final Stream<Map<String, Map<String, Correction>>> _corr = matterCorrectionsStream(widget.matter.reference);
  final _origScroll = ScrollController();
  final _listScroll = ScrollController();
  final _paraKey = GlobalKey();
  final _opened = DateTime.now();
  final Set<int> _viewed = {};

  ReceiptsRecord get r => widget.receipt;

  List<_Item> _buildItems() {
    final out = <_Item>[];
    final msgs = r.snapshotData['threadMessages'];
    if (msgs is List) {
      for (var i = 0; i < msgs.length; i++) {
        final m = msgs[i];
        if (m is Map && m['isHeader'] != true) out.add(_Item(type: 'm', index: i, raw: Map<String, dynamic>.from(m)));
      }
    }
    final st = r.snapshotData['statements'];
    if (st is List) {
      for (var i = 0; i < st.length; i++) {
        final s = st[i];
        if (s is Map) out.add(_Item(type: 's', index: i, raw: Map<String, dynamic>.from(s)));
      }
    }
    return out;
  }

  int _initialSelection() {
    if (_items.isEmpty) return -1;
    final idx = _items.indexWhere((it) =>
        (widget.messageIndex != null && it.type == 'm' && it.index == widget.messageIndex) ||
        (widget.statementIndex != null && it.type == 's' && it.index == widget.statementIndex));
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    if (_sel >= 0) _viewed.add(_sel);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  @override
  void dispose() {
    // Review time for the value report (only real reviews, capped at 30 min).
    final ms = DateTime.now().difference(_opened).inMilliseconds;
    if (ms >= 4000 && currentUserUid.isNotEmpty) {
      unawaited(FirebaseFirestore.instance.collection('Activity').add({
        'firmID': currentFirmId(),
        'matterId': widget.matter.reference,
        'receiptId': r.reference,
        'uid': currentUserUid,
        'type': 'review',
        'durationMs': ms > 1800000 ? 1800000 : ms,
        'itemsViewed': _viewed.length,
        'itemsTotal': _items.length,
        'at': FieldValue.serverTimestamp(),
      }).then((_) {}, onError: (_) {}));
    }
    _origScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _select(int i) {
    setState(() {
      _sel = i;
      _viewed.add(i);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  // Bring the highlighted source into view.
  double _imageHeight = 0;
  void _reveal() {
    if (!mounted || _sel < 0) return;
    final box = _items[_sel].box;
    if (box != null && _imageHeight > 0 && _origScroll.hasClients) {
      final target = (box.y * _imageHeight - 80.0).clamp(0.0, _origScroll.position.maxScrollExtent);
      _origScroll.animateTo(target, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
    final ctx = _paraKey.currentContext;
    if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 280), alignment: 0.2);
  }

  bool get _isImage {
    final w = r.snapshotData['imageWidth'];
    return r.sourceUrl.isNotEmpty && (w is num || r.itemKind == 'photo' || r.itemKind == 'screenshot' || r.itemKind == 'image');
  }

  bool get _isPdf => r.sourceStoragePath.toLowerCase().endsWith('.pdf') || '${r.snapshotData['contentType'] ?? ''}'.contains('pdf');
  bool get _isMedia => ['video', 'audio', 'screen_recording'].contains(r.itemKind);
  String get _docText => '${r.snapshotData['documentText'] ?? ''}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThreadDoc?>(
      stream: _thread,
      builder: (context, ts) => StreamBuilder<Map<String, Map<String, Correction>>>(
        stream: _corr,
        builder: (context, cs) => _layout(context, ts.data, cs.data ?? const {}),
      ),
    );
  }

  Widget _layout(BuildContext context, ThreadDoc? thread, Map<String, Map<String, Correction>> corr) {
    final c = VC.of(context);
    final byIndex = thread?.forReceipt(r.reference.id) ?? const <int, TEntry>{};
    final original = _originalPane(context);
    final record = _recordPane(context, byIndex, corr, thread);
    return LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 860.0;
      final header = Container(
        padding: const EdgeInsets.fromLTRB(24.0, 14.0, 24.0, 14.0),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.border))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, weight: FontWeight.w600)),
            const SizedBox(height: 2.0),
            Text(
              '${r.kindLabel} · received ${fmtWhen(r.receivedAt)} · SHA-256 ${r.itemHash.length > 16 ? '${r.itemHash.substring(0, 16)}…' : r.itemHash}',
              style: VT.muted(context, size: 12.0),
            ),
          ],
        ),
      );
      final body = wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 11, child: _paneFrame(context, 'ORIGINAL AS RECEIVED', original)),
                Container(width: 1.0, color: c.border),
                Expanded(flex: 9, child: _paneFrame(context, 'ASSEMBLED RECORD', record)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: box.maxHeight * 0.45, child: _paneFrame(context, 'ORIGINAL AS RECEIVED', original)),
                Container(height: 1.0, color: c.border),
                Expanded(child: _paneFrame(context, 'ASSEMBLED RECORD', record)),
              ],
            );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, Expanded(child: body)],
      );
    });
  }

  Widget _paneFrame(BuildContext context, String label, Widget child) {
    final c = VC.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: c.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Text(label, style: VT.eyebrow(context, size: 10.0, color: c.mutedFg)),
        ),
        Expanded(child: child),
      ],
    );
  }

  // ---------------------------------------------------------------- original

  Widget _originalPane(BuildContext context) {
    final c = VC.of(context);
    final sel = _sel >= 0 ? _items[_sel] : null;
    if (_isImage) return _imagePane(context, sel);
    if (_docText.isNotEmpty) return _textPane(context, sel);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isPdf) ...[
            Text(
              sel != null && sel.page > 0 ? 'Page ${sel.page} of the PDF' : 'PDF',
              style: VT.body(context, size: 15.0, weight: FontWeight.w600),
            ),
            const SizedBox(height: 8.0),
            if (sel != null) _quote(context, sel.text),
            const SizedBox(height: 16.0),
            Wrap(spacing: 10.0, runSpacing: 10.0, children: [
              if (sel != null && sel.page > 0)
                VButton(label: 'Open page ${sel.page}', icon: Icons.open_in_new, size: VButtonSize.sm, onPressed: () => launchURL('${r.sourceUrl}#page=${sel.page}')),
              VButton(label: 'Open the original', icon: Icons.description_outlined, kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => launchURL(r.sourceUrl)),
            ]),
            const SizedBox(height: 12.0),
            Text('The PDF opens in your browser at that page; find the passage above on it.', style: VT.muted(context, size: 12.0)),
          ] else if (_isMedia) ...[
            Text(sel?.atSeconds != null ? 'At ${_mmss(sel!.atSeconds!)} in the recording' : 'Recording', style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
            const SizedBox(height: 8.0),
            if (sel != null) _quote(context, sel.text),
            const SizedBox(height: 16.0),
            VButton(
              label: sel?.atSeconds != null ? 'Play from ${_mmss(sel!.atSeconds!)}' : 'Open the recording',
              icon: Icons.play_arrow_rounded,
              size: VButtonSize.sm,
              onPressed: () => launchURL(sel?.atSeconds != null ? '${r.sourceUrl}#t=${sel!.atSeconds}' : r.sourceUrl),
            ),
          ] else ...[
            Icon(Icons.insert_drive_file_outlined, size: 28.0, color: c.mutedFg),
            const SizedBox(height: 8.0),
            Text('This item can only be viewed in its own app.', style: VT.muted(context)),
            const SizedBox(height: 12.0),
            if (r.sourceUrl.isNotEmpty)
              Align(alignment: Alignment.centerLeft, child: VButton(label: 'Open the original', icon: Icons.open_in_new, size: VButtonSize.sm, onPressed: () => launchURL(r.sourceUrl))),
          ],
        ],
      ),
    );
  }

  Widget _quote(BuildContext context, String text) {
    final c = VC.of(context);
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: c.pending.withValues(alpha: 0.10),
        border: Border(left: BorderSide(color: c.pending, width: 3.0)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: SelectableText(text, style: VT.body(context, size: 14.0, height: 1.45)),
    );
  }

  Widget _imagePane(BuildContext context, _Item? sel) {
    final c = VC.of(context);
    final iw = r.snapshotData['imageWidth'];
    final ih = r.snapshotData['imageHeight'];
    final hasDims = iw is num && ih is num && iw > 0 && ih > 0;
    final located = _items.where((it) => it.box != null).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!hasDims || (located == 0 && _items.isNotEmpty))
          Container(
            margin: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
            child: VNotice(
              text: !hasDims
                  ? 'This item was read before lines were located on images. Use "Run AI reading again" on the receipt to add highlights.'
                  : 'The reading could not place these lines on the image; compare them by eye.',
            ),
          ),
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth - 32.0;
            final h = hasDims ? w * (ih.toDouble() / iw.toDouble()) : null;
            _imageHeight = h ?? 0;
            final image = Image.network(
              r.sourceUrl,
              width: w,
              height: h,
              fit: hasDims ? BoxFit.fill : BoxFit.fitWidth,
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              errorBuilder: (context, _, __) => Container(
                height: 200.0,
                alignment: Alignment.center,
                color: c.secondary,
                child: VButton(label: 'Open the original', icon: Icons.open_in_new, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: () => launchURL(r.sourceUrl)),
              ),
            );
            return SingleChildScrollView(
              controller: _origScroll,
              padding: const EdgeInsets.all(16.0),
              child: !hasDims
                  ? image
                  : SizedBox(
                      width: w,
                      height: h,
                      child: Stack(
                        children: [
                          Positioned.fill(child: image),
                          for (var i = 0; i < _items.length; i++)
                            if (_items[i].box != null) _boxOverlay(context, i, _items[i].box!.toRect(Size(w, h!))),
                        ],
                      ),
                    ),
            );
          }),
        ),
      ],
    );
  }

  Widget _boxOverlay(BuildContext context, int i, Rect rect) {
    final c = VC.of(context);
    final on = i == _sel;
    return Positioned(
      left: rect.left - 3.0,
      top: rect.top - 3.0,
      width: rect.width + 6.0,
      height: rect.height + 6.0,
      child: GestureDetector(
        onTap: () => _select(i),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: on ? c.pending.withValues(alpha: 0.18) : Colors.transparent,
              border: Border.all(color: on ? c.pending : c.teal.withValues(alpha: 0.35), width: on ? 2.5 : 1.0),
              borderRadius: BorderRadius.circular(6.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textPane(BuildContext context, _Item? sel) {
    final c = VC.of(context);
    final text = _docText;
    final paras = text.split(RegExp(r'\n\s*\n')).where((p) => p.trim().isNotEmpty).take(600).toList();
    String norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
    final needle = sel == null ? '' : norm(sel.text);
    final probe = needle.length > 60 ? needle.substring(0, 60) : needle;
    var hit = -1;
    if (probe.isNotEmpty) hit = paras.indexWhere((p) => norm(p).contains(probe));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.snapshotData['documentTextTruncated'] == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Text('Long document — the start is shown here; open the original for the rest.', style: VT.muted(context, size: 12.0)),
            ),
          if (sel != null && hit < 0 && needle.isNotEmpty) ...[
            _quote(context, sel.text),
            const SizedBox(height: 6.0),
            Text('This exact wording wasn\'t found in the text below; it may span a page break or be in an attachment.', style: VT.muted(context, size: 12.0)),
            const SizedBox(height: 16.0),
          ],
          for (var i = 0; i < paras.length; i++)
            Container(
              key: i == hit ? _paraKey : null,
              margin: const EdgeInsets.only(bottom: 10.0),
              padding: i == hit ? const EdgeInsets.all(10.0) : EdgeInsets.zero,
              decoration: i == hit
                  ? BoxDecoration(color: c.pending.withValues(alpha: 0.12), border: Border(left: BorderSide(color: c.pending, width: 3.0)), borderRadius: BorderRadius.circular(6.0))
                  : null,
              child: SelectableText(paras[i].trim(), style: VT.body(context, size: 13.0, height: 1.5)),
            ),
          if (r.sourceUrl.isNotEmpty)
            Align(alignment: Alignment.centerLeft, child: VButton(label: 'Open the original file', icon: Icons.open_in_new, kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => launchURL(r.sourceUrl))),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- record

  Widget _recordPane(BuildContext context, Map<int, TEntry> byIndex, Map<String, Map<String, Correction>> corr, ThreadDoc? thread) {
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: VEmptyState(
          compact: true,
          icon: Icons.fact_check_outlined,
          title: 'Nothing extracted to check',
          message: r.aiSummary.isNotEmpty ? r.aiSummary : 'This item has no messages or key passages read from it yet.',
        ),
      );
    }
    int flagCount = 0;
    for (final it in _items) {
      if (_flags(it, it.type == 'm' ? byIndex[it.index] : null).isNotEmpty) flagCount++;
    }
    return ListView(
      controller: _listScroll,
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4.0, 0.0, 4.0, 10.0),
          child: Text(
            '${_items.length} line${_items.length == 1 ? '' : 's'} read · ${flagCount == 0 ? 'nothing flagged' : '$flagCount flagged for a closer look'}',
            style: VT.muted(context, size: 12.0),
          ),
        ),
        for (var i = 0; i < _items.length; i++) _row(context, i, byIndex, corr),
        const SizedBox(height: 12.0),
        Text(
          'The original is the evidence. The record beside it is a reading aid — check flagged lines against the highlighted source.',
          style: VT.muted(context, size: 11.0),
        ),
      ],
    );
  }

  /// (label, tone) flags for one line.
  List<(String, Color)> _flags(_Item it, TEntry? e) {
    final c = VC.of(context);
    final out = <(String, Color)>[];
    if (it.type == 'm') {
      if (e != null) {
        if (e.has('no_date')) out.add(('No date', c.pending));
        if (e.has('date_uncertain')) out.add(('Date ${e.dateBasisLabel}', c.pending));
        if (e.has('year_inferred')) out.add(('Year inferred', c.pending));
        if (e.has('out_of_order')) out.add(('Dated before the line above', c.broken));
        if (e.has('sender_not_shown')) out.add(('Sender not named', c.pending));
        if (e.has('name_unconfirmed')) out.add(('Name not confirmed', c.pending));
      } else if (it.label.trim().isEmpty) {
        out.add(('No date', c.pending));
      }
      if (it.read < 0.75) out.add(('Hard to read · ${(it.read * 100).round()}%', c.broken));
    }
    if (_isImage && it.box == null && r.snapshotData['imageWidth'] is num) out.add(('Not located on image', c.mutedFg));
    return out;
  }

  Widget _row(BuildContext context, int i, Map<int, TEntry> byIndex, Map<String, Map<String, Correction>> corr) {
    final c = VC.of(context);
    final it = _items[i];
    final e = it.type == 'm' ? byIndex[it.index] : null;
    final on = i == _sel;
    final target = correctionTarget(r.reference.id, it.type, it.index);
    final fix = corr[target] ?? const {};
    final textFix = fix['text'];
    final flags = _flags(it, e);
    final who = it.type == 'm'
        ? (it.isClient
            ? (widget.matter.clientName.isNotEmpty ? widget.matter.clientName : 'Client')
            : (e != null && e.person.isNotEmpty ? e.person : it.sender.isNotEmpty ? it.sender : 'Other party'))
        : _kindLabel(it.kind);
    final when = it.type == 'm' ? (e != null ? e.whenLabel : (it.label.isNotEmpty ? it.label : 'no date')) : (it.page > 0 ? 'page ${it.page}' : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: VHover(
        onTap: () => _select(i),
        builder: (context, hovered) => AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(14.0, 10.0, 12.0, 10.0),
          decoration: BoxDecoration(
            color: on ? c.pending.withValues(alpha: 0.08) : (hovered ? c.secondary : c.card),
            border: Border.all(color: on ? c.pending : c.border, width: on ? 1.5 : 1.0),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(children: [
                        TextSpan(text: who, style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: it.isClient ? c.tealDeep : c.foreground)),
                        if (when.isNotEmpty) TextSpan(text: '  ·  $when', style: VT.muted(context, size: 11.0)),
                      ]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (on)
                    Tooltip(
                      message: 'Note a transcription discrepancy',
                      child: VHover(
                        onTap: () => _correct(it, textFix),
                        builder: (context, h) => Padding(
                          padding: const EdgeInsets.only(left: 6.0),
                          child: Text('Note discrepancy', style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: h ? c.teal : c.tealDeep)),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4.0),
              if (textFix != null) ...[
                Text(textFix.corrected, style: VT.body(context, size: 13.5, height: 1.4)),
                const SizedBox(height: 4.0),
                Text('AI read: "${it.text}"', style: VT.muted(context, size: 11.0).copyWith(decoration: TextDecoration.lineThrough)),
                Text('Reviewer reading by ${textFix.byName.isEmpty ? 'a reviewer' : textFix.byName}${textFix.at != null ? ' · ${fmtWhen(textFix.at)}' : ''}',
                    style: VT.body(context, size: 10.5, color: c.verified)),
              ] else
                Text(it.text, style: VT.body(context, size: 13.5, height: 1.4)),
              if (e != null && on && e.date.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text('Date: ${e.dateBasisLabel}${e.dateConfidence.isNotEmpty ? ' · ${e.dateConfidence} confidence' : ''}', style: VT.muted(context, size: 11.0)),
              ],
              // Wrong dates and wrong thread placement are counted for the
              // accuracy measure on the Admin dashboard.
              for (final (f, label) in const [('date', 'Date'), ('thread', 'Placement')])
                if (fix[f] != null) ...[
                  const SizedBox(height: 4.0),
                  Text('$label noted by ${fix[f]!.byName.isEmpty ? 'a reviewer' : fix[f]!.byName}: ${fix[f]!.corrected}', style: VT.body(context, size: 10.5, color: c.pending)),
                ],
              if (on && it.type == 'm') ...[
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 12.0,
                  children: [
                    for (final (f, label) in const [('date', 'Date is wrong'), ('thread', 'Wrong place in thread')])
                      VHover(
                        onTap: () => _noteOther(it, f, e?.whenLabel ?? when, fix[f]),
                        builder: (context, h) => Text(label, style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: h ? c.teal : c.tealDeep)),
                      ),
                  ],
                ),
              ],
              if (e != null && e.alsoIn.isNotEmpty) ...[
                const SizedBox(height: 4.0),
                Text('Also in ${e.alsoIn.length} other screenshot${e.alsoIn.length == 1 ? '' : 's'} — shown once in the thread', style: VT.muted(context, size: 11.0)),
              ],
              if (flags.isNotEmpty) ...[
                const SizedBox(height: 6.0),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [for (final (label, tone) in flags) VBadge(label: label, bg: tone.withValues(alpha: 0.12), fg: tone, size: 10.0)],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _correct(_Item it, Correction? existing) async {
    final ok = await showCorrectionDialog(
      context,
      title: it.type == 'm' ? 'Note a discrepancy in this message' : 'Note a discrepancy in this passage',
      fieldLabel: 'What the original says',
      aiValue: it.text,
      current: existing?.corrected,
      onSave: (v) => saveCorrection(
        matter: widget.matter.reference,
        receipt: r.reference,
        target: correctionTarget(r.reference.id, it.type, it.index),
        field: 'text',
        original: it.text,
        corrected: v,
      ),
    );
    if (ok && mounted) showVToast(context, 'Reviewer note saved');
  }

  Future<void> _noteOther(_Item it, String field, String shown, Correction? existing) async {
    final date = field == 'date';
    final ok = await showCorrectionDialog(
      context,
      title: date ? 'Note a wrong date' : 'Note a wrong place in the thread',
      fieldLabel: date ? 'The correct date and time' : 'Where it belongs (or what is wrong)',
      aiValue: date ? shown : '',
      current: existing?.corrected,
      multiline: !date,
      onSave: (v) => saveCorrection(
        matter: widget.matter.reference,
        receipt: r.reference,
        target: correctionTarget(r.reference.id, it.type, it.index),
        field: field,
        original: date ? shown : it.text,
        corrected: v,
      ),
    );
    if (ok && mounted) showVToast(context, 'Reviewer note saved');
  }

  static String _kindLabel(String k) => switch (k) {
        'date' => 'Date',
        'amount' => 'Amount',
        'person' => 'Person',
        'place' => 'Place',
        'event' => 'Event',
        _ => 'Passage',
      };

  static String _mmss(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
