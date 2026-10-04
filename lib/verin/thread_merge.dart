// Verin Legal — merge every receipt's extracted messages into one thread
// (Thread tab, guide §6c).
//
// Order: receipts by receivedAt (oldest first), then each receipt's messages
// in the order the extraction read them off the screen. That on-screen order
// is the only reliable ordering available — timestampLabel is free text
// ("2:14 PM", "Yesterday 9:03 AM", or ""), so sorting on it as a string (what
// the earlier mergeThreadMessages action did) scrambles threads across days.
//
// Consecutive screenshots of the same conversation usually overlap by a few
// messages. An entry whose speaker + text + timestamp label match one of the
// last few entries already kept is marked `isRepeat` rather than dropped, so
// nothing the client sent silently disappears from the record.

import '/backend/backend.dart';

import 'record_ext.dart';
import 'verin_config.dart';

class ThreadEntry {
  ThreadEntry({
    required this.speaker,
    required this.text,
    required this.timestampLabel,
    required this.isGap,
    required this.isHeader,
    required this.confidence,
    required this.platform,
    required this.sourceThumbnailUrl,
    required this.receipt,
    required this.indexInReceipt,
    this.isRepeat = false,
  });

  final String speaker;
  final String text;
  final String timestampLabel;
  final bool isGap;
  final bool isHeader;
  final double confidence;
  final String platform;
  final String sourceThumbnailUrl;
  final ReceiptsRecord receipt;
  final int indexInReceipt;
  bool isRepeat;

  bool get isFromClient => speaker == 'client';
  bool get isLowConfidence => confidence < kLowConfidence;

  String get _key => '$speaker\u0000${text.trim()}\u0000${timestampLabel.trim()}';
}

int _compareReceipts(ReceiptsRecord a, ReceiptsRecord b) {
  final ra = a.receivedAt;
  final rb = b.receivedAt;
  if (ra == null && rb == null) return a.reference.id.compareTo(b.reference.id);
  if (ra == null) return 1;
  if (rb == null) return -1;
  final c = ra.compareTo(rb);
  return c != 0 ? c : a.reference.id.compareTo(b.reference.id);
}

/// Receipts that carry extracted messages, oldest first.
List<ReceiptsRecord> threadSources(List<ReceiptsRecord> receipts) {
  final withMessages = receipts.where((r) => r.threadMessages.isNotEmpty).toList();
  withMessages.sort(_compareReceipts);
  return withMessages;
}

List<ThreadEntry> mergeThread(List<ReceiptsRecord> receipts, {int overlapWindow = 8}) {
  final out = <ThreadEntry>[];
  for (final r in threadSources(receipts)) {
    final msgs = r.threadMessages;
    for (var i = 0; i < msgs.length; i++) {
      final m = msgs[i];
      final e = ThreadEntry(
        speaker: m.speaker.toLowerCase(),
        text: m.text,
        timestampLabel: m.timestampLabel,
        isGap: m.isGap,
        isHeader: m.isHeader,
        confidence: m.hasConfidence() ? m.confidence : 1.0,
        platform: m.platform.isNotEmpty ? m.platform : r.detectedPlatform,
        sourceThumbnailUrl: m.sourceThumbnailUrl.isNotEmpty ? m.sourceThumbnailUrl : r.sourceUrl,
        receipt: r,
        indexInReceipt: i,
      );
      if (!e.isHeader && e.text.trim().isNotEmpty) {
        final start = out.length > overlapWindow ? out.length - overlapWindow : 0;
        for (var j = out.length - 1; j >= start; j--) {
          final prev = out[j];
          if (!identical(prev.receipt, r) && prev._key == e._key) {
            e.isRepeat = true;
            break;
          }
        }
      }
      out.add(e);
    }
  }
  return out;
}

/// Share of messages read at or above the low-confidence threshold (0..1),
/// or null when there are no messages.
double? threadAccuracy(List<ThreadEntry> entries) {
  final real = entries.where((e) => !e.isHeader).toList();
  if (real.isEmpty) return null;
  final total = real.fold<double>(0.0, (sum, e) => sum + e.confidence.clamp(0.0, 1.0).toDouble());
  return total / real.length;
}

int threadGapCount(List<ThreadEntry> entries) => entries.where((e) => e.isGap).length;
