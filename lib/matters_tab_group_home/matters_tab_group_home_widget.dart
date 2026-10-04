// Verin Legal — Matter Detail page (guide §3–§8).
//
// Originally exported from FlutterFlow; rewritten by hand so every value is
// bound to this matter's Firestore data. The five tab bodies live in
// lib/verin/matter/. Route name and path are unchanged, so existing
// navigation (Matters list, Admin Matters) keeps working.

import '/backend/backend.dart';
import '/components/side_nav_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/keep_alive_wrapper.dart';
import '/verin/matter/intake_tab.dart';
import '/verin/matter/integrity_tab.dart';
import '/verin/matter/matter_header.dart';
import '/verin/matter/practice_tab.dart';
import '/verin/matter/receipts_tab.dart';
import '/verin/matter/thread_tab.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'matters_tab_group_home_model.dart';
export 'matters_tab_group_home_model.dart';

class MattersTabGroupHomeWidget extends StatefulWidget {
  const MattersTabGroupHomeWidget({
    super.key,
    this.matterDoc,
  });

  final MattersRecord? matterDoc;

  static String routeName = 'MattersTabGroupHome';
  static String routePath = '/mattersTabGroupHome';

  @override
  State<MattersTabGroupHomeWidget> createState() =>
      _MattersTabGroupHomeWidgetState();
}

class _MattersTabGroupHomeWidgetState extends State<MattersTabGroupHomeWidget>
    with TickerProviderStateMixin {
  late MattersTabGroupHomeModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  Stream<MattersRecord>? _matterStream;
  Stream<List<ReceiptsRecord>>? _receiptsStream;
  String? _streamsFor;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MattersTabGroupHomeModel());
    _model.tabBarController = TabController(
      vsync: this,
      length: 5,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// Create the Firestore streams once per matter, not on every build.
  void _ensureStreams(DocumentReference ref) {
    if (_streamsFor == ref.path) return;
    _streamsFor = ref.path;
    _matterStream = MattersRecord.getDocument(ref);
    _receiptsStream = queryReceiptsRecord(
      queryBuilder: (q) => q.where('matterId', isEqualTo: ref).orderBy('receivedAt', descending: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFFDFCFA),
        body: SafeArea(
          top: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              wrapWithModel(
                model: _model.sideNavModel,
                updateCallback: () => safeSetState(() {}),
                child: SideNavWidget(),
              ),
              Expanded(child: _body(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final initial = widget.matterDoc;
    if (initial == null) {
      return VerinEmptyState(
        icon: Icons.folder_off_outlined,
        title: 'No matter selected',
        message: 'Open a matter from the Matters list.',
        action: VerinButton(
          label: 'Go to Matters',
          icon: Icons.arrow_back_rounded,
          onPressed: () => context.goNamed('MattersList'),
        ),
      );
    }
    _ensureStreams(initial.reference);

    return StreamBuilder<MattersRecord>(
      stream: _matterStream,
      initialData: initial,
      builder: (context, matterSnap) {
        final matter = matterSnap.data ?? initial;
        return StreamBuilder<List<ReceiptsRecord>>(
          stream: _receiptsStream,
          builder: (context, receiptsSnap) {
            final receipts = receiptsSnap.data ?? const <ReceiptsRecord>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MatterHeader(
                  matter: matter,
                  receipts: receipts,
                  onOpenThread: () => _model.tabBarController?.animateTo(2),
                ),
                _tabBar(context),
                Expanded(child: _tabs(context, matter, receiptsSnap)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _tabBar(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return Container(
      color: t.secondaryBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: _model.tabBarController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: t.secondary,
            unselectedLabelColor: t.secondaryText,
            indicatorColor: t.secondary,
            labelStyle: GoogleFonts.ibmPlexSans(fontSize: 13.5, fontWeight: FontWeight.w800),
            unselectedLabelStyle: GoogleFonts.ibmPlexSans(fontSize: 13.5, fontWeight: FontWeight.w500),
            tabs: const [
              Tab(text: 'Intake Channel'),
              Tab(text: 'Reciepts'),
              Tab(text: 'Thread'),
              Tab(text: 'Integrity'),
              Tab(text: 'Practice'),
            ],
          ),
          Container(height: 1.0, color: t.alternate),
        ],
      ),
    );
  }

  Widget _tabs(BuildContext context, MattersRecord matter, AsyncSnapshot<List<ReceiptsRecord>> receiptsSnap) {
    final t = FlutterFlowTheme.of(context);
    if (receiptsSnap.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'This matter\'s receipts could not be loaded: ${receiptsSnap.error}',
            style: VerinText.body(context, color: t.error),
          ),
        ),
      );
    }
    if (!receiptsSnap.hasData) return const VerinLoading();
    final receipts = receiptsSnap.data!;
    return Container(
      color: t.secondaryBackground,
      child: TabBarView(
        controller: _model.tabBarController,
        children: [
          KeepAliveWidgetWrapper(builder: (context) => IntakeTab(matter: matter, receipts: receipts)),
          KeepAliveWidgetWrapper(builder: (context) => ReceiptsTab(matter: matter, receipts: receipts)),
          KeepAliveWidgetWrapper(builder: (context) => ThreadTab(matter: matter, receipts: receipts)),
          KeepAliveWidgetWrapper(builder: (context) => IntegrityTab(matter: matter, receipts: receipts)),
          KeepAliveWidgetWrapper(builder: (context) => PracticeTab(matter: matter)),
        ],
      ),
    );
  }
}
