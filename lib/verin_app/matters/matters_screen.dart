// Matters list — port of the Make's <MattersList>.

import 'package:flutter/material.dart';

import '../matter/hearings.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/badges.dart';
import '../widgets/motion.dart';
import 'new_matter_drawer.dart';
import '../onboarding/tour.dart';
import '../onboarding/tours.dart';
import '/auth/firebase_auth/auth_util.dart' show currentUserDocument;

const kMatterDetailRoute = 'MattersTabGroupHome';

void openMatter(BuildContext context, MattersRecord m, {bool admin = false, String? tab}) {
  context.pushNamed(
    kMatterDetailRoute,
    queryParameters: {
      'matterDoc': serializeParam(m, ParamType.Document),
      if (admin) 'from': 'admin',
      if (tab != null) 'tab': tab,
    }.withoutNulls,
    extra: <String, dynamic>{'matterDoc': m},
  );
}

/// The firm's receipts, grouped by matter path.
Stream<Map<String, List<ReceiptsRecord>>> receiptsByMatterStream() => queryReceiptsRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
    ).map((list) {
      final out = <String, List<ReceiptsRecord>>{};
      for (final r in list) {
        final m = r.matterId;
        if (m == null) continue;
        out.putIfAbsent(m.path, () => []).add(r);
      }
      return out;
    });

class MattersScreen extends StatefulWidget {
  const MattersScreen({super.key, this.admin = false});

  /// Shown inside the admin console (no New matter here in the Make, but we
  /// keep it available to admins).
  final bool admin;

  @override
  State<MattersScreen> createState() => _MattersScreenState();
}

class _MattersScreenState extends State<MattersScreen> {
  final _q = TextEditingController();
  late final Stream<List<MattersRecord>> _matters = firmMattersStream();
  late final Stream<Map<String, List<ReceiptsRecord>>> _receipts = receiptsByMatterStream();
  late final Stream<Map<String, dynamic>> _intg = integrationStatusStream();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  Future<void> _newMatter() async {
    final created = await showNewMatterDrawer(context);
    if (created != null && mounted) openMatter(context, created, admin: widget.admin);
  }

  @override
  Widget build(BuildContext context) => TourLauncher(
        tourId: 'matters',
        enabled: !widget.admin,
        beforeStart: sendToIntroIfNew,
        steps: mattersTour(admin: VUser.fromRecord(currentUserDocument).isAdmin),
        child: _page(context),
      );

  Widget _page(BuildContext context) {
    final c = VC.of(context);
    return StreamBuilder<List<MattersRecord>>(
      stream: _matters,
      builder: (context, snap) {
        final matters = snap.data ?? const <MattersRecord>[];
        return SingleChildScrollView(
          padding: vPagePadding(context, top: 36.0),
          child: Align(
  alignment: Alignment.topLeft,
  child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1000.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
  width: double.infinity,
  child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  runSpacing: 16.0,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Matters', style: VT.h1(context, size: 30.0)),
                          const SizedBox(height: 4.0),
                          Text(
                            '${pluralizeWord(matters.length, 'matter')} · records prepared at the direction of counsel',
                            style: VT.muted(context),
                          ),
                        ],
                      ),
                    ),
                    TourTarget(id: 'matters_new', child: VButton(label: 'New matter', icon: Icons.add, onPressed: _newMatter)),
                  ],
                ),
),
                const SizedBox(height: 28.0),
                UpcomingHearingsCard(matters: matters, onOpen: (m) => openMatter(context, m, admin: widget.admin)),
                TourTarget(
                  id: 'matters_search',
                  onDemoTour: () async {
                    await demoType(_q, 'Reyes', step: const Duration(milliseconds: 90));
                    if (mounted) setState(() {});
                  },
                  child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360.0),
                  child: TextField(
                    controller: _q,
                    onChanged: (_) => setState(() {}),
                    style: VT.body(context),
                    cursorColor: c.teal,
                    decoration: vInputDecoration(
                      context,
                      hint: 'Search matters or clients',
                      prefix: Icon(Icons.search, size: 16.0, color: c.mutedFg),
                    ).copyWith(fillColor: c.card),
                  ),
                ),
                ),
                const SizedBox(height: 16.0),
                if (snap.hasError)
                  VErrorBox(message: 'Matters could not be loaded: ${snap.error}')
                else if (!snap.hasData)
                  const VLoading()
                else
                  TourTarget(
                    id: 'matters_list',
                    child: StreamBuilder<Map<String, List<ReceiptsRecord>>>(
                    stream: _receipts,
                    builder: (context, rs) => StreamBuilder<Map<String, dynamic>>(
                      stream: _intg,
                      builder: (context, ig) => _MattersTable(
                        matters: matters,
                        query: _q.text,
                        receipts: rs.data ?? const {},
                        firmClio: ig.data?['clioConnected'] == true,
                        onOpen: (m) => openMatter(context, m, admin: widget.admin),
                        onNew: _newMatter,
                      ),
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
  }
}

String pluralizeWord(int n, String word) => '$n ${n == 1 ? word : '${word}s'}';

class _MattersTable extends StatelessWidget {
  const _MattersTable({
    required this.matters,
    required this.query,
    required this.receipts,
    required this.firmClio,
    required this.onOpen,
    required this.onNew,
  });

  final List<MattersRecord> matters;
  final String query;
  final Map<String, List<ReceiptsRecord>> receipts;
  final bool firmClio;
  final void Function(MattersRecord) onOpen;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final q = query.trim().toLowerCase();
    final rows = matters.where((m) => q.isEmpty || '${m.title} ${m.clientName} ${m.caseNumber}'.toLowerCase().contains(q)).toList();

    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 720.0;
      Widget header() => Container(
            color: c.secondary,
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(child: Text('MATTER', style: VT.eyebrow(context, color: c.mutedFg))),
                if (!compact) ...[
                  const SizedBox(width: 16.0),
                  SizedBox(width: 120.0, child: Text('ITEMS', style: VT.eyebrow(context, color: c.mutedFg))),
                  const SizedBox(width: 16.0),
                  SizedBox(width: 120.0, child: Text('INTEGRITY', style: VT.eyebrow(context, color: c.mutedFg))),
                  const SizedBox(width: 16.0),
                  SizedBox(width: 150.0, child: Text('PRACTICE MGMT', style: VT.eyebrow(context, color: c.mutedFg))),
                ],
                const SizedBox(width: 44.0),
              ],
            ),
          );

      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.card)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header(),
            for (final m in rows) _row(context, m, compact),
            if (rows.isEmpty)
              Container(
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.border))),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
                child: matters.isEmpty
                    ? Column(
                        children: [
                          VIconCircle(icon: Icons.folder_open_outlined, size: 52.0, iconSize: 22.0, bg: c.tealPale),
                          const SizedBox(height: 14.0),
                          Text('No matters yet', style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
                          const SizedBox(height: 6.0),
                          Text('Create a matter to start receiving evidence into its own record.', textAlign: TextAlign.center, style: VT.muted(context, size: 13.0)),
                          const SizedBox(height: 18.0),
                          VButton(label: 'Create your first matter', icon: Icons.add, kind: VButtonKind.tonal, size: VButtonSize.sm, onPressed: onNew),
                        ],
                      )
                    : Text('No matters match "$query"', textAlign: TextAlign.center, style: VT.muted(context)),
              ),
          ],
        ),
      );
    });
  }

  Widget _row(BuildContext context, MattersRecord m, bool compact) {
    final c = VC.of(context);
    final rs = (receipts[m.reference.path] ?? const <ReceiptsRecord>[]).where((r) => !r.isDuplicate).toList();
    final toReview = rs.where((r) {
      final s = itemStateOf(r);
      return s == VItemState.uncertain || s == VItemState.unreadable;
    }).length;
    final sub = [
      if (m.clientName.isNotEmpty) m.clientName,
      if (m.caseNumber.isNotEmpty) m.caseNumber,
      matterIsOpen(m) ? 'Open' : 'Closed',
    ].join(' · ');

    final items = Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '${rs.length}', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
          if (toReview > 0) TextSpan(text: ' · $toReview to review', style: VT.body(context, size: 11.0, color: c.pending)),
        ],
      ),
    );

    return VHover(
      onTap: () => onOpen(m),
      builder: (context, hovered) => Container(
        decoration: BoxDecoration(color: hovered ? c.secondary : c.background, border: Border(top: BorderSide(color: c.border))),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextHero(
                    tag: matterTitleTag(m.reference.path),
                    child: Text(m.title.isEmpty ? 'Untitled matter' : m.title, style: VT.serif(context, size: 15.0)),
                  ),
                  const SizedBox(height: 2.0),
                  Text(sub, style: VT.muted(context, size: 12.0)),
                  if (compact) ...[
                    const SizedBox(height: 8.0),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 6.0,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [items, ChainStatusInline(status: chainStatusOf(m)), ClioBadge(state: clioStateOf(m, firmConnected: firmClio))],
                    ),
                  ],
                ],
              ),
            ),
            if (!compact) ...[
              const SizedBox(width: 16.0),
              SizedBox(width: 120.0, child: items),
              const SizedBox(width: 16.0),
              SizedBox(width: 120.0, child: Align(alignment: Alignment.centerLeft, child: ChainStatusInline(status: chainStatusOf(m)))),
              const SizedBox(width: 16.0),
              SizedBox(width: 150.0, child: Align(alignment: Alignment.centerLeft, child: ClioBadge(state: clioStateOf(m, firmConnected: firmClio)))),
            ],
            const SizedBox(width: 16.0),
            SizedBox(width: 28.0, child: Icon(Icons.chevron_right, size: 18.0, color: c.mutedFg)),
          ],
        ),
      ),
    );
  }
}
