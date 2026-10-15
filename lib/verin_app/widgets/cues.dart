// Sound, used sparingly.
//
// A paralegal is often in an open office, on a call with a client, or sitting
// in a courthouse hallway. A chime at the wrong moment is worse than silence,
// so Verin is quiet by default and says four things at most:
//
//   arrival     evidence landed in a matter
//   done        something the person started finished (a production, a
//               delivery, a redacted video)
//   attention   something needs a person — a failed delivery, a flag
//   soft        a small confirmation, for a copy or a save
//
// Each is two or three low sine tones a few hundred milliseconds long, built
// as a WAV in memory. Nothing to license, nothing to download, and no file
// that could go missing from a build. Closer to a well-made car indicator
// than a notification: no melody, nothing cheerful, nothing that carries
// across a room.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

enum VCue { arrival, done, attention, soft }

/// One note: a frequency, when it starts, how long it lasts, how loud.
class _Note {
  const _Note(this.hz, this.start, this.length, this.gain);
  final double hz, start, length, gain;
}

/// Low and close together — an interval, never a tune. Quiet on purpose: the
/// loudest of these peaks at about a fifth of full scale.
const Map<VCue, List<_Note>> _score = {
  // Two rising notes, a fourth apart: something arrived.
  VCue.arrival: [
    _Note(392.0, 0.0, 0.16, 0.16),
    _Note(523.25, 0.10, 0.22, 0.13),
  ],
  // Three settling notes: the thing you asked for is finished.
  VCue.done: [
    _Note(523.25, 0.0, 0.14, 0.15),
    _Note(659.25, 0.09, 0.14, 0.13),
    _Note(783.99, 0.18, 0.26, 0.11),
  ],
  // Two low notes, the second lower: look at this.
  VCue.attention: [
    _Note(349.23, 0.0, 0.18, 0.18),
    _Note(293.66, 0.16, 0.30, 0.16),
  ],
  // One short note, barely there.
  VCue.soft: [
    _Note(587.33, 0.0, 0.10, 0.10),
  ],
};

const int _sampleRate = 44100;

/// A 16-bit mono WAV of the given notes, as a data: URL.
String _wavDataUrl(List<_Note> notes) {
  final seconds = notes.fold<double>(0.0, (m, n) => math.max(m, n.start + n.length)) + 0.05;
  final frames = (seconds * _sampleRate).ceil();
  final samples = Float64List(frames);

  for (final n in notes) {
    final from = (n.start * _sampleRate).floor();
    final count = (n.length * _sampleRate).floor();
    for (var i = 0; i < count; i++) {
      final at = from + i;
      if (at >= frames) break;
      final t = i / _sampleRate;
      // A quick fade in and a long fade out, so nothing clicks and the tail
      // disappears rather than stopping.
      final progress = i / count;
      final attack = math.min(1.0, t / 0.012);
      final release = math.pow(1.0 - progress, 2.2).toDouble();
      samples[at] += math.sin(2 * math.pi * n.hz * t) * n.gain * attack * release;
    }
  }

  final bytes = Uint8List(44 + frames * 2);
  final view = ByteData.view(bytes.buffer);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes[at + i] = s.codeUnitAt(i);
    }
  }

  ascii(0, 'RIFF');
  view.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  view.setUint32(16, 16, Endian.little); // PCM header length
  view.setUint16(20, 1, Endian.little); // PCM
  view.setUint16(22, 1, Endian.little); // mono
  view.setUint32(24, _sampleRate, Endian.little);
  view.setUint32(28, _sampleRate * 2, Endian.little); // byte rate
  view.setUint16(32, 2, Endian.little); // block align
  view.setUint16(34, 16, Endian.little); // bits
  ascii(36, 'data');
  view.setUint32(40, frames * 2, Endian.little);
  for (var i = 0; i < frames; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    view.setInt16(44 + i * 2, v, Endian.little);
  }
  return 'data:audio/wav;base64,${base64Encode(bytes)}';
}

/// Built once each, then reused — the maths is cheap but not free.
final Map<VCue, String> _cache = {};

/// Off until someone turns it on. A firm that wants sound chooses it; nobody
/// is surprised by Verin in front of a client.
bool _enabled = false;

bool get cuesEnabled => _enabled;

set cuesEnabled(bool v) => _enabled = v;

DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

/// Plays a cue, if sound is on. Never more than one in two seconds: a batch of
/// evidence arriving at once should sound like one event, not a cascade.
void playCue(VCue cue) {
  if (!_enabled || !kIsWeb) return;
  final now = DateTime.now();
  if (now.difference(_last) < const Duration(seconds: 2)) return;
  _last = now;
  try {
    final url = _cache[cue] ??= _wavDataUrl(_score[cue]!);
    final a = web.document.createElement('audio') as web.HTMLAudioElement
      ..src = url
      ..volume = 0.5;
    // Browsers refuse audio until the person has interacted with the page;
    // that refusal is normal and must never surface as an error.
    a.play().toDart.catchError((Object _) => null);
  } catch (_) {
    // Sound is a courtesy. It never interrupts the work.
  }
}
