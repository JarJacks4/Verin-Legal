import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'hash_row_model.dart';
export 'hash_row_model.dart';

class HashRowWidget extends StatefulWidget {
  const HashRowWidget({
    super.key,
    String? hash,
    String? index,
  })  : this.hash = hash ??
            '5d8dd7378ced61bf0fe1e3f570094c80ac89d09ce99fab2eaac5636c78b49155',
        this.index = index ?? '1';

  final String hash;
  final String index;

  @override
  State<HashRowWidget> createState() => _HashRowWidgetState();
}

class _HashRowWidgetState extends State<HashRowWidget> {
  late HashRowModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HashRowModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.link_rounded,
          color: Color(0xFF0E6E7D),
          size: 16.0,
        ),
        Container(
          width: 24.0,
          child: Text(
            valueOrDefault<String>(
              '#${widget.index}',
              '#1',
            ),
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.spaceGrotesk(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryText,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  lineHeight: 1.2,
                ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            valueOrDefault<String>(
              widget.hash,
              '5d8dd7378ced61bf0fe1e3f570094c80ac89d09ce99fab2eaac5636c78b49155',
            ),
            maxLines: 1,
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.spaceGrotesk(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelSmall.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).labelSmall.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).labelSmall.fontStyle,
                  lineHeight: 1.2,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ].divide(SizedBox(width: 16.0)),
    );
  }
}
