// Video redaction — the editor from the Figma Make design.
//
// A redaction is a fixed rectangle over a time range. It does not follow a
// moving subject, and the screen says so in as many places as it takes,
// because a firm that believes a face was tracked will produce a video that
// shows the face.
//
// Producing burns solid black rectangles into the pixels and silences the
// muted spans, then saves a new file with its own fingerprint. The original
// is never altered: it keeps its hash and its place in the chain.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/verin/record_ext.dart';
import '/verin/verin_api.dart';

import '../data/format.dart';
import '../data/model.dart';
import '../matter/exhibits_tab.dart' show sensitiveOf, categoryLabel;
import '../onboarding/tour.dart';
import '../onboarding/tours.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';
import '../widgets/motion.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

const kRedactionReasons = <String, String>{
  'child': "Child's name",
  'account': 'Account number',
  'face': 'Face',
  'address': 'Address',
  'other': 'Other',
};

/// A rectangle over a span, in percentages of the frame and seconds.
class VideoBox {
  VideoBox({
    required this.id,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.start,
    required this.end,
    this.reason = 'face',
  });

  final String id;
  double x, y, w, h, start, end;
  String reason;

  Map<String, dynamic> toMap() => {
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'start': start,
        'end': end,
        'reason': reason,
      };
}

class MuteSpan {
  MuteSpan({required this.id, required this.start, required this.end});

  final String id;
  double start, end;

  Map<String, dynamic> toMap() => {'start': start, 'end': end};
}

String mmss(double s) {
  final v = s.isFinite && s > 0 ? s : 0.0;
  final m = (v ~/ 60).toString();
  final sec = (v % 60).floor().toString().padLeft(2, '0');
  return '$m:$sec';
}

String spanLabel(double a, double b, double duration) =>
    (a <= 0 && b >= duration) ? 'Whole clip' : '${mmss(a)}–${mmss(b)}';

double _clamp(double n, double lo, double hi) => math.min(hi, math.max(lo, n));

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

/// Opens the editor for one video item.
Future<void> showVideoRedaction(BuildContext context, {required MattersRecord matter, required ReceiptsRecord receipt}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => VideoRedactionScreen(matter: matter, receipt: receipt),
    ));

class VideoRedactionScreen extends StatefulWidget {
  const VideoRedactionScreen({super.key, required this.matter, required this.receipt});

  final MattersRecord matter;
  final ReceiptsRecord receipt;

  @override
  State<VideoRedactionScreen> createState() => _VideoRedactionScreenState();
}

enum _Stage { editor, producing, done }

class _VideoRedactionScreenState extends State<VideoRedactionScreen> {
  final _boxes = <VideoBox>[];
  final _mutes = <MuteSpan>[];
  final _reviewed = <int>{};

  _Stage _stage = _Stage.editor;
  double _t = 0.0;
  String? _selected;
  String? _editing;

  // The draft rectangle being dragged on the frame.
  Rect? _draft;
  bool _drawing = false;
  String _scope = 'range';
  double _dStart = 0.0, _dEnd = 5.0;
  String _dReason = 'face';

  // The span being dragged on the audio track.
  double? _muteFrom, _muteTo;

  String? _jobId;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _jobSub;
  double _progress = 0.0;
  String _jobStage = '';
  String? _producedHash, _producedUrl, _producedName;
  String? _error;
  bool _starting = false;

  /// Length of the clip. Videos carry it on the receipt; without it the
  /// timeline still works on a nominal minute and every span stays inside it.
  double get _duration {
    final v = widget.receipt.durationSeconds;
    return v > 0 ? v.toDouble() : 60.0;
  }

  List<Map<String, dynamic>> get _flags => sensitiveOf(widget.receipt);
  int get _unreviewed => _flags.length - _reviewed.length;
  bool get _blocked => _unreviewed > 0;

  /// Why Produce can't run yet, in the words the person needs, or null when it
  /// can. A greyed-out button that says nothing reads as a broken button, so
  /// the button always presses and answers instead.
  String? get _whyNotReady {
    if (_blocked) {
      return 'Review the $_unreviewed marked moment${_unreviewed == 1 ? '' : 's'} below first — '
          'each one needs Mark reviewed before this video can leave the firm.';
    }
    if (_boxes.isEmpty && _mutes.isEmpty) {
      return 'Nothing is marked for redaction yet. Drag a rectangle over the frame to cover something, '
          'or select a span on the audio track to silence it.';
    }
    return null;
  }

  @override
  void dispose() {
    _jobSub?.cancel();
    super.dispose();
  }

  // -- producing ------------------------------------------------------------

  Future<void> _produce() async {
    if (_blocked || (_boxes.isEmpty && _mutes.isEmpty) || _starting) return;
    setState(() {
      _starting = true;
      _stage = _Stage.producing;
      _progress = 0.0;
      _jobStage = 'preparing';
      _error = null;
    });
    // Progress and the job id come from the job document, not from waiting on
    // the call — without this the bar never moves and Cancel has nothing to
    // cancel.
    _watchJob();
    try {
      final r = await VerinApi.redactVideo(
        matterId: widget.matter.reference.id,
        receiptId: widget.receipt.reference.id,
        boxes: _boxes.map((b) => b.toMap()).toList(),
        mutes: _mutes.map((m) => m.toMap()).toList(),
      );
      if (!mounted) return;
      setState(() {
        _stage = _Stage.done;
        _producedHash = '${r['sha256'] ?? ''}';
        _producedUrl = '${r['downloadUrl'] ?? ''}';
        _producedName = '${r['fileName'] ?? ''}';
        _starting = false;
      });
      celebrate(context, title: 'Redacted video is ready', subtitle: _producedName);
    } on VerinApiException catch (e) {
      if (!mounted) return;
      final stopped = e.code == 'cancelled';
      setState(() {
        _stage = _Stage.editor;
        _starting = false;
        _error = stopped ? null : e.message;
      });
      showVToast(context, stopped ? 'Production cancelled' : 'Could not produce the redacted video',
          error: !stopped, description: stopped ? 'Nothing was produced and the original is untouched.' : e.message);
    } finally {
      _jobSub?.cancel();
      _jobSub = null;
    }
  }

  /// The callable runs for tens of seconds, so progress comes from the job
  /// document rather than from waiting on the call.
  void _watchJob() {
    _jobSub?.cancel();
    _jobSub = widget.matter.reference
        .collection('videoRedactions')
        .orderBy('startedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty ? null : s.docs.first)
        .where((d) => d != null)
        .cast<DocumentSnapshot<Map<String, dynamic>>>()
        .listen((d) {
      final data = d.data() ?? const {};
      if (!mounted) return;
      setState(() {
        _jobId = d.id;
        _progress = (data['progress'] is num) ? (data['progress'] as num).toDouble() : _progress;
        _jobStage = '${data['stage'] ?? _jobStage}';
      });
    });
  }

  Future<void> _cancel() async {
    final id = _jobId;
    if (id == null) {
      // The job document hasn't appeared yet, so there is nothing to stop.
      setState(() {
        _stage = _Stage.editor;
        _starting = false;
      });
      return;
    }
    try {
      await VerinApi.cancelVideoRedaction(matterId: widget.matter.reference.id, jobId: id);
      if (mounted) showVToast(context, 'Stopping…', description: 'The encode is being stopped.');
    } on VerinApiException catch (e) {
      if (mounted) showVToast(context, 'Could not cancel', error: true, description: e.message);
    }
  }

  // -- editing --------------------------------------------------------------

  void _addDraft() {
    final d = _draft;
    if (d == null) return;
    final (s, e) = switch (_scope) {
      'whole' => (0.0, _duration),
      'moment' => (_t.floorToDouble(), math.min(_duration, _t.floorToDouble() + 1)),
      _ => (math.min(_dStart, _dEnd), math.max(_dStart, _dEnd)),
    };
    final box = VideoBox(
      id: 'b${DateTime.now().microsecondsSinceEpoch}',
      x: d.left,
      y: d.top,
      w: d.width,
      h: d.height,
      start: s,
      end: e,
      reason: _dReason,
    );
    setState(() {
      _boxes.add(box);
      _selected = box.id;
      _draft = null;
    });
    showVToast(context, 'Redaction added', description: '${kRedactionReasons[_dReason]} · ${spanLabel(s, e, _duration)}');
  }

  void _addMute() {
    final a = _muteFrom, b = _muteTo;
    if (a == null || b == null) return;
    final s = math.min(a, b).roundToDouble();
    final e = math.max(math.min(a, b).roundToDouble() + 1, math.max(a, b).roundToDouble());
    setState(() {
      _mutes.add(MuteSpan(id: 'm${DateTime.now().microsecondsSinceEpoch}', start: s, end: e));
      _muteFrom = null;
      _muteTo = null;
    });
    showVToast(context, 'Audio muted', description: '${spanLabel(s, e, _duration)} — silenced, not lowered');
  }

  // -- the demo does the work while it explains it ---------------------------

  /// Covers the house number, which sits still for the whole clip.
  void _demoDrawBox() {
    if (_boxes.isNotEmpty) return;
    setState(() {
      _t = 4;
      _boxes.add(VideoBox(
        id: 'demo-address',
        x: 6,
        y: 9,
        w: 24,
        h: 26,
        start: 0,
        end: _duration,
        reason: 'address',
      ));
      _selected = 'demo-address';
    });
  }

  /// Silences the span where the name is said aloud.
  void _demoAddMute() {
    if (_mutes.isNotEmpty) return;
    setState(() {
      _mutes.add(MuteSpan(id: 'demo-mute', start: 5, end: 8));
      _t = 6;
    });
  }

  /// Clears the review gate so the walkthrough can reach Produce, the same
  /// way a person would after looking at each flagged moment.
  void _demoReviewFlags() {
    if (!_blocked) return;
    setState(() {
      for (var i = 0; i < _flags.length; i++) {
        _reviewed.add(i);
      }
    });
  }

  // -- build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: TourLauncher(
        tourId: 'video_redaction',
        steps: videoRedactionTour,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: vPagePadding(context),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1360.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  const SizedBox(height: 20.0),
                  if (_stage == _Stage.editor) ...[
                    if (_flags.isNotEmpty) _reviewBanner(context),
                    _editor(context),
                  ] else if (_stage == _Stage.producing)
                    _producing(context)
                  else
                    _done(context),
                  const SizedBox(height: 40.0),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final c = VC.of(context);
    final r = widget.receipt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VIconButton(icon: Icons.arrow_back, size: 16.0, tooltip: 'Back', onPressed: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('REDACTIONS · ${widget.matter.matterName}', style: VT.eyebrow(context, spacing: 0.08)),
              const SizedBox(height: 4.0),
              Text(r.fileName.isEmpty ? r.headline : r.fileName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: VT.h1(context, size: 26.0)),
              const SizedBox(height: 2.0),
              Text(
                [
                  if (r.durationSeconds > 0) mmss(r.durationSeconds.toDouble()),
                  r.kindLabel,
                  'received ${fmtWhen(r.receivedAt)}',
                ].join(' · '),
                style: VT.muted(context, size: 12.5),
              ),
            ],
          ),
        ),
        if (_stage == _Stage.editor) ...[
          const SizedBox(width: 16.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${_boxes.length} redaction${_boxes.length == 1 ? '' : 's'} · ${_mutes.length} mute${_mutes.length == 1 ? '' : 's'}',
                  style: VT.muted(context, size: 11.5)),
              Text('The original is never changed', style: VT.body(context, size: 11.5, color: c.verified)),
              const SizedBox(height: 8.0),
              TourTarget(
                id: 'video_produce',
                onDemoTour: _demoReviewFlags,
                child: VButton(
                  label: 'Produce redacted video',
                  icon: Icons.movie_filter_outlined,
                  onPressed: () {
                    final why = _whyNotReady;
                    if (why != null) {
                      showVToast(context, 'Not ready to produce yet', description: why);
                      return;
                    }
                    _produce();
                  },
                ),
              ),
              if (_whyNotReady != null) ...[
                const SizedBox(height: 6.0),
                SizedBox(
                  width: 280.0,
                  child: Text(
                    _whyNotReady!,
                    textAlign: TextAlign.right,
                    style: VT.muted(context, size: 11.5),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _reviewBanner(BuildContext context) {
    final c = VC.of(context);
    if (!_blocked) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: VPanel(
          child: Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 16.0, color: c.verified),
              const SizedBox(width: 10.0),
              Expanded(child: Text('All ${_flags.length} flagged details were reviewed. This video can be produced.', style: VT.body(context, size: 12.5))),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: c.pending.withValues(alpha: 0.1),
          border: Border.all(color: c.pending.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(VR.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.warning_amber_rounded, size: 18.0, color: c.pending),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("This video can't leave the firm until someone looks.",
                          style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
                      const SizedBox(height: 2.0),
                      Text(
                        'Verin marked $_unreviewed moment${_unreviewed == 1 ? '' : 's'} for review. A mark is a prompt to look, not a finding. Production is locked until each one is reviewed.',
                        style: VT.muted(context, size: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            for (final (i, f) in _flags.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(color: c.card, border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.lg)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${categoryLabel('${f['category'] ?? 'other'}')}${'${f['text'] ?? ''}'.isEmpty ? '' : ' — flagged in this file'}',
                          style: VT.body(context, size: 12.5,
                              color: _reviewed.contains(i) ? c.mutedFg : c.foreground),
                        ),
                      ),
                      if (_reviewed.contains(i))
                        Row(children: [
                          Icon(Icons.check, size: 13.0, color: c.verified),
                          const SizedBox(width: 4.0),
                          Text('Reviewed', style: VT.body(context, size: 11.5, weight: FontWeight.w600, color: c.verified)),
                        ])
                      else
                        VButton(
                          label: 'Mark reviewed',
                          size: VButtonSize.sm,
                          onPressed: () => setState(() => _reviewed.add(i)),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // -- editor ---------------------------------------------------------------

  Widget _editor(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _frameCard(context),
        const SizedBox(height: 12.0),
        _notFollowsNote(context),
        const SizedBox(height: 16.0),
        _timeline(context),
      ],
    );
    final right = _list(context);
    if (!wide) {
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [left, const SizedBox(height: 16.0), right]);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 20.0),
        SizedBox(width: 360.0, child: right),
      ],
    );
  }

  Widget _notFollowsNote(BuildContext context) {
    final c = VC.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14.0, color: c.tealDeep),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            'Each redaction is a fixed rectangle over a time range. If someone walks across the frame, draw one box large enough to cover their whole path, or add several boxes over shorter spans.',
            style: VT.muted(context, size: 12.0),
          ),
        ),
      ],
    );
  }

  Widget _frameCard(BuildContext context) {
    final c = VC.of(context);
    return TourTarget(
      id: 'video_frame',
      onDemoTour: _demoDrawBox,
      child: VCard(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(VR.lg),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) {
                    final p = _pct(d.localPosition, box.biggest);
                    setState(() {
                      _drawing = true;
                      _draft = Rect.fromLTWH(p.dx, p.dy, 0, 0);
                    });
                  },
                  onPanUpdate: (d) {
                    if (!_drawing || _draft == null) return;
                    final p = _pct(d.localPosition, box.biggest);
                    final o = _draft!;
                    setState(() => _draft = Rect.fromLTRB(
                          math.min(o.left, p.dx),
                          math.min(o.top, p.dy),
                          math.max(o.left, p.dx),
                          math.max(o.top, p.dy),
                        ));
                  },
                  onPanEnd: (_) {
                    setState(() {
                      _drawing = false;
                      if (_draft != null && (_draft!.width < 2 || _draft!.height < 3)) {
                        _draft = null;
                      } else {
                        _dStart = _t.floorToDouble();
                        _dEnd = math.min(_duration, _t.floorToDouble() + 5);
                        _scope = 'range';
                        _dReason = 'face';
                      }
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: const Color(0xFF10171A)),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.videocam_outlined, size: 30.0, color: c.mutedFg),
                            const SizedBox(height: 8.0),
                            Text('Frame at ${mmss(_t)}', style: VT.muted(context, size: 12.0)),
                            Text('Drag on the picture to draw a redaction', style: VT.muted(context, size: 11.0)),
                          ],
                        ),
                      ),
                      // Boxes live at this moment only.
                      for (final b in _boxes)
                        if (_t >= b.start && _t <= b.end)
                          Positioned(
                            left: b.x / 100 * box.maxWidth,
                            top: b.y / 100 * box.maxHeight,
                            width: b.w / 100 * box.maxWidth,
                            height: b.h / 100 * box.maxHeight,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                border: _selected == b.id ? Border.all(color: c.teal, width: 2.0) : null,
                              ),
                            ),
                          ),
                      if (_draft != null)
                        Positioned(
                          left: _draft!.left / 100 * box.maxWidth,
                          top: _draft!.top / 100 * box.maxHeight,
                          width: _draft!.width / 100 * box.maxWidth,
                          height: _draft!.height / 100 * box.maxHeight,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.78),
                              border: Border.all(color: c.teal, width: 2.0),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_draft != null && !_drawing) ...[
            const SizedBox(height: 12.0),
            _draftPopover(context),
          ],
          const SizedBox(height: 12.0),
          _scrubber(context),
        ],
      ),
      ),
    );
  }

  Offset _pct(Offset local, Size size) => Offset(
        _clamp(local.dx / size.width * 100, 0, 100),
        _clamp(local.dy / size.height * 100, 0, 100),
      );

  Widget _draftPopover(BuildContext context) {
    final c = VC.of(context);
    final (s, e) = switch (_scope) {
      'whole' => (0.0, _duration),
      'moment' => (_t.floorToDouble(), math.min(_duration, _t.floorToDouble() + 1)),
      _ => (math.min(_dStart, _dEnd), math.max(_dStart, _dEnd)),
    };
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(color: c.card, border: Border.all(color: c.teal), borderRadius: BorderRadius.circular(VR.xl)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cover this area…', style: VT.body(context, size: 12.5, weight: FontWeight.w600)),
          const SizedBox(height: 10.0),
          VSegmented<String>(
            value: _scope,
            options: const ['moment', 'range', 'whole'],
            fontSize: 11.5,
            labelFor: (v) => const {'moment': 'This moment only', 'range': 'From here to here', 'whole': 'Whole clip'}[v]!,
            onChanged: (v) => setState(() => _scope = v),
          ),
          if (_scope == 'range') ...[
            const SizedBox(height: 10.0),
            Row(
              children: [
                _stepper(context, 'From', _dStart, (v) => setState(() => _dStart = v)),
                const SizedBox(width: 16.0),
                _stepper(context, 'To', _dEnd, (v) => setState(() => _dEnd = v)),
              ],
            ),
          ],
          const SizedBox(height: 10.0),
          Text(
            '${_scope == 'moment' ? 'Covers 1 second, from ${mmss(_t.floorToDouble())}.' : _scope == 'whole' ? 'Covers 0:00–${mmss(_duration)}.' : 'Covers ${mmss(s)}–${mmss(e)}.'} '
            'The box stays in this exact spot. It does not follow movement.',
            style: VT.muted(context, size: 11.5),
          ),
          const SizedBox(height: 10.0),
          Text('REASON', style: VT.eyebrow(context, size: 10.0)),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 6.0,
            runSpacing: 6.0,
            children: [
              for (final entry in kRedactionReasons.entries)
                _chip(context, entry.value, _dReason == entry.key, () => setState(() => _dReason = entry.key)),
            ],
          ),
          const SizedBox(height: 12.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              VButton(label: 'Cancel', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => setState(() => _draft = null)),
              const SizedBox(width: 8.0),
              VButton(label: 'Add redaction', size: VButtonSize.sm, onPressed: _addDraft),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, bool on, VoidCallback onTap) {
    final c = VC.of(context);
    return VHover(
      onTap: onTap,
      builder: (context, hovered) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
        decoration: BoxDecoration(color: on ? c.primary : (hovered ? c.panel : c.secondary), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: VT.body(context, size: 11.0, weight: FontWeight.w600, color: on ? c.primaryFg : c.foreground)),
      ),
    );
  }

  Widget _stepper(BuildContext context, String label, double value, ValueChanged<double> onChanged) {
    final c = VC.of(context);
    Widget btn(IconData i, VoidCallback f) => VHover(
          onTap: f,
          builder: (context, _) => Container(
            width: 24.0,
            height: 24.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg)),
            child: Icon(i, size: 13.0),
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: VT.muted(context, size: 11.0)),
        const SizedBox(width: 6.0),
        btn(Icons.remove, () => onChanged(_clamp(value - 1, 0, _duration))),
        SizedBox(width: 44.0, child: Text(mmss(value), textAlign: TextAlign.center, style: VT.mono(context, size: 12.0))),
        btn(Icons.add, () => onChanged(_clamp(value + 1, 0, _duration))),
      ],
    );
  }

  Widget _scrubber(BuildContext context) {
    final c = VC.of(context);
    return Row(
      children: [
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.0,
              activeTrackColor: c.teal,
              inactiveTrackColor: c.secondary,
              thumbColor: c.teal,
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
            ),
            child: Slider(
              value: _clamp(_t, 0, _duration),
              max: _duration,
              onChanged: (v) => setState(() => _t = v),
            ),
          ),
        ),
        const SizedBox(width: 8.0),
        Text('${mmss(_t)} / ${mmss(_duration)}', style: VT.mono(context, size: 12.0)),
      ],
    );
  }

  // -- timeline -------------------------------------------------------------

  /// Boxes packed into lanes so overlapping spans do not sit on top of one
  /// another: the first lane whose last span has already ended.
  Map<String, int> _lanes() {
    final ends = <double>[];
    final map = <String, int>{};
    final sorted = [..._boxes]..sort((a, b) => a.start.compareTo(b.start));
    for (final b in sorted) {
      var lane = ends.indexWhere((e) => e <= b.start);
      if (lane == -1) {
        lane = ends.length;
        ends.add(b.end);
      } else {
        ends[lane] = b.end;
      }
      map[b.id] = lane;
    }
    return map;
  }

  Widget _timeline(BuildContext context) {
    final c = VC.of(context);
    final lanes = _lanes();
    final laneCount = lanes.isEmpty ? 1 : (lanes.values.reduce(math.max) + 1);
    return TourTarget(
      id: 'video_timeline',
      onDemoTour: _demoAddMute,
      child: VCard(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          double at(double s) => (s / _duration) * w;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.movie_outlined, size: 13.0, color: c.tealDeep),
                  const SizedBox(width: 6.0),
                  Text('Redactions', style: VT.body(context, size: 12.0, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6.0),
              SizedBox(
                height: laneCount * 30.0 + 8.0,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg))),
                    ),
                    for (final b in _boxes)
                      Positioned(
                        left: at(b.start),
                        top: 4.0 + (lanes[b.id] ?? 0) * 30.0,
                        width: math.max(18.0, at(b.end) - at(b.start) - 2),
                        height: 26.0,
                        child: VHover(
                          onTap: () => setState(() {
                            _selected = b.id;
                            _t = b.start;
                          }),
                          builder: (context, _) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0),
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(VR.lg),
                              border: _selected == b.id ? Border.all(color: c.foreground, width: 2.0) : null,
                            ),
                            child: Text(
                              '${kRedactionReasons[b.reason] ?? 'Other'} · ${spanLabel(b.start, b.end, _duration)}',
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: VT.body(context, size: 10.5, weight: FontWeight.w600, color: c.primaryFg),
                            ),
                          ),
                        ),
                      ),
                    Positioned(left: at(_t), top: 0, bottom: 0, child: Container(width: 1.0, color: c.foreground)),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Icon(Icons.graphic_eq_rounded, size: 13.0, color: c.tealDeep),
                  const SizedBox(width: 6.0),
                  Text('Audio', style: VT.body(context, size: 12.0, weight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 6.0),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (d) => setState(() {
                  _muteFrom = _clamp(d.localPosition.dx / w * _duration, 0, _duration);
                  _muteTo = _muteFrom;
                }),
                onPanUpdate: (d) => setState(() => _muteTo = _clamp(d.localPosition.dx / w * _duration, 0, _duration)),
                child: SizedBox(
                  height: 56.0,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(decoration: BoxDecoration(color: c.secondary, borderRadius: BorderRadius.circular(VR.lg))),
                      ),
                      // A level line, not a real waveform: the audio is not
                      // decoded here, and a drawn shape that looked like one
                      // would be a lie about the file.
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6.0),
                          child: Row(
                            children: [
                              for (var i = 0; i < 80; i++)
                                Expanded(
                                  child: Builder(builder: (context) {
                                    final s = (i / 80) * _duration;
                                    final muted = _mutes.any((m) => s >= m.start && s <= m.end);
                                    return Container(
                                      height: muted ? 2.0 : 18.0,
                                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                                      decoration: BoxDecoration(
                                        color: (muted ? c.mutedFg : c.teal).withValues(alpha: muted ? 0.5 : 0.45),
                                        borderRadius: BorderRadius.circular(2.0),
                                      ),
                                    );
                                  }),
                                ),
                            ],
                          ),
                        ),
                      ),
                      for (final m in _mutes)
                        Positioned(
                          left: at(m.start),
                          width: math.max(10.0, at(m.end) - at(m.start)),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.broken.withValues(alpha: 0.18),
                              border: Border.symmetric(vertical: BorderSide(color: c.broken, width: 2.0)),
                            ),
                            child: Icon(Icons.volume_off_outlined, size: 13.0, color: c.broken),
                          ),
                        ),
                      if (_muteFrom != null && _muteTo != null)
                        Positioned(
                          left: at(math.min(_muteFrom!, _muteTo!)),
                          width: math.max(2.0, (at(_muteTo!) - at(_muteFrom!)).abs()),
                          top: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(color: c.teal.withValues(alpha: 0.2), border: Border.all(color: c.teal, width: 2.0)),
                          ),
                        ),
                      Positioned(left: at(_t), top: 0, bottom: 0, child: Container(width: 1.0, color: c.foreground)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              if (_muteFrom != null && _muteTo != null && (_muteTo! - _muteFrom!).abs() >= 0.8)
                VPanel(
                  child: Row(
                    children: [
                      Icon(Icons.volume_off_outlined, size: 16.0, color: c.tealDeep),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mute ${mmss(math.min(_muteFrom!, _muteTo!))}–${mmss(math.max(_muteFrom!, _muteTo!))}',
                                style: VT.body(context, size: 12.5, weight: FontWeight.w600)),
                            Text('This silences the span completely. The sound is removed, not turned down.',
                                style: VT.muted(context, size: 11.5)),
                          ],
                        ),
                      ),
                      VButton(label: 'Cancel', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: () => setState(() {
                            _muteFrom = null;
                            _muteTo = null;
                          })),
                      const SizedBox(width: 6.0),
                      VButton(label: 'Mute this span', size: VButtonSize.sm, onPressed: _addMute),
                    ],
                  ),
                )
              else
                Text('Drag across the audio track to select a span to mute.', style: VT.muted(context, size: 11.5)),
            ],
          );
        },
      ),
      ),
    );
  }

  // -- right-hand list ------------------------------------------------------

  Widget _list(BuildContext context) {
    final c = VC.of(context);
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Redactions (${_boxes.length})', style: VT.body(context, size: 15.0, weight: FontWeight.w600)),
          const SizedBox(height: 10.0),
          if (_boxes.isEmpty)
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                border: Border.all(color: c.border, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(VR.lg),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_box_outlined, size: 18.0, color: c.mutedFg),
                  const SizedBox(height: 6.0),
                  Text('No redactions yet. Drag a rectangle on the picture.',
                      textAlign: TextAlign.center, style: VT.muted(context, size: 12.0)),
                ],
              ),
            ),
          for (final (i, b) in _boxes.indexed)
            VReveal(
              key: ValueKey(b.id),
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _boxRow(context, b),
              ),
            ),
          const SizedBox(height: 14.0),
          Text('Muted audio (${_mutes.length})', style: VT.body(context, size: 13.5, weight: FontWeight.w600)),
          const SizedBox(height: 6.0),
          if (_mutes.isEmpty)
            Text('Nothing muted. Select a span on the audio track.', style: VT.muted(context, size: 11.5)),
          for (final m in _mutes)
            Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                decoration: BoxDecoration(border: Border.all(color: c.border), borderRadius: BorderRadius.circular(VR.lg)),
                child: Row(
                  children: [
                    Icon(Icons.volume_off_outlined, size: 15.0, color: c.broken),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(spanLabel(m.start, m.end, _duration), style: VT.body(context, size: 12.5, weight: FontWeight.w500)),
                          Text('Silenced completely', style: VT.muted(context, size: 11.0)),
                        ],
                      ),
                    ),
                    VIconButton(icon: Icons.close, size: 13.0, tooltip: 'Remove', onPressed: () => setState(() => _mutes.remove(m))),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12.0),
          Text(
            'Producing burns solid black rectangles into the picture and silences the muted spans, then saves a new file. The original is never altered.',
            style: VT.muted(context, size: 11.0),
          ),
        ],
      ),
    );
  }

  Widget _boxRow(BuildContext context, VideoBox b) {
    final c = VC.of(context);
    final on = _selected == b.id;
    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: on ? c.teal : c.border),
        color: on ? c.secondary : Colors.transparent,
        borderRadius: BorderRadius.circular(VR.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44.0,
                height: 30.0,
                decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(6.0), border: Border.all(color: c.border)),
                alignment: Alignment.center,
                child: Icon(Icons.crop_square, size: 13.0, color: c.mutedFg),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kRedactionReasons[b.reason] ?? 'Other', style: VT.body(context, size: 11.5, weight: FontWeight.w600, color: c.tealDeep)),
                    Text(spanLabel(b.start, b.end, _duration), style: VT.body(context, size: 12.5)),
                  ],
                ),
              ),
              VIconButton(
                icon: Icons.edit_outlined,
                size: 13.0,
                tooltip: 'Edit',
                onPressed: () => setState(() => _editing = _editing == b.id ? null : b.id),
              ),
              VIconButton(
                icon: Icons.delete_outline,
                size: 13.0,
                tooltip: 'Remove',
                onPressed: () => setState(() {
                  _boxes.remove(b);
                  if (_selected == b.id) _selected = null;
                }),
              ),
            ],
          ),
          if (_editing == b.id) ...[
            const SizedBox(height: 10.0),
            const VHairline(),
            const SizedBox(height: 10.0),
            Wrap(
              spacing: 6.0,
              runSpacing: 6.0,
              children: [
                for (final e in kRedactionReasons.entries)
                  _chip(context, e.value, b.reason == e.key, () => setState(() => b.reason = e.key)),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                _stepper(context, 'From', b.start, (v) => setState(() => b.start = math.min(v, b.end - 1))),
                const SizedBox(width: 12.0),
                _stepper(context, 'To', b.end, (v) => setState(() => b.end = math.max(v, b.start + 1))),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                VButton(
                  label: 'Cover whole clip',
                  kind: VButtonKind.link,
                  size: VButtonSize.sm,
                  onPressed: () => setState(() {
                    b.start = 0;
                    b.end = _duration;
                  }),
                ),
                VButton(label: 'Done', size: VButtonSize.sm, onPressed: () => setState(() => _editing = null)),
              ],
            ),
            const SizedBox(height: 6.0),
            Text('Position and size are fixed. To change them, remove this box and draw a new one.', style: VT.muted(context, size: 10.5)),
          ],
        ],
      ),
    );
  }

  // -- producing and done ---------------------------------------------------

  String get _stageText => switch (_jobStage) {
        'preparing' => 'Preparing a copy of the original',
        'redacting' => 'Burning in redactions',
        'silencing' => 'Silencing muted spans',
        'fingerprinting' => 'Fingerprinting the new file',
        _ => 'Working',
      };

  Widget _producing(BuildContext context) {
    final c = VC.of(context);
    final pct = (_progress * 100).clamp(0, 100).round();
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$_stageText… $pct%', style: VT.body(context, size: 13.0, weight: FontWeight.w600)),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _progress <= 0 ? null : _progress,
              minHeight: 8.0,
              color: c.teal,
              backgroundColor: c.secondary,
            ),
          ),
          const SizedBox(height: 18.0),
          for (final step in const [
            ('preparing', 'Preparing a copy of the original'),
            ('redacting', 'Burning in redactions'),
            ('silencing', 'Silencing muted spans'),
            ('fingerprinting', 'Fingerprinting the new file'),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Icon(
                    _jobStage == step.$1 ? Icons.radio_button_checked : Icons.circle_outlined,
                    size: 14.0,
                    color: _jobStage == step.$1 ? c.teal : c.mutedFg,
                  ),
                  const SizedBox(width: 8.0),
                  Text(step.$2, style: VT.body(context, size: 12.5, color: _jobStage == step.$1 ? c.foreground : c.mutedFg)),
                ],
              ),
            ),
          const SizedBox(height: 10.0),
          VPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 15.0, color: c.tealDeep),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    'Redacting re-encodes the whole file, so this takes a while. You can leave this page and come back — the work continues on our side. The original is not touched.',
                    style: VT.body(context, size: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              VButton(label: 'Leave this page', kind: VButtonKind.secondary, size: VButtonSize.sm, onPressed: () => Navigator.of(context).maybePop()),
              const SizedBox(width: 8.0),
              VButton(label: 'Cancel', kind: VButtonKind.link, size: VButtonSize.sm, onPressed: _cancel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _done(BuildContext context) {
    final c = VC.of(context);
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const VSuccessBurst(size: 26.0),
              const SizedBox(width: 10.0),
              Text('Redacted video produced', style: VT.h3(context, size: 18.0)),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            '${_boxes.length} fixed rectangle${_boxes.length == 1 ? '' : 's'} burned into the picture and '
            '${_mutes.length} span${_mutes.length == 1 ? '' : 's'} silenced. This is a new file.',
            style: VT.muted(context, size: 12.5),
          ),
          const SizedBox(height: 16.0),
          Text('FINGERPRINT OF THIS FILE · SHA-256', style: VT.eyebrow(context, size: 10.0)),
          const SizedBox(height: 6.0),
          VPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: SelectableText(_producedHash ?? '', style: VT.mono(context, size: 11.5))),
                VIconButton(
                  icon: Icons.copy,
                  size: 13.0,
                  tooltip: 'Copy',
                  onPressed: () => copyToClipboard(context, _producedHash ?? '', what: 'Fingerprint copied'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14.0),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15.0, color: c.verified),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text('The original is unchanged — still stored exactly as received, and it still verifies against its own fingerprint.',
                    style: VT.muted(context, size: 12.0)),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Row(
            children: [
              VButton(
                label: 'Download the redacted video',
                icon: Icons.file_download_outlined,
                onPressed: (_producedUrl ?? '').isEmpty ? null : () => launchURL(_producedUrl!),
              ),
              const SizedBox(width: 8.0),
              VButton(
                label: 'Back to the editor',
                kind: VButtonKind.secondary,
                onPressed: () => setState(() {
                  _stage = _Stage.editor;
                  _progress = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text('Editing again makes a new version; this one is kept.', style: VT.muted(context, size: 11.0)),
        ],
      ),
    );
  }
}
