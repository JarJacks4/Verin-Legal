// The server-built views of a matter's record (see functions/verin/thread):
//   Matters/{id}/derived/thread   reconstructed conversation, gaps, names,
//                                 follow-up suggestions
//   Matters/{id}/updates/{rid}    what each new item changed
//   FollowUps                     requests staff drafted, sent or dismissed

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/verin/verin_config.dart';

String _s(Object? v) => v is String ? v : '';
int _i(Object? v) => v is num ? v.toInt() : 0;
double _d(Object? v, [double fallback = 1.0]) => v is num ? v.toDouble() : fallback;
List<String> _ls(Object? v) => v is List ? v.whereType<String>().toList() : const [];

/// A normalized rectangle on an image (fractions of width/height).
class SourceBox {
  const SourceBox(this.x, this.y, this.w, this.h);
  final double x, y, w, h;

  static SourceBox? from(Object? v) {
    if (v is! Map) return null;
    final x = v['x'], y = v['y'], w = v['w'], h = v['h'];
    if (x is! num || y is! num || w is! num || h is! num || w <= 0 || h <= 0) return null;
    return SourceBox(x.toDouble(), y.toDouble(), w.toDouble(), h.toDouble());
  }

  Rect toRect(Size size) => Rect.fromLTWH(x * size.width, y * size.height, w * size.width, h * size.height);
}

/// One line of the reconstructed record: a message, a date divider or a gap.
class TEntry {
  TEntry(this.raw)
      : kind = _s(raw['kind']),
        key = _s(raw['key']),
        rid = _s(raw['rid']),
        index = _i(raw['i']),
        speaker = _s(raw['speaker']),
        sender = _s(raw['sender']),
        person = _s(raw['person']),
        text = _s(raw['text']),
        label = _s(raw['label']),
        date = _s(raw['date']),
        time = _s(raw['time']),
        timeOnly = _s(raw['timeOnly']),
        dateBasis = _s(raw['dateBasis']),
        dateConfidence = _s(raw['dateConfidence']),
        read = _d(raw['read']),
        alsoIn = _ls(raw['alsoIn']),
        flags = _ls(raw['flags']),
        orderBasis = _s(raw['orderBasis']),
        reason = _s(raw['reason']),
        afterText = _s(raw['afterText']),
        beforeText = _s(raw['beforeText']);

  final Map<String, dynamic> raw;
  final String kind, key, rid, speaker, sender, person, text, label, date, time, timeOnly, dateBasis, dateConfidence, orderBasis;
  final int index;
  final double read;
  final List<String> alsoIn, flags;
  final String reason, afterText, beforeText;

  bool get isMessage => kind == 'msg';
  bool get isHeader => kind == 'header';
  bool get isGap => kind == 'gap';
  bool get isClient => speaker == 'client';
  bool has(String flag) => flags.contains(flag);

  /// "Mar 3, 2026 · 2:14 PM", "time 2:14 PM · no date", or "no date".
  String get whenLabel {
    if (date.isEmpty) return timeOnly.isNotEmpty ? '${_clock(timeOnly)} · no date' : 'no date';
    final d = _day(date);
    return time.isNotEmpty ? '$d · ${_clock(time)}' : d;
  }

  /// How the date was worked out, for the reviewer.
  String get dateBasisLabel => switch (dateBasis) {
        'explicit' => 'printed date',
        'year_inferred' => 'printed day, year inferred',
        'relative' => 'from "${label.trim().isEmpty ? 'relative label' : label.trim()}"',
        'carried' => 'from the nearest date above',
        'item_date' => 'date of the item',
        _ => 'no date found',
      };
}

String _clock(String hhmm) {
  final p = hhmm.split(':');
  if (p.length != 2) return hhmm;
  final h = int.tryParse(p[0]) ?? 0;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${p[1]} ${h < 12 ? 'AM' : 'PM'}';
}

String _day(String ymd) {
  final p = ymd.split('-');
  if (p.length != 3) return ymd;
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final m = int.tryParse(p[1]) ?? 1;
  return '${months[(m - 1).clamp(0, 11)]} ${int.tryParse(p[2]) ?? p[2]}, ${p[0]}';
}

String fmtYmd(String ymd) => ymd.isEmpty ? '' : _day(ymd);

class Participant {
  Participant(Map<String, dynamic> m)
      : name = _s(m['name']),
        key = _s(m['key']),
        count = _i(m['count']),
        confirmedAs = _s(m['confirmedAs']);
  final String name, key, confirmedAs;
  final int count;
}

class Suggestion {
  Suggestion(Map<String, dynamic> m)
      : key = _s(m['key']),
        kind = _s(m['kind']),
        title = _s(m['title']),
        request = _s(m['request']),
        anchor = _s(m['anchor']),
        receiptId = _s(m['receiptId']);
  final String key, kind, title, request, anchor, receiptId;
}

class ThreadDoc {
  ThreadDoc(Map<String, dynamic> d)
      : entries = (d['entries'] is List ? d['entries'] as List : const [])
            .whereType<Map>()
            .map((e) => TEntry(Map<String, dynamic>.from(e)))
            .toList(),
        notes = _ls(d['notes']),
        stats = d['stats'] is Map ? Map<String, dynamic>.from(d['stats'] as Map) : const {},
        clientNames = _participants(d, 'client'),
        otherNames = _participants(d, 'other'),
        suggestions = (d['suggestions'] is List ? d['suggestions'] as List : const [])
            .whereType<Map>()
            .map((e) => Suggestion(Map<String, dynamic>.from(e)))
            .toList(),
        builtAt = (d['builtAt'] as Timestamp?)?.toDate(),
        truncated = d['truncated'] == true;

  final List<TEntry> entries;
  final List<String> notes;
  final Map<String, dynamic> stats;
  final List<Participant> clientNames, otherNames;
  final List<Suggestion> suggestions;
  final DateTime? builtAt;
  final bool truncated;

  int stat(String k) => _i(stats[k]);

  static List<Participant> _participants(Map<String, dynamic> d, String side) {
    final p = d['participants'];
    if (p is! Map || p[side] is! List) return const [];
    return (p[side] as List).whereType<Map>().map((m) => Participant(Map<String, dynamic>.from(m))).toList();
  }

  /// Entries of one receipt, in its on-screen order, by index.
  Map<int, TEntry> forReceipt(String rid) {
    final out = <int, TEntry>{};
    for (final e in entries) {
      if (e.rid == rid) out[e.index] = e;
      for (final k in e.alsoIn) {
        final p = k.split('#');
        if (p.length == 2 && p[0] == rid) out[int.tryParse(p[1]) ?? -1] ??= e;
      }
    }
    return out;
  }
}

DocumentReference _threadRef(DocumentReference matter) => matter.collection('derived').doc('thread');

/// The matter's reconstructed thread, or null until it has been built.
Stream<ThreadDoc?> matterThreadStream(DocumentReference matter) =>
    _threadRef(matter).snapshots().map((s) => s.exists ? ThreadDoc(s.data() as Map<String, dynamic>) : null);

class MatterUpdate {
  MatterUpdate(this.ref, Map<String, dynamic> d)
      : receiptRef = d['receiptId'] as DocumentReference?,
        headline = _s(d['headline']),
        channel = _s(d['channel']),
        kinds = _ls(d['kinds']),
        summary = _s(d['summary']),
        newMessages = _i(d['newMessages']),
        repeatedMessages = _i(d['repeatedMessages']),
        at = (d['at'] as Timestamp?)?.toDate();
  final DocumentReference ref;
  final DocumentReference? receiptRef;
  final String headline, channel, summary;
  final List<String> kinds;
  final int newMessages, repeatedMessages;
  final DateTime? at;
}

Stream<List<MatterUpdate>> matterUpdatesStream(DocumentReference matter, {int limit = 50}) => matter
    .collection('updates')
    .orderBy('at', descending: true)
    .limit(limit)
    .snapshots()
    .map((s) => s.docs.map((d) => MatterUpdate(d.reference, d.data())).toList());

class FollowUp {
  FollowUp(this.ref, Map<String, dynamic> d)
      : key = _s(d['key']),
        kind = _s(d['kind']),
        title = _s(d['title']),
        request = _s(d['request']),
        status = _s(d['status']),
        recipient = _s(d['recipient']),
        subject = _s(d['subject']),
        body = _s(d['body']),
        sentByName = _s(d['sentByName']),
        sentAt = (d['sentAt'] as Timestamp?)?.toDate(),
        resolvedAt = (d['resolvedAt'] as Timestamp?)?.toDate(),
        createdAt = (d['createdAt'] as Timestamp?)?.toDate();
  final DocumentReference ref;
  final String key, kind, title, request, status, recipient, subject, body, sentByName;
  final DateTime? sentAt, resolvedAt, createdAt;
}

Stream<List<FollowUp>> matterFollowUpsStream(DocumentReference matter) => FirebaseFirestore.instance
    .collection('FollowUps')
    .where('matterId', isEqualTo: matter)
    .where('firmID', isEqualTo: currentFirmId())
    .snapshots()
    .map((s) => s.docs.map((d) => FollowUp(d.reference, d.data())).toList()
      ..sort((a, b) => (b.createdAt ?? DateTime(2100)).compareTo(a.createdAt ?? DateTime(2100))));

/// Staff-confirmed names: personKey -> display name.
Map<String, String> participantAliases(MattersRecord m) {
  final v = m.snapshotData['participantAliases'];
  if (v is! Map) return const {};
  return {for (final e in v.entries) if (e.key is String && e.value is String) e.key as String: e.value as String};
}

String matterClientEmail(MattersRecord m) => _s(m.snapshotData['clientEmail']);
