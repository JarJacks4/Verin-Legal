import '/backend/backend.dart';
import '/components/button_widget.dart';
import '/components/create_new_matter_bottom_sheet_widget.dart';
import '/components/filter_sort_matters_widget.dart';
import '/components/matter_row2_widget.dart';
import '/components/side_nav_admin_widget.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/verin/admin/admin_common.dart';
import '/verin/record_ext.dart';
import '/verin/verin_config.dart';
import '/verin/verin_format.dart';
import '/verin/verin_ui.dart';
import 'package:flutter/material.dart';
import 'admin_matters_list_model.dart';
export 'admin_matters_list_model.dart';

/// Admin Portal — Matters (guide §12b): every matter for the firm, with live
/// evidence counts per matter and firm-wide duplicate / chronology-shift
/// counts from Receipts.
class AdminMattersListWidget extends StatefulWidget {
  const AdminMattersListWidget({
    super.key,
    this.matterDoc,
  });

  /// Not used: the page loads the firm's matters itself. Kept so the route in
  /// nav.dart (which passes it through asyncParams) still compiles.
  final List<MattersRecord>? matterDoc;

  static String routeName = 'AdminMattersList';
  static String routePath = '/adminMattersList';

  @override
  State<AdminMattersListWidget> createState() => _AdminMattersListWidgetState();
}

class _AdminMattersListWidgetState extends State<AdminMattersListWidget> {
  late AdminMattersListModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  late final Stream<List<MattersRecord>> _mattersStream;
  late final Stream<List<ReceiptsRecord>> _receiptsStream;
  late final Stream<List<SyncStatusRecord>> _syncStream;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AdminMattersListModel());

    _model.textController ??= TextEditingController();
    _model.textFieldFocusNode ??= FocusNode();

    _mattersStream = queryMattersRecord(
      queryBuilder: (q) => q.where('firmID', isEqualTo: currentFirmId()),
    );
    _receiptsStream = queryReceiptsRecord();
    _syncStream = querySyncStatusRecord(singleRecord: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _openMatter(MattersRecord m) {
    context.pushNamed(
      MattersTabGroupHomeWidget.routeName,
      queryParameters: {
        'matterDoc': serializeParam(m, ParamType.Document),
      }.withoutNulls,
      extra: <String, dynamic>{
        'matterDoc': m,
      },
    );
  }

  Future<void> _openFilter(List<MattersRecord>? allMatters) async {
    if (allMatters == null) return;
    final value = await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: context,
      builder: (context) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: FilterSortMattersWidget(
              allMatters: allMatters,
            ),
          ),
        );
      },
    );
    if (value is List) {
      final list = value.whereType<MattersRecord>().toList();
      safeSetState(() {
        _model.filterSortResult = list;
        _model.filterIds = list.map((m) => m.reference.id).toList();
      });
    }
  }

  void _clearFilter() {
    safeSetState(() {
      _model.filterSortResult = null;
      _model.filterIds = null;
    });
  }

  Color _statusBg(BuildContext context, String status) {
    final s = status.trim().toLowerCase();
    if (s == 'open' || s == 'active' || s == 'verified') {
      return Color(0xFFDCFCE7);
    }
    if (s.isEmpty || s == 'closed' || s == 'archived') {
      return FlutterFlowTheme.of(context).alternate;
    }
    return FlutterFlowTheme.of(context).warning10;
  }

  Color _statusText(BuildContext context, String status) {
    final s = status.trim().toLowerCase();
    if (s == 'open' || s == 'active' || s == 'verified') {
      return Color(0xFF166534);
    }
    if (s.isEmpty || s == 'closed' || s == 'archived') {
      return FlutterFlowTheme.of(context).secondaryText;
    }
    return FlutterFlowTheme.of(context).warning;
  }

  TextStyle _labelSmall(BuildContext context, Color color) => adminText(
        FlutterFlowTheme.of(context).labelSmall,
        AdminFont.grotesk,
        color: color,
        lineHeight: 1.2,
      );

  Widget _chip(BuildContext context, IconData icon, Color color, String text,
      {bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: color,
          size: 16.0,
        ),
        Text(
          text,
          style: adminText(
            FlutterFlowTheme.of(context).bodySmall,
            AdminFont.plex,
            color: color,
            fontWeight: bold ? FontWeight.w600 : null,
            lineHeight: 1.5,
          ),
        ),
      ].divide(SizedBox(width: 4.0)),
    );
  }

  Widget _columnLabel(BuildContext context, String text, int flex,
      {TextAlign align = TextAlign.start}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: _labelSmall(context, FlutterFlowTheme.of(context).secondaryText),
      ),
    );
  }

  Widget _header(BuildContext context, List<MattersRecord>? allMatters) {
    final theme = FlutterFlowTheme.of(context);
    final filterActive = _model.filterIds != null;
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        shape: BoxShape.rectangle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(32.0, 24.0, 32.0, 24.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment:
                        (FFCrossAxisAlignment.start).flutterValue,
                    children: [
                      Text(
                        'Matters',
                        style: adminText(theme.bodyMedium, AdminFont.roboto,
                            color: theme.primaryText,
                            fontSize: 28.0,
                            fontWeight: FontWeight.bold,
                            lineHeight: 1.5),
                      ),
                      Text(
                        'Active evidentiary workspaces for your firm',
                        style: adminText(theme.bodySmall, AdminFont.plex,
                            color: theme.secondaryText,
                            fontSize: 14.0,
                            lineHeight: 1.5),
                      ),
                    ].divide(SizedBox(height: 4.0)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 320.0,
                      child: TextFormField(
                        controller: _model.textController,
                        focusNode: _model.textFieldFocusNode,
                        onChanged: (value) =>
                            safeSetState(() => _model.searchText = value),
                        autofocus: false,
                        enabled: true,
                        obscureText: false,
                        decoration: InputDecoration(
                          isDense: true,
                          labelStyle: adminText(
                              theme.labelMedium, AdminFont.plex,
                              color: theme.tertiary, fontSize: 18.0),
                          alignLabelWithHint: true,
                          hintText: 'Search by case, client or number...',
                          hintStyle:
                              adminText(theme.labelMedium, AdminFont.plex),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: theme.secondaryText,
                            size: 20.0,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Color(0x281A2B3C),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.secondary,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.error,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          filled: true,
                          fillColor: theme.secondaryBackground,
                        ),
                        style: adminText(theme.bodyMedium, AdminFont.plex),
                        cursorColor: theme.primaryText,
                        enableInteractiveSelection: true,
                        validator:
                            _model.textControllerValidator.asValidator(context),
                      ),
                    ),
                    Tooltip(
                      message: 'Filter & sort',
                      child: FlutterFlowIconButton(
                        borderRadius: 8.0,
                        buttonSize: 40.0,
                        fillColor:
                            filterActive ? theme.secondary10 : Colors.transparent,
                        icon: Icon(
                          Icons.filter_list,
                          color: filterActive ? theme.secondary : theme.tertiary,
                          size: 24.0,
                        ),
                        onPressed: () async {
                          await _openFilter(allMatters);
                        },
                      ),
                    ),
                    if (filterActive)
                      VerinButton(
                        label: 'Clear filter',
                        icon: Icons.close_rounded,
                        variant: VerinButtonVariant.ghost,
                        size: VerinButtonSize.small,
                        onPressed: _clearFilter,
                      ),
                    InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        await showModalBottomSheet(
                          isScrollControlled: true,
                          backgroundColor: Color(0x132D5A5E),
                          context: context,
                          builder: (context) {
                            return GestureDetector(
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                              child: Padding(
                                padding: MediaQuery.viewInsetsOf(context),
                                child: CreateNewMatterBottomSheetWidget(),
                              ),
                            );
                          },
                        ).then((value) => safeSetState(() {}));
                      },
                      child: wrapWithModel(
                        model: _model.buttonModel,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonWidget(
                          icon: Icon(
                            Icons.add_rounded,
                            color: theme.primaryText,
                            size: 24.0,
                          ),
                          iconPresent: true,
                          iconEndPresent: false,
                          content: 'New Matter',
                          variant: 'primary',
                          size: 'medium',
                          fullWidth: false,
                          loading: false,
                          disabled: false,
                        ),
                      ),
                    ),
                  ].divide(SizedBox(width: 16.0)),
                ),
              ],
            ),
          ),
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: theme.alternate,
              shape: BoxShape.rectangle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _syncBar(
    BuildContext context, {
    required bool loading,
    required List<ReceiptsRecord> firmReceipts,
    required SyncStatusRecord? sync,
  }) {
    final theme = FlutterFlowTheme.of(context);

    String lastSyncText;
    final syncedAt = sync?.lastSyncAt;
    if (syncedAt != null) {
      lastSyncText = 'Last sync: ${fmtRelative(syncedAt)}';
    } else {
      DateTime? newest;
      for (final r in firmReceipts) {
        final d = r.receivedAt;
        if (d != null && (newest == null || d.isAfter(newest))) newest = d;
      }
      lastSyncText = newest == null
          ? 'Last item received: $kDash'
          : 'Last item received: ${fmtRelative(newest)}';
    }

    final weekAgo = DateTime.now().subtract(Duration(days: 7));
    final newCount = firmReceipts.where((r) {
      final d = r.receivedAt;
      return d != null && d.isAfter(weekAgo);
    }).length;
    final dupCount = firmReceipts.where((r) => r.isDuplicate).length;
    final shiftCount = firmReceipts.where((r) => r.hasChronologyShift).length;

    String n(int v) => loading ? kDash : v.toString();

    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        shape: BoxShape.rectangle,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(24.0, 16.0, 24.0, 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sync_rounded,
                          color: theme.secondary,
                          size: 18.0,
                        ),
                        Text(
                          'CONTINUOUS UPDATES',
                          style: _labelSmall(context, theme.secondaryText),
                        ),
                      ].divide(SizedBox(width: 8.0)),
                    ),
                    Text(
                      loading ? 'Last sync: $kDash' : lastSyncText,
                      style: _labelSmall(context, theme.accent3),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 24.0,
                  runSpacing: 8.0,
                  children: [
                    Tooltip(
                      message: 'Items received in the last 7 days',
                      child: _chip(context, Icons.auto_awesome_rounded,
                          theme.success, '${n(newCount)} New items this week',
                          bold: true),
                    ),
                    _chip(context, Icons.copy_all_rounded, theme.secondaryText,
                        '${n(dupCount)} Duplicates filtered'),
                    _chip(context, Icons.history_rounded, theme.onSurface,
                        '${n(shiftCount)} Chronology shifts'),
                  ],
                ),
              ].divide(SizedBox(height: 16.0)),
            ),
          ),
          Container(
            height: 1.0,
            decoration: BoxDecoration(
              color: theme.alternate,
              shape: BoxShape.rectangle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(
    BuildContext context, {
    required List<MattersRecord>? allMatters,
    required List<MattersRecord> visible,
    required Map<String, int>? itemCounts,
  }) {
    if (allMatters == null) return const VerinLoading();
    if (allMatters.isEmpty) {
      return Center(
        child: VerinEmptyState(
          icon: Icons.folder_open_rounded,
          title: 'No matters yet',
          message: 'Matters your firm opens will appear here.',
        ),
      );
    }
    if (visible.isEmpty) {
      return Center(
        child: VerinEmptyState(
          icon: Icons.search_off_rounded,
          title: 'No matters match',
          message: _model.filterIds != null
              ? 'Try a different search, or clear the filter.'
              : 'Try a different search.',
          action: _model.filterIds != null
              ? VerinButton(
                  label: 'Clear filter',
                  icon: Icons.close_rounded,
                  size: VerinButtonSize.small,
                  onPressed: _clearFilter,
                )
              : null,
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      scrollDirection: Axis.vertical,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final m = visible[index];
        final counts = itemCounts;
        return InkWell(
          splashColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () => _openMatter(m),
          child: MatterRow2Widget(
            key: ValueKey('admin_matter_${m.reference.id}'),
            name: orDash(m.title),
            caseNo: orDash(m.caseNumber),
            client: orDash(m.clientName),
            status: orDash(m.status),
            items: counts == null
                ? kDash
                : (counts[m.reference.path] ?? 0).toString(),
            statusBg: _statusBg(context, m.status),
            statusText: _statusText(context, m.status),
            onTap: () => _openMatter(m),
          ),
        );
      },
    );
  }

  Widget _content(
    BuildContext context,
    List<MattersRecord>? allMatters,
    List<ReceiptsRecord>? receipts,
    SyncStatusRecord? sync,
  ) {
    final theme = FlutterFlowTheme.of(context);
    final matters = allMatters ?? const <MattersRecord>[];

    // Receipts for this firm's matters, and item counts per matter.
    final matterPaths = matters.map((m) => m.reference.path).toSet();
    final firmReceipts = <ReceiptsRecord>[];
    final counts = <String, int>{};
    for (final r in receipts ?? const <ReceiptsRecord>[]) {
      final path = r.matterId?.path;
      if (path == null || !matterPaths.contains(path)) continue;
      firmReceipts.add(r);
      counts[path] = (counts[path] ?? 0) + 1;
    }

    // Filter & Sort result (ids in the sheet's order), then search.
    List<MattersRecord> visible;
    final ids = _model.filterIds;
    if (ids != null) {
      final byId = <String, MattersRecord>{
        for (final m in matters) m.reference.id: m,
      };
      visible = ids.map((id) => byId[id]).whereType<MattersRecord>().toList();
    } else {
      visible = [...matters]..sort((a, b) {
          final ad = a.openedAt;
          final bd = b.openedAt;
          if (ad == null && bd == null) {
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          }
          if (ad == null) return 1;
          if (bd == null) return -1;
          return bd.compareTo(ad);
        });
    }
    final q = _model.searchText.trim().toLowerCase();
    if (q.isNotEmpty) {
      visible = visible
          .where((m) =>
              m.title.toLowerCase().contains(q) ||
              m.clientName.toLowerCase().contains(q) ||
              m.caseNumber.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, allMatters),
        _syncBar(
          context,
          loading: allMatters == null || receipts == null,
          firmReceipts: firmReceipts,
          sync: sync,
        ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              shape: BoxShape.rectangle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _columnLabel(context, 'CASE NAME', 3),
                      _columnLabel(context, 'CLIENT', 2),
                      _columnLabel(context, 'STATUS', 2),
                      _columnLabel(context, 'ITEMS', 1, align: TextAlign.end),
                      Container(
                        width: 40.0,
                      ),
                    ].divide(SizedBox(width: 16.0)),
                  ),
                ),
                Container(
                  height: 1.0,
                  color: theme.alternate,
                ),
                Expanded(
                  child: _list(
                    context,
                    allMatters: allMatters,
                    visible: visible,
                    itemCounts: receipts == null ? null : counts,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        body: AdminAccessGate(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: AlignmentDirectional(-1.0, -1.0),
                child: Container(
                  width: 284.0,
                  height: MediaQuery.sizeOf(context).height * 1.0,
                  decoration: BoxDecoration(
                    color: Color(0xFF093F49),
                    shape: BoxShape.rectangle,
                  ),
                  child: wrapWithModel(
                    model: _model.sideNavAdminModel,
                    updateCallback: () => safeSetState(() {}),
                    child: SideNavAdminWidget(
                      activePage: AdminMattersListWidget.routeName,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: StreamBuilder<List<MattersRecord>>(
                  stream: _mattersStream,
                  builder: (context, mattersSnapshot) {
                    return StreamBuilder<List<ReceiptsRecord>>(
                      stream: _receiptsStream,
                      builder: (context, receiptsSnapshot) {
                        return StreamBuilder<List<SyncStatusRecord>>(
                          stream: _syncStream,
                          builder: (context, syncSnapshot) {
                            final syncList = syncSnapshot.data;
                            final sync = (syncList == null || syncList.isEmpty)
                                ? null
                                : syncList.first;
                            return _content(
                              context,
                              mattersSnapshot.data,
                              receiptsSnapshot.data,
                              sync,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
