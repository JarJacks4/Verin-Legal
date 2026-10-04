import '/backend/backend.dart';
import '/components/confirm_approve_reject_widget.dart';
import '/components/review_item_widget.dart';
import '/components/side_nav_widget.dart';
import '/components/text_field_widget.dart';
import '/flutter_flow/flutter_flow_charts.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart' as actions;
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'review_queue_model.dart';
export 'review_queue_model.dart';

class ReviewQueueWidget extends StatefulWidget {
  const ReviewQueueWidget({super.key});

  static String routeName = 'ReviewQueue';
  static String routePath = '/reviewQueue';

  @override
  State<ReviewQueueWidget> createState() => _ReviewQueueWidgetState();
}

class _ReviewQueueWidgetState extends State<ReviewQueueWidget> {
  late ReviewQueueModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  /// Item states that need a human decision (besides isQuarantined == true).
  static const List<String> _kReviewStates = [
    'Uncertain',
    'uncertain',
    'Unreadable',
    'unreadable',
    'pending_review',
    'Pending Review',
    'extraction_failed',
  ];

  /// Queue filter menu: value -> label.
  static const Map<String, String> _kQueueFilters = {
    'all': 'All items',
    'quarantined': 'Quarantined',
    'uncertain': 'Uncertain',
    'unreadable': 'Unreadable',
    'extraction_failed': 'Extraction failed',
  };

  StreamSubscription<List<ItemsRecord>>? _quarantinedSub;
  StreamSubscription<List<ItemsRecord>>? _pendingSub;
  List<ItemsRecord>? _quarantined;
  List<ItemsRecord>? _pending;
  String? _queueError;
  String? _statsError;
  String _queueFilter = 'all';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ReviewQueueModel());

    // The queue is live: quarantined items plus items whose state needs
    // review. Two single-field queries (no composite index), merged here.
    _quarantinedSub = _itemsStream(
      (q) => q.where('isQuarantined', isEqualTo: true),
    ).listen(
      (items) {
        _quarantined = items;
        _mergeQueue();
      },
      onError: (e) {
        _quarantined ??= [];
        _queueError = '$e';
        _mergeQueue();
      },
    );
    _pendingSub = _itemsStream(
      (q) => q.where('state', whereIn: _kReviewStates),
    ).listen(
      (items) {
        _pending = items;
        _mergeQueue();
      },
      onError: (e) {
        _pending ??= [];
        _queueError = '$e';
        _mergeQueue();
      },
    );

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.textFieldModel.inputTextController
          ?.addListener(_onSearchChanged);
      await _loadStats();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _quarantinedSub?.cancel();
    _pendingSub?.cancel();
    _model.dispose();

    super.dispose();
  }

  Stream<List<ItemsRecord>> _itemsStream(Query Function(Query) build) =>
      build(ItemsRecord.collection).limit(200).snapshots().map((s) => s.docs
          .map((d) {
            try {
              return ItemsRecord.fromSnapshot(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<ItemsRecord>()
          .toList());

  void _mergeQueue() {
    if (_quarantined == null && _pending == null) return;
    final byPath = <String, ItemsRecord>{};
    for (final item in [...?_quarantined, ...?_pending]) {
      byPath[item.reference.path] = item;
    }
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    _model.queueItems = byPath.values.toList()
      ..sort((a, b) =>
          (b.recievedAt ?? epoch).compareTo(a.recievedAt ?? epoch));
    safeSetState(() {});
  }

  void _onSearchChanged() => safeSetState(() {});

  /// Today's auto-resolved count, time saved and the 7-day volume chart.
  Future<void> _loadStats() async {
    try {
      _model.startOffToday = await actions.daysAgoStart(
        0,
      );
      _model.autoResolvedTodayCount = await queryItemsRecordCount(
        queryBuilder: (itemsRecord) => itemsRecord
            .where(
              'state',
              isEqualTo: 'Processed',
            )
            .where(
              'recievedAt',
              isGreaterThanOrEqualTo: _model.startOffToday,
            ),
      );
      _model.hoursSaved = await actions.estimateTimeSaved(
        _model.autoResolvedTodayCount ?? 0,
      );
      // Today plus the six days before it.
      _model.startofWeek = await actions.daysAgoStart(
        6,
      );
      _model.weeklyProcessedItems = await queryItemsRecordOnce(
        queryBuilder: (itemsRecord) => itemsRecord
            .where(
              'state',
              isEqualTo: 'Processed',
            )
            .where(
              'recievedAt',
              isGreaterThanOrEqualTo: _model.startofWeek,
            ),
      );
      _model.weeklyVolume = await actions.bucketByWeekday(
        _model.weeklyProcessedItems ?? [],
      );
      _statsError = null;
    } catch (e) {
      _model.weeklyProcessedItems ??= [];
      _statsError = '$e';
    }
    safeSetState(() {});
  }

  /// bucketByWeekday output: [{'day': 'M', 'count': 3}, ...].
  List<Map<String, dynamic>> get _weekBuckets {
    final v = _model.weeklyVolume;
    if (v is! List) return const [];
    return v
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  String get _searchText =>
      (_model.textFieldModel.inputTextController?.text ?? '').trim();

  /// Queue narrowed by the filter menu and the search box.
  List<ItemsRecord> _visibleQueue() {
    final all = _model.queueItems ?? const <ItemsRecord>[];
    final q = _searchText.toLowerCase();
    return all.where((i) {
      if (_queueFilter == 'quarantined' && !i.isQuarantined) return false;
      if (_queueFilter != 'all' &&
          _queueFilter != 'quarantined' &&
          i.state.trim().toLowerCase() != _queueFilter) {
        return false;
      }
      if (q.isEmpty) return true;
      return [
        i.matterName,
        i.clientName,
        i.senderRaw,
        i.channel,
        i.kind,
        i.state,
        i.classificationLabel,
        i.batesId,
      ].any((f) => f.toLowerCase().contains(q));
    }).toList();
  }

  /// Why an item is in the queue, for its badge.
  String _issueLabel(ItemsRecord i) {
    if (i.isQuarantined) return 'Quarantined';
    final raw = i.state.trim().isNotEmpty
        ? i.state.trim()
        : i.classificationLabel.trim();
    if (raw.isEmpty) return '';
    final words = raw.replaceAll('_', ' ');
    return '${words[0].toUpperCase()}${words.substring(1)}';
  }

  (Color, Color) _issueColors(ItemsRecord i) {
    if (i.isQuarantined) {
      return (const Color(0xFFFEE2E2), const Color(0xFF991B1B));
    }
    final st = i.state.trim().toLowerCase();
    if (st == 'unreadable' || st == 'extraction_failed') {
      return (const Color(0xFFFFEDD5), const Color(0xFF9A3412));
    }
    return (const Color(0xFFFEF3C7), const Color(0xFF92400E));
  }

  Future<void> _openResolve(ItemsRecord item) async {
    // The confirmation card is centred, so it is shown as a dialog: taps
    // outside the card reach the barrier and dismiss it.
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return Material(
          type: MaterialType.transparency,
          child: ConfirmApproveRejectWidget(
            sender:
                item.senderRaw.isNotEmpty ? item.senderRaw : item.clientName,
            channel: item.channel,
            timestamp: fmtDateTime(item.recievedAt),
            itemDoc: item.reference,
            currentState: _issueLabel(item),
          ),
        );
      },
    );
    if (!mounted || result == null) return;
    showVerinSnack(
      context,
      result == 'approved' ? 'Item approved.' : 'Item rejected.',
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
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 260.0,
              decoration: BoxDecoration(
                color: Color(0xFF0F172A),
                shape: BoxShape.rectangle,
              ),
              child: wrapWithModel(
                model: _model.sideNavModel,
                updateCallback: () => safeSetState(() {}),
                child: SideNavWidget(),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(),
                child: SingleChildScrollView(
                  primary: false,
                  controller: _model.columnScrollController,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                          shape: BoxShape.rectangle,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  40.0, 24.0, 40.0, 24.0),
                              child: Container(
                                child: Row(
                                  mainAxisSize: MainAxisSize.max,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Review Queue',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.roboto(
                                                  fontWeight: FontWeight.bold,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                fontSize: 32.0,
                                                letterSpacing: 0.0,
                                                fontWeight: FontWeight.bold,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.5,
                                              ),
                                        ),
                                        Text(
                                          'Items requiring manual resolution across all active matters',
                                          style: FlutterFlowTheme.of(context)
                                              .bodyMedium
                                              .override(
                                                font: GoogleFonts.ibmPlexSans(
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .fontStyle,
                                                ),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondaryText,
                                                letterSpacing: 0.0,
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .fontStyle,
                                                lineHeight: 1.5,
                                              ),
                                        ),
                                      ].divide(SizedBox(height: 4.0)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.max,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 300.0,
                                          child: wrapWithModel(
                                            model: _model.textFieldModel,
                                            updateCallback: () =>
                                                safeSetState(() {}),
                                            child: TextFieldWidget(
                                              label: '',
                                              labelPresent: false,
                                              helper: '',
                                              helperPresent: false,
                                              leadingIcon: Icon(
                                                Icons.search_rounded,
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryText,
                                                size: 24.0,
                                              ),
                                              leadingIconPresent: true,
                                              trailingIconPresent: false,
                                              hint: 'Search items...',
                                              value: '',
                                              onChange: '',
                                              onSubmit: '',
                                              variant: 'outlined',
                                              error: false,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          tooltip: 'Filter queue',
                                          initialValue: _queueFilter,
                                          onSelected: (value) => safeSetState(
                                              () => _queueFilter = value),
                                          itemBuilder: (context) => [
                                            for (final entry
                                                in _kQueueFilters.entries)
                                              PopupMenuItem<String>(
                                                value: entry.key,
                                                child: Text(
                                                  entry.value,
                                                  style: VerinText.body(
                                                      context),
                                                ),
                                              ),
                                          ],
                                          child: Container(
                                            width: 40.0,
                                            height: 40.0,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                              borderRadius:
                                                  BorderRadius.circular(6.0),
                                            ),
                                            alignment:
                                                AlignmentDirectional(0.0, 0.0),
                                            child: Icon(
                                              Icons.filter_list_rounded,
                                              color: _queueFilter == 'all'
                                                  ? FlutterFlowTheme.of(context)
                                                      .primaryText
                                                  : FlutterFlowTheme.of(context)
                                                      .secondary,
                                              size: 24.0,
                                            ),
                                          ),
                                        ),
                                      ].divide(SizedBox(width: 16.0)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Container(
                              height: 1.0,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context).alternate,
                                shape: BoxShape.rectangle,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Pending Review',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                        lineHeight: 1.2,
                                                      ),
                                            ),
                                            Text(
                                              _model.queueItems == null
                                                  ? '—'
                                                  : pluralize(
                                                      _model.queueItems!.length,
                                                      'Item'),
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .headlineSmall
                                                  .override(
                                                    font: GoogleFonts.spectral(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryText,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineSmall
                                                            .fontStyle,
                                                    lineHeight: 1.3,
                                                  ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Auto-Resolved (Today)',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                        lineHeight: 1.2,
                                                      ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  _model.autoResolvedTodayCount
                                                          ?.toString() ??
                                                      '—',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .headlineSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .spectral(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .headlineSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .success,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .headlineSmall
                                                                .fontStyle,
                                                        lineHeight: 1.3,
                                                      ),
                                                ),
                                                if ((_model.autoResolvedTodayCount ??
                                                        0) >
                                                    0)
                                                Icon(
                                                  Icons.arrow_upward_rounded,
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .success,
                                                  size: 16.0,
                                                ),
                                              ].divide(SizedBox(width: 4.0)),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryBackground,
                                      borderRadius: BorderRadius.circular(8.0),
                                      shape: BoxShape.rectangle,
                                      border: Border.all(
                                        color: FlutterFlowTheme.of(context)
                                            .alternate,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(24.0),
                                      child: Container(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Est. Paralegal Time Saved',
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .labelSmall
                                                      .override(
                                                        font: GoogleFonts
                                                            .spaceGrotesk(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .labelSmall
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .secondaryText,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelSmall
                                                                .fontStyle,
                                                        lineHeight: 1.2,
                                                      ),
                                            ),
                                            Text(
                                              _model.hoursSaved == null
                                                  ? '—'
                                                  : '${_model.hoursSaved!.toStringAsFixed(1)} hrs',
                                              style: FlutterFlowTheme.of(
                                                      context)
                                                  .headlineSmall
                                                  .override(
                                                    font: GoogleFonts.spectral(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .headlineSmall
                                                              .fontStyle,
                                                    ),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .secondary,
                                                    letterSpacing: 0.0,
                                                    fontWeight: FontWeight.w600,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .headlineSmall
                                                            .fontStyle,
                                                    lineHeight: 1.3,
                                                  ),
                                            ),
                                          ].divide(SizedBox(height: 4.0)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ].divide(SizedBox(width: 24.0)),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                borderRadius: BorderRadius.circular(8.0),
                                shape: BoxShape.rectangle,
                                border: Border.all(
                                  color: FlutterFlowTheme.of(context).alternate,
                                  width: 1.0,
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Container(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Processing Volume & Efficiency',
                                            style: FlutterFlowTheme.of(context)
                                                .titleMedium
                                                .override(
                                                  font: GoogleFonts.ibmPlexSans(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMedium
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .titleMedium
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .primaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .titleMedium
                                                          .fontStyle,
                                                  lineHeight: 1.4,
                                                ),
                                          ),
                                          Text(
                                            'Last 7 Days',
                                            style: FlutterFlowTheme.of(context)
                                                .labelSmall
                                                .override(
                                                  font:
                                                      GoogleFonts.spaceGrotesk(
                                                    fontWeight:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontWeight,
                                                    fontStyle:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .labelSmall
                                                            .fontStyle,
                                                  ),
                                                  color: FlutterFlowTheme.of(
                                                          context)
                                                      .secondaryText,
                                                  letterSpacing: 0.0,
                                                  fontWeight:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontWeight,
                                                  fontStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .labelSmall
                                                          .fontStyle,
                                                  lineHeight: 1.2,
                                                ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        height: 190.45,
                                        child: _weekBuckets.isEmpty
                                            ? Center(
                                                child: _statsError != null
                                                    ? Text(
                                                        'Processing stats are unavailable right now.',
                                                        style: VerinText.small(
                                                            context),
                                                      )
                                                    : VerinLoading(),
                                              )
                                            : Container(
                                          height: 151.07,
                                          child: Stack(
                                            children: [
                                              FlutterFlowBarChart(
                                                barData: [
                                                  FFBarChartData(
                                                    yData: _weekBuckets
                                                        .map((b) =>
                                                            b['count'] is num
                                                                ? b['count']
                                                                : 0)
                                                        .toList(),
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .tertiary,
                                                    borderColor:
                                                        Color(0x2CE2E0DB),
                                                  )
                                                ],
                                                xLabels: _weekBuckets
                                                    .map((b) =>
                                                        '${b['day'] ?? ''}')
                                                    .toList(),
                                                barWidth: 60.0,
                                                barBorderRadius:
                                                    BorderRadius.circular(4.0),
                                                groupSpace: 7.0,
                                                alignment: BarChartAlignment
                                                    .spaceEvenly,
                                                chartStylingInfo:
                                                    ChartStylingInfo(
                                                  enableTooltip: true,
                                                  tooltipBackgroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .secondary,
                                                  backgroundColor:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .primaryBackground,
                                                  showGrid: true,
                                                  borderColor:
                                                      Color(0x2BF9F8F6),
                                                ),
                                                axisBounds: AxisBounds(
                                                  minY: 0.0,
                                                  maxX: 6.0,
                                                  maxY: math.max(
                                                    4.0,
                                                    _weekBuckets.fold<double>(
                                                            0.0,
                                                            (m, b) => math.max(
                                                                m,
                                                                b['count'] is num
                                                                    ? (b['count']
                                                                            as num)
                                                                        .toDouble()
                                                                    : 0.0)) *
                                                        1.25,
                                                  ),
                                                ),
                                                xAxisLabelInfo: AxisLabelInfo(
                                                  showLabels: true,
                                                  labelTextStyle:
                                                      FlutterFlowTheme.of(
                                                              context)
                                                          .bodySmall
                                                          .override(
                                                            font: GoogleFonts
                                                                .ibmPlexSans(
                                                              fontWeight:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontWeight,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodySmall
                                                                      .fontStyle,
                                                            ),
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .secondaryText,
                                                            fontSize: 10.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodySmall
                                                                    .fontStyle,
                                                            lineHeight: 1.0,
                                                          ),
                                                  reservedSize: 20.0,
                                                ),
                                                yAxisLabelInfo: AxisLabelInfo(
                                                  reservedSize: 0.0,
                                                ),
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 0.0),
                                                child:
                                                    FlutterFlowChartLegendWidget(
                                                  entries: [
                                                    LegendEntry(
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .tertiary,
                                                        'Items auto-processed per day'),
                                                  ],
                                                  textStyle: TextStyle(),
                                                  indicatorSize: 5.0,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ].divide(SizedBox(height: 16.0)),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Priority Items',
                                  style: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .override(
                                        font: GoogleFonts.ibmPlexSans(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleMedium
                                                  .fontStyle,
                                        ),
                                        color: FlutterFlowTheme.of(context)
                                            .primaryText,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleMedium
                                            .fontStyle,
                                        lineHeight: 1.4,
                                      ),
                                ),
                                Builder(
                                  builder: (context) {
                                    if (_model.queueItems == null) {
                                      return VerinLoading();
                                    }
                                    final items = _visibleQueue();
                                    if (items.isEmpty) {
                                      final narrowed = _searchText.isNotEmpty ||
                                          _queueFilter != 'all';
                                      return VerinCard(
                                        padding: EdgeInsets.zero,
                                        child: VerinEmptyState(
                                          icon: narrowed
                                              ? Icons.search_off_rounded
                                              : Icons.inbox_rounded,
                                          title: narrowed
                                              ? 'No items match'
                                              : 'Nothing waiting for review',
                                          message: _queueError != null
                                              ? 'Part of the queue could not be loaded. $_queueError'
                                              : narrowed
                                                  ? 'Try a different search or filter.'
                                                  : 'Quarantined and uncertain items will appear here.',
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      padding: EdgeInsets.zero,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      scrollDirection: Axis.vertical,
                                      itemCount: items.length,
                                      itemBuilder: (context, itemsIndex) {
                                        final itemsItem = items[itemsIndex];
                                        final (issueBg, issueFg) =
                                            _issueColors(itemsItem);
                                        return Padding(
                                          key: ValueKey(
                                              itemsItem.reference.path),
                                          padding: EdgeInsetsDirectional
                                              .fromSTEB(0.0, 0.0, 0.0, 12.0),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: ReviewItemWidget(
                                              key: Key(
                                                  'Keyawb_${itemsItem.reference.id}'),
                                              client: itemsItem.clientName,
                                              date: fmtDateTime(
                                                  itemsItem.recievedAt),
                                              issue: _issueLabel(itemsItem),
                                              issueBg: issueBg,
                                              issueText: issueFg,
                                              matter: itemsItem.matterName,
                                              type: itemsItem.kind,
                                              channel: itemsItem.channel,
                                              onResolve: () =>
                                                  _openResolve(itemsItem),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ].divide(SizedBox(height: 16.0)),
                            ),
                          ].divide(SizedBox(height: 24.0)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
