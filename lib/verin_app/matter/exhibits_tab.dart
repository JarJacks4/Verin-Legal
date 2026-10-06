// Exhibits tab — reviewable exhibit production (Differentiator 5).
//
// A production is a draft until produced: pick the items, put them in order,
// review the redactions Verin suggests (and draw your own), then produce.
// Producing builds Bates-stamped, slip-sheeted exhibits with an index and a
// versioned ZIP on the server (functions/verin/exhibits). Final versions never
// change; a new version gets new Bates numbers and the old ones stay.

import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../data/record_view.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/drawer.dart';

// ---------------------------------------------------------------- template

/// The firm's exhibit template with defaults (mirrors functions/verin/exhibits/template.js).
class ExhibitTemplate {
  ExhibitTemplate(Map<String, dynamic>? t)
      : batesPrefix = _str(t?['batesPrefix'], 'VERIN'),
        batesDigits = (t?['batesDigits'] is num) ? (t!['batesDigits'] as num).toInt().clamp(3, 10) : 6,
        exhibitStyle = t?['exhibitStyle'] == 'letter' ? 'letter' : 'number',
        exhibitWord = _str(t?['exhibitWord'], 'Exhibit'),
        stampPosition = const ['bottom-right', 'bottom-center', 'bottom-left'].contains(t?['stampPosition']) ? t!['stampPosition'] as String : 'bottom-right',
        legend = _str(t?['legend'], ''),
        slipSheets = t?['slipSheets'] != false,
        indexTitle = _str(t?['indexTitle'], 'Exhibit Index');

  final String batesPrefix, exhibitStyle, exhibitWord, stampPosition, legend, indexTitle;
  final int batesDigits;
  final bool slipSheets;

  static String _str(Object? v, String d) => v is String && v.trim().isNotEmpty ? v.trim() : d;

  static ExhibitTemplate of(FirmAccountRecord? f) {
    final t = f?.snapshotData['productionTemplate'];
    return ExhibitTemplate(t is Map ? Map<String, dynamic>.from(t) : null);
  }

  String bates(int n) => '$batesPrefix-${n.toString().padLeft(batesDigits, '0')}';

  String exhibit(int n) {
    if (exhibitStyle != 'letter') return '$exhibitWord $n';
    var s = '';
    var k = n;
    while (k > 0) {
      final r = (k - 1) % 26;
      s = String.fromCharCode(65 + r) + s;
      k = (k - 1) ~/ 26;
    }
    return '$exhibitWord $s';
  }
}

// ---------------------------------------------------------------- data

class RedactionMark {
  RedactionMark({required this.page, required this.box, required this.reason, required this.source});
  final int page;
  final SourceBox box;
  final String reason, source; // source: ai | manual

  Map<String, dynamic> toMap() => {
        'page': page,
        'box': {'x': box.x, 'y': box.y, 'w': box.w, 'h': box.h},
        'reason': reason,
        'source': source,
      };

  static RedactionMark? from(Object? v) {
    if (v is! Map) return null;
    final b = SourceBox.from(v['box']);
    if (b == null) return null;
    return RedactionMark(page: v['page'] is num ? (v['page'] as num).toInt() : 0, box: b, reason: '${v['reason'] ?? 'other'}', source: '${v['source'] ?? 'manual'}');
  }
}

class ProdItem {
  ProdItem({required this.receiptId, this.include = true, List<RedactionMark>? redactions, List<String>? textRedactions, this.reviewed = false})
      : redactions = redactions ?? [],
        textRedactions = textRedactions ?? [];
  final String receiptId;
  bool include;
  final List<RedactionMark> redactions;
  final List<String> textRedactions;
  bool reviewed;

  Map<String, dynamic> toMap() => {
        'receiptId': receiptId,
        'include': include,
        'redactions': redactions.map((r) => r.toMap()).toList(),
        'textRedactions': textRedactions,
        'reviewed': reviewed,
      };

  static ProdItem from(Map m) => ProdItem(
        receiptId: '${m['receiptId']}',
        include: m['include'] != false,
        redactions: (m['redactions'] is List ? m['redactions'] as List : const []).map(RedactionMark.from).whereType<RedactionMark>().toList(),
        textRedactions: (m['textRedactions'] is List ? m['textRedactions'] as List : const []).whereType<String>().toList(),
        reviewed: m['reviewed'] == true,
      );
}

class Production {
  Production(this.ref, Map<String, dynamic> d)
      : name = '${d['name'] ?? ''}',
        status = '${d['status'] ?? 'draft'}',
        version = d['version'] is num ? (d['version'] as num).toInt() : 0,
        batesStart = '${d['batesStart'] ?? ''}',
        batesEnd = '${d['batesEnd'] ?? ''}',
        pageCount = d['pageCount'] is num ? (d['pageCount'] as num).toInt() : 0,
        finalizedByName = '${d['finalizedByName'] ?? ''}',
        finalizedAt = (d['finalizedAt'] as Timestamp?)?.toDate(),
        createdAt = (d['createdAt'] as Timestamp?)?.toDate(),
        items = (d['items'] is List ? d['items'] as List : const []).whereType<Map>().map(ProdItem.from).toList(),
        exhibits = (d['exhibits'] is List ? d['exhibits'] as List : const []).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList(),
        files = d['files'] is Map ? Map<String, dynamic>.from(d['files'] as Map) : const {};
  final DocumentReference ref;
  final String name, status, batesStart, batesEnd, finalizedByName;
  final int version, pageCount;
  final DateTime? finalizedAt, createdAt;
  final List<ProdItem> items;
  final List<Map<String, dynamic>> exhibits;
  final Map<String, dynamic> files;

  bool get isFinal => status == 'final';
  String fileUrl(String k) => files[k] is Map ? '${(files[k] as Map)['url'] ?? ''}' : '';
}

Stream<List<Production>> productionsStream(DocumentReference matter) => matter
    .collection('productions')
    .snapshots()
    .map((s) => s.docs.map((d) => Production(d.reference, d.data())).toList()
      ..sort((a, b) {
        if (a.isFinal != b.isFinal) return a.isFinal ? 1 : -1;
        if (a.isFinal) return b.version.compareTo(a.version);
        return (b.createdAt ?? DateTime(2100)).compareTo(a.createdAt ?? DateTime(2100));
      }));

/// Redaction suggestions read from an item (see functions/verin/evidence/source.js).
List<Map<String, dynamic>> sensitiveOf(ReceiptsRecord r) {
  final v = r.snapshotData['sensitive'];
  return v is List ? v.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList() : const [];
}

String categoryLabel(String c) => switch (c) {
      'ssn' => 'SSN',
      'tax_id' => 'Tax ID',
      'account' => 'Account number',
      'birth_date' => 'Birth date',
      'minor_name' => 'Child\'s name',
      'address' => 'Home address',
      'phone' => 'Phone number',
      'email' => 'Email address',
      _ => 'Other',
    };

bool _isImage(ReceiptsRecord r) => r.snapshotData['imageWidth'] is num || ((r.itemKind == 'photo' || r.itemKind == 'screenshot') && r.sourceUrl.isNotEmpty);

// ---------------------------------------------------------------- tab

class ExhibitsTab extends StatefulWidget {
  const ExhibitsTab({super.key, required this.matter, required this.receipts});
  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;

  @override
  State<ExhibitsTab> createState() => _ExhibitsTabState();
}

class _ExhibitsTabState extends State<ExhibitsTab> {
  late final Stream<List<Production>> _prods = productionsStream(widget.matter.reference);
  late final Stream<FirmAccountRecord?> _firmStream = firmAccountStream();
  FirmAccountRecord? _firm;

  int get _nextBates {
    final v = widget.matter.snapshotData['batesNext'];
    return v is num && v > 0 ? v.toInt() : 1;
  }

  Future<void> _new({Production? from}) async {
    final usable = widget.receipts.where((r) => !r.isDuplicate).toList()
      ..sort((a, b) => (a.resolvedDate ?? a.receivedAt ?? DateTime(2100)).compareTo(b.resolvedDate ?? b.receivedAt ?? DateTime(2100)));
    final items = from != null ? from.items.map((i) => ProdItem.from(i.toMap())).toList() : usable.map((r) => _seed(r)).toList();
    try {
      final ref = await widget.matter.reference.collection('productions').add({
        'name': from != null ? (from.name.isEmpty ? 'Production' : from.name) : 'Production ${DateTime.now().month}/${DateTime.now().day}',
        'status': 'draft',
        'items': items.map((i) => i.toMap()).toList(),
        'basedOnVersion': from?.version,
        'createdBy': currentUserUid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      final snap = await ref.get();
      if (mounted) await _edit(Production(ref, snap.data() as Map<String, dynamic>));
    } catch (e) {
      if (mounted) showVToast(context, 'Could not start a production: $e', error: true);
    }
  }

  /// A new item starts with Verin's redaction suggestions pre-selected for
  /// images (boxes) and other items (exact text); a person still reviews them.
  ProdItem _seed(ReceiptsRecord r) {
    final it = ProdItem(receiptId: r.reference.id);
    for (final s in sensitiveOf(r)) {
      final box = SourceBox.from(s['box']);
      if (_isImage(r) && box != null) {
        it.redactions.add(RedactionMark(page: 0, box: box, reason: '${s['category']}', source: 'ai'));
      } else if ('${s['text'] ?? ''}'.trim().length >= 2) {
        it.textRedactions.add('${s['text']}'.trim());
      }
    }
    return it;
  }

  Future<void> _edit(Production p) => showVDrawer<void>(
        context,
        title: p.name.isEmpty ? 'Production' : p.name,
        width: 980.0,
        tour: 'production_editor',
        builder: (_) => ProductionEditor(matter: widget.matter, receipts: widget.receipts, production: p, template: ExhibitTemplate.of(_firm), nextBates: _nextBates),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirmAccountRecord?>(
      stream: _firmStream,
      builder: (context, fs) {
        _firm = fs.data;
        return _body(context);
      },
    );
  }

  Widget _body(BuildContext context) {
    final c = VC.of(context);
    final tpl = ExhibitTemplate.of(_firm);
    return StreamBuilder<List<Production>>(
      stream: _prods,
      builder: (context, snap) {
        final prods = snap.data ?? const <Production>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text('Exhibit productions', style: VT.h2(context, size: 20.0))),
                VButton(label: 'New production', icon: Icons.add, size: VButtonSize.sm, onPressed: widget.receipts.isEmpty ? null : () => _new()),
              ],
            ),
            const SizedBox(height: 4.0),
            Text(
              'Numbered exhibits with Bates labels, slip sheets, an index and reviewed redactions — built from the originals, which are never altered. Each produced version is kept.',
              style: VT.muted(context),
            ),
            const SizedBox(height: 12.0),
            Wrap(spacing: 8.0, runSpacing: 8.0, children: [
              VBadge(label: 'Next Bates ${tpl.bates(_nextBates)}', bg: c.secondary, fg: c.tealDeep, size: 11.0),
              VBadge(label: 'Numbering: ${tpl.exhibit(1)}, ${tpl.exhibit(2)}…', bg: c.secondary, fg: c.tealDeep, size: 11.0),
              if (tpl.legend.isNotEmpty) VBadge(label: tpl.legend, bg: c.secondary, fg: c.oxblood, size: 11.0),
            ]),
            const SizedBox(height: 6.0),
            Text('The firm\'s exhibit template is set in Admin → Settings.', style: VT.muted(context, size: 11.0)),
            const SizedBox(height: 24.0),
            if (!snap.hasData)
              const VLoading()
            else if (prods.isEmpty)
              VEmptyState(
                icon: Icons.folder_copy_outlined,
                title: 'No productions yet',
                message: widget.receipts.isEmpty ? 'Once evidence arrives you can produce it as numbered exhibits.' : 'Start one to pick items, review redactions and produce Bates-stamped exhibits.',
                action: widget.receipts.isEmpty ? null : VButton(label: 'New production', icon: Icons.add, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: () => _new()),
              )
            else
              for (final p in prods) _card(context, p),
          ],
        );
      },
    );
  }

  Widget _card(BuildContext context, Production p) {
    final c = VC.of(context);
    final included = p.items.where((i) => i.include).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            VBadge(
              label: p.isFinal ? 'v${p.version} · final' : 'Draft',
              bg: (p.isFinal ? c.verified : c.pending).withValues(alpha: 0.12),
              fg: p.isFinal ? c.verified : c.pending,
              size: 10.0,
            ),
            const SizedBox(width: 10.0),
            Expanded(child: Text(p.name.isEmpty ? 'Production' : p.name, style: VT.body(context, weight: FontWeight.w600))),
          ]),
          const SizedBox(height: 6.0),
          Text(
            p.isFinal
                ? '${p.exhibits.length} exhibits · ${p.pageCount} pages · ${p.batesStart} – ${p.batesEnd} · produced ${fmtWhen(p.finalizedAt)}${p.finalizedByName.isNotEmpty ? ' by ${p.finalizedByName}' : ''}'
                : '$included of ${p.items.length} items included · ${p.items.where((i) => i.include && i.reviewed).length} reviewed',
            style: VT.muted(context, size: 12.0),
          ),
          const SizedBox(height: 12.0),
          Wrap(spacing: 10.0, runSpacing: 8.0, children: [
            if (p.isFinal) ...[
              VButton(label: 'Download ZIP', icon: Icons.download_outlined, size: VButtonSize.sm, onPressed: p.fileUrl('zip').isEmpty ? null : () => launchURL(p.fileUrl('zip'))),
              VButton(label: 'Production PDF', kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: p.fileUrl('pdf').isEmpty ? null : () => launchURL(p.fileUrl('pdf'))),
              VButton(label: 'Index', kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: p.fileUrl('index').isEmpty ? null : () => launchURL(p.fileUrl('index'))),
              VButton(label: 'New version from this', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => _new(from: p)),
            ] else ...[
              VButton(label: 'Continue', icon: Icons.edit_outlined, size: VButtonSize.sm, onPressed: () => _edit(p)),
              VButton(
                label: 'Delete draft',
                kind: VButtonKind.link,
                size: VButtonSize.sm,
                onPressed: () async {
                  try {
                    await p.ref.delete();
                  } catch (e) {
                    if (context.mounted) showVToast(context, 'Could not delete: $e', error: true);
                  }
                },
              ),
            ],
          ]),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- editor

class ProductionEditor extends StatefulWidget {
  const ProductionEditor({super.key, required this.matter, required this.receipts, required this.production, required this.template, required this.nextBates});
  final MattersRecord matter;
  final List<ReceiptsRecord> receipts;
  final Production production;
  final ExhibitTemplate template;
  final int nextBates;

  @override
  State<ProductionEditor> createState() => _ProductionEditorState();
}

class _ProductionEditorState extends State<ProductionEditor> {
  late final _name = TextEditingController(text: widget.production.name);
  late final List<ProdItem> _items = _merge();
  bool _saving = false;
  bool _producing = false;
  bool _dirty = false;
  String? _error;
  Map<String, dynamic>? _result;

  /// Draft items, plus any receipt that arrived since the draft was started (excluded by default).
  List<ProdItem> _merge() {
    final items = widget.production.items.map((i) => ProdItem.from(i.toMap())).toList();
    final have = items.map((i) => i.receiptId).toSet();
    for (final r in widget.receipts) {
      if (!r.isDuplicate && !have.contains(r.reference.id)) items.add(ProdItem(receiptId: r.reference.id, include: false));
    }
    return items;
  }

  ReceiptsRecord? _r(String id) {
    for (final r in widget.receipts) {
      if (r.reference.id == id) return r;
    }
    return null;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<bool> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.production.ref.update({
        'name': _name.text.trim(),
        'status': 'draft',
        'items': _items.where((i) => _r(i.receiptId) != null).map((i) => i.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) setState(() => _dirty = false);
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not save the draft: $e');
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _produce() async {
    final included = _items.where((i) => i.include && _r(i.receiptId) != null).toList();
    if (included.isEmpty) {
      setState(() => _error = 'Include at least one item.');
      return;
    }
    final unreviewed = included.where((i) => !i.reviewed && sensitiveOf(_r(i.receiptId)!).isNotEmpty).length;
    final ok = await showVDialog<bool>(
      context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Produce ${included.length} exhibit${included.length == 1 ? '' : 's'}?', style: VT.body(ctx, size: 16.0, weight: FontWeight.w600)),
          const SizedBox(height: 8.0),
          Text(
            'This makes a final, numbered version starting at ${widget.template.bates(widget.nextBates)}. It can\'t be edited afterwards — you can always produce a new version.',
            style: VT.muted(ctx, size: 13.0),
          ),
          if (unreviewed > 0) ...[
            const SizedBox(height: 12.0),
            VNotice(text: '$unreviewed item${unreviewed == 1 ? ' has' : 's have'} redaction suggestions nobody has reviewed. Suggested redactions are applied as selected.'),
          ],
          const SizedBox(height: 20.0),
          Row(children: [
            Expanded(child: VButton(label: 'Cancel', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => Navigator.of(ctx).pop(false))),
            const SizedBox(width: 12.0),
            Expanded(child: VButton(label: 'Produce', fullWidth: true, onPressed: () => Navigator.of(ctx).pop(true))),
          ]),
        ],
      ),
    );
    if (ok != true) return;
    if (!await _save()) return;
    setState(() {
      _producing = true;
      _error = null;
    });
    try {
      final r = await VerinApi.produceExhibits(matterId: widget.matter.reference.id, productionId: widget.production.ref.id);
      if (mounted) setState(() => _result = r);
    } on VerinApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _producing = false);
    }
  }

  void _move(int i, int d) {
    final j = i + d;
    if (j < 0 || j >= _items.length) return;
    setState(() {
      final t = _items[i];
      _items[i] = _items[j];
      _items[j] = t;
      _dirty = true;
    });
  }

  Future<void> _review(ProdItem it) async {
    final r = _r(it.receiptId);
    if (r == null) return;
    final changed = await showVDrawer<bool>(
      context,
      title: 'Review redactions',
      width: 900.0,
      builder: (_) => RedactionReview(receipt: r, item: it),
    );
    if (changed == true && mounted) setState(() => _dirty = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_result != null) {
      final r = _result!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VSuccessState(
            title: 'Production v${r['version']} is ready',
            desc: '${r['batesStart']} – ${r['batesEnd']} · ${r['pages']} pages. The originals are unchanged; every hash is in the manifest.',
          ),
          VButton(label: 'Download ZIP', icon: Icons.download_outlined, size: VButtonSize.lg, fullWidth: true, onPressed: () => launchURL('${r['zipUrl']}')),
          const SizedBox(height: 10.0),
          VButton(label: 'Open production PDF', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => launchURL('${r['pdfUrl']}')),
          const SizedBox(height: 10.0),
          VButton(label: 'Open index', kind: VButtonKind.secondary, fullWidth: true, onPressed: () => launchURL('${r['indexUrl']}')),
        ],
      );
    }
    var n = 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null) ...[VErrorBox(message: _error!), const SizedBox(height: 14.0)],
        VTextField(controller: _name, label: 'Production name', hint: 'Respondent\'s first production', onChanged: (_) => _dirty = true),
        const SizedBox(height: 16.0),
        Text(
          'Tick what to produce and set the order. Exhibit numbers and Bates labels follow this order, starting at ${widget.template.bates(widget.nextBates)}.',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 12.0),
        for (var i = 0; i < _items.length; i++)
          if (_r(_items[i].receiptId) != null) _row(context, i, _items[i].include ? ++n : 0),
        const SizedBox(height: 20.0),
        Row(children: [
          Expanded(child: VButton(label: _dirty ? 'Save draft' : 'Saved', kind: VButtonKind.secondary, fullWidth: true, loading: _saving, onPressed: _dirty ? _save : null)),
          const SizedBox(width: 12.0),
          Expanded(child: VButton(label: 'Produce', icon: Icons.gavel_outlined, fullWidth: true, loading: _producing, loadingLabel: 'Producing… (can take a minute)', onPressed: _produce)),
        ]),
      ],
    );
  }

  Widget _row(BuildContext context, int i, int number) {
    final c = VC.of(context);
    final it = _items[i];
    final r = _r(it.receiptId)!;
    final sugg = sensitiveOf(r).length;
    final applied = it.redactions.length + it.textRedactions.length;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.fromLTRB(6.0, 8.0, 12.0, 8.0),
      decoration: BoxDecoration(
        color: it.include ? c.card : c.secondary,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Checkbox(value: it.include, activeColor: c.teal, onChanged: (v) => setState(() {
                it.include = v == true;
                _dirty = true;
              })),
          SizedBox(
            width: 92.0,
            child: Text(it.include ? widget.template.exhibit(number) : 'Not produced', style: VT.body(context, size: 12.0, weight: FontWeight.w600, color: it.include ? c.tealDeep : c.mutedFg)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.headline, maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.body(context, size: 13.0, weight: FontWeight.w500)),
                Text(
                  [
                    r.kindLabel,
                    if (r.resolvedDate != null) 'dated ${fmtDay(r.resolvedDate)}',
                    'received ${fmtDay(r.receivedAt)}',
                  ].join(' · '),
                  style: VT.muted(context, size: 11.0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          if (it.include)
            VHover(
              onTap: () => _review(it),
              builder: (context, h) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: (it.reviewed ? c.verified : sugg > 0 ? c.pending : c.mutedFg).withValues(alpha: h ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(999.0),
                ),
                child: Text(
                  it.reviewed ? 'Reviewed · $applied redacted' : sugg > 0 ? '$sugg suggested · review' : 'Redact…',
                  style: VT.body(context, size: 11.0, weight: FontWeight.w500, color: it.reviewed ? c.verified : sugg > 0 ? c.pending : c.foreground),
                ),
              ),
            ),
          VIconButton(icon: Icons.arrow_upward, size: 14.0, tooltip: 'Move up', onPressed: i == 0 ? null : () => _move(i, -1)),
          VIconButton(icon: Icons.arrow_downward, size: 14.0, tooltip: 'Move down', onPressed: i == _items.length - 1 ? null : () => _move(i, 1)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- redaction review

class RedactionReview extends StatefulWidget {
  const RedactionReview({super.key, required this.receipt, required this.item});
  final ReceiptsRecord receipt;
  final ProdItem item;

  @override
  State<RedactionReview> createState() => _RedactionReviewState();
}

class _RedactionReviewState extends State<RedactionReview> {
  late final List<Map<String, dynamic>> _sugg = sensitiveOf(widget.receipt);
  final _add = TextEditingController();
  Offset? _dragStart;
  Rect? _drag;

  ReceiptsRecord get r => widget.receipt;
  ProdItem get it => widget.item;

  @override
  void dispose() {
    _add.dispose();
    super.dispose();
  }

  bool _boxOn(SourceBox b) => it.redactions.any((m) => (m.box.x - b.x).abs() < 0.002 && (m.box.y - b.y).abs() < 0.002 && (m.box.w - b.w).abs() < 0.002);

  void _toggleSuggestion(Map<String, dynamic> s) {
    final box = SourceBox.from(s['box']);
    final text = '${s['text'] ?? ''}'.trim();
    setState(() {
      if (_isImage(r) && box != null) {
        if (_boxOn(box)) {
          it.redactions.removeWhere((m) => (m.box.x - box.x).abs() < 0.002 && (m.box.y - box.y).abs() < 0.002);
        } else {
          it.redactions.add(RedactionMark(page: 0, box: box, reason: '${s['category']}', source: 'ai'));
        }
      } else if (text.isNotEmpty) {
        if (it.textRedactions.contains(text)) {
          it.textRedactions.remove(text);
        } else {
          it.textRedactions.add(text);
        }
      }
    });
  }

  bool _suggOn(Map<String, dynamic> s) {
    final box = SourceBox.from(s['box']);
    if (_isImage(r) && box != null) return _boxOn(box);
    return it.textRedactions.contains('${s['text'] ?? ''}'.trim());
  }

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final image = _isImage(r);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(r.headline, style: VT.body(context, weight: FontWeight.w600)),
        const SizedBox(height: 4.0),
        Text(
          image
              ? 'Black boxes are burned into the exhibit\'s pixels — nothing under them survives. Tap a suggestion to apply or remove it; drag on the image to add your own.'
              : 'Each selected text is removed from the exhibit wherever it appears (PDF pages with redactions are re-rendered as images so nothing survives underneath).',
          style: VT.muted(context, size: 13.0),
        ),
        const SizedBox(height: 16.0),
        if (image) _imageEditor(context),
        const SizedBox(height: 16.0),
        Text('SUGGESTED BY VERIN (${_sugg.length})', style: VT.eyebrow(context, color: c.mutedFg)),
        const SizedBox(height: 8.0),
        if (_sugg.isEmpty)
          Text('Nothing flagged. Court rules usually require redacting SSNs, account numbers, birth dates and children\'s names — check by eye.', style: VT.muted(context, size: 12.0)),
        for (final s in _sugg)
          CheckboxListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            activeColor: c.teal,
            value: _suggOn(s),
            onChanged: (_) => _toggleSuggestion(s),
            title: Text('${s['text']}', style: VT.mono(context, size: 12.0)),
            subtitle: Text(categoryLabel('${s['category']}'), style: VT.muted(context, size: 11.0)),
          ),
        if (!image) ...[
          const SizedBox(height: 12.0),
          Text('YOUR REDACTIONS', style: VT.eyebrow(context, color: c.mutedFg)),
          const SizedBox(height: 8.0),
          for (final t in it.textRedactions.where((t) => !_sugg.any((s) => '${s['text']}'.trim() == t)))
            Row(children: [
              Expanded(child: Text(t, style: VT.mono(context, size: 12.0))),
              VIconButton(icon: Icons.close, size: 14.0, tooltip: 'Remove', onPressed: () => setState(() => it.textRedactions.remove(t))),
            ]),
          Row(children: [
            Expanded(child: VTextField(controller: _add, hint: 'Exact text to redact, e.g. 4417 1234 5678 9113')),
            const SizedBox(width: 8.0),
            VButton(
              label: 'Add',
              size: VButtonSize.sm,
              onPressed: () {
                final t = _add.text.trim();
                if (t.length < 2) return;
                setState(() {
                  if (!it.textRedactions.contains(t)) it.textRedactions.add(t);
                  _add.clear();
                });
              },
            ),
          ]),
        ],
        const SizedBox(height: 20.0),
        VButton(
          label: 'Mark reviewed',
          icon: Icons.check,
          size: VButtonSize.lg,
          fullWidth: true,
          onPressed: () {
            it.reviewed = true;
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }

  Widget _imageEditor(BuildContext context) {
    final c = VC.of(context);
    final iw = r.snapshotData['imageWidth'];
    final ih = r.snapshotData['imageHeight'];
    final ratio = iw is num && ih is num && iw > 0 && ih > 0 ? ih.toDouble() / iw.toDouble() : 1.6;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth.clamp(200.0, 760.0);
      final h = w * ratio;
      Rect toRect(SourceBox b) => b.toRect(Size(w, h));
      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: GestureDetector(
            onPanStart: (d) => setState(() {
              _dragStart = d.localPosition;
              _drag = Rect.fromPoints(d.localPosition, d.localPosition);
            }),
            onPanUpdate: (d) => setState(() => _drag = Rect.fromPoints(_dragStart ?? d.localPosition, d.localPosition)),
            onPanEnd: (_) {
              final rect = _drag;
              setState(() {
                _drag = null;
                _dragStart = null;
                if (rect != null && rect.width > 6 && rect.height > 6) {
                  final cl = Rect.fromLTRB(rect.left.clamp(0.0, w), rect.top.clamp(0.0, h), rect.right.clamp(0.0, w), rect.bottom.clamp(0.0, h));
                  it.redactions.add(RedactionMark(page: 0, box: SourceBox(cl.left / w, cl.top / h, cl.width / w, cl.height / h), reason: 'other', source: 'manual'));
                }
              });
            },
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(r.sourceUrl, fit: BoxFit.fill, webHtmlElementStrategy: WebHtmlElementStrategy.fallback),
                ),
                for (final s in _sugg)
                  if (SourceBox.from(s['box']) != null && !_boxOn(SourceBox.from(s['box'])!))
                    Positioned.fromRect(
                      rect: toRect(SourceBox.from(s['box'])!).inflate(2),
                      child: GestureDetector(
                        onTap: () => _toggleSuggestion(s),
                        child: Container(decoration: BoxDecoration(border: Border.all(color: c.pending, width: 2.0), color: c.pending.withValues(alpha: 0.15))),
                      ),
                    ),
                for (final m in it.redactions)
                  Positioned.fromRect(
                    rect: toRect(m.box).inflate(2),
                    child: GestureDetector(
                      onTap: () => setState(() => it.redactions.remove(m)),
                      child: Tooltip(message: 'Tap to remove', child: Container(color: Colors.black.withValues(alpha: 0.85))),
                    ),
                  ),
                if (_drag != null) Positioned.fromRect(rect: _drag!, child: Container(decoration: BoxDecoration(border: Border.all(color: c.teal, width: 2.0), color: c.teal.withValues(alpha: 0.15)))),
              ],
            ),
          ),
        ),
      );
    });
  }
}
