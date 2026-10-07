// Demo-run log: demoRuns/{id}, one timed demo in a demo workspace.

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/verin/verin_config.dart';

import '../data/model.dart';

// ---------------------------------------------------------------------------
// Demo runs (checklist #8: every demo is timed and logged)
// ---------------------------------------------------------------------------

class DemoRun {
  const DemoRun(this.id, this.d);

  final String id;
  final Map<String, dynamic> d;

  DateTime? get startedAt => rDate(d, 'startedAt') ?? rDate(d, 'startedAtClient');
  DateTime? get endedAt => rDate(d, 'endedAt');
  bool get running => rStr(d, 'status') == 'running';
  String get prospect => rStr(d, 'prospectFirm');
  String get matter => rStr(d, 'matterName');
  String get ranBy => rStr(d, 'startedByName');
  String get notes => rStr(d, 'notes');
  int get itemsIn => rInt(d, 'itemsIn');
  int get itemsOut => rInt(d, 'itemsOut');
  int get itemsFlagged => rInt(d, 'itemsFlagged');
  double? num_(String k) => d[k] is num ? (d[k] as num).toDouble() : null;
  double? get pipelineMinutes => num_('pipelineMinutes');
  double? get reviewMinutes => num_('reviewMinutes');
  double? get writeBackSeconds => num_('writeBackSeconds');
  double? get firmHoursByHand => num_('firmHoursByHand');

  double? get totalMinutes {
    final s = startedAt, e = endedAt;
    if (s == null || e == null) return null;
    return e.difference(s).inSeconds / 60.0;
  }
}

final _runs = FirebaseFirestore.instance.collection('demoRuns');

/// The signed-in firm's runs (a demo workspace logs its own).
Stream<List<DemoRun>> firmDemoRunsStream() {
  final fid = currentFirmId();
  return _runs
      .where('firmID', isEqualTo: fid.isEmpty ? '_none_' : fid)
      .snapshots()
      .map((s) => [for (final d in s.docs) DemoRun(d.id, d.data())]..sort(_newestFirst));
}

int _newestFirst(DemoRun a, DemoRun b) =>
    (b.startedAt ?? DateTime(2100)).compareTo(a.startedAt ?? DateTime(2100));

Future<String> startDemoRun() async {
  final u = VUser.current();
  final ref = await _runs.add({
    'firmID': currentFirmId(),
    'status': 'running',
    'startedAt': FieldValue.serverTimestamp(),
    'startedAtClient': DateTime.now(),
    'startedBy': currentUserUid,
    'startedByName': u.name.isNotEmpty ? u.name : u.email,
  });
  return ref.id;
}

/// What the pipeline did since the run started, read from the firm's receipts.
class DemoRunCounts {
  const DemoRunCounts({required this.itemsIn, required this.itemsOut, required this.flagged, this.pipelineMinutes});
  final int itemsIn;
  final int itemsOut;
  final int flagged;

  /// Sum of arrival → reading-finished time over the items read.
  final double? pipelineMinutes;
}

Future<DemoRunCounts> measureDemoRun(DateTime since) async {
  final snap = await FirebaseFirestore.instance.collection('Receipts').where('firmID', isEqualTo: currentFirmId()).get();
  var inn = 0, out = 0, flagged = 0, ms = 0, timed = 0;
  for (final doc in snap.docs) {
    final d = doc.data();
    final at = rDate(d, 'receivedAt') ?? rDate(d, 'createdAt');
    if (at == null || at.isBefore(since)) continue;
    inn++;
    final label = rStr(d, 'classificationLabel').toLowerCase();
    if (label == 'processed') out++;
    if (label == 'uncertain' || label == 'unreadable' || rStr(d, 'extractionState') == 'quarantined') flagged++;
    final done = rDate(d, 'extractedAt');
    if (done != null && done.isAfter(at)) {
      ms += done.difference(at).inMilliseconds;
      timed++;
    }
  }
  return DemoRunCounts(itemsIn: inn, itemsOut: out, flagged: flagged, pipelineMinutes: timed == 0 ? null : ms / 60000.0);
}

Future<void> finishDemoRun(String id, Map<String, dynamic> fields) => _runs.doc(id).set({
      ...fields,
      'status': 'done',
      'endedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

Future<void> discardDemoRun(String id) => _runs.doc(id).set({'status': 'discarded', 'endedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));

double? median(List<double> xs) {
  if (xs.isEmpty) return null;
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
}
