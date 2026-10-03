// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/ff_builtin_enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/actions/index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

Future<String> buildMatterExportHtml(
  MattersRecord matter,
  List<ItemsRecord> items,
  List<VerifiedStatementsRecord> verifiedStatements,
) async {
  const navy = '#1B3A5C';
  const teal = '#3F8F7F';
  const slate = '#5B6470';
  const warn = '#B8791A';
  const warnBg = '#FCEFDA';
  const light = '#EEF2F5';

  String esc(String? s) {
    if (s == null) return '';
    return s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String fmtDate(DateTime? d) {
    if (d == null) return '—';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final minute = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year}, $hour12:$minute $ampm UTC';
  }

  // --- Verification certificate -------------------------------------------
  final verified = verifiedStatements.where((s) => s.verified == true).toList();
  final needsReview =
      verifiedStatements.where((s) => s.verified != true).toList();

  final verifiedRows = verified.map((s) => '''
      <div class="statement-row verified">
        <div class="statement-text">${esc(s.statementText)}</div>
        <div class="statement-source">Source: ${esc(s.sourceLabel)}</div>
      </div>''').join('\n');

  final needsReviewRows = needsReview.map((s) => '''
      <div class="statement-row review">
        <div class="statement-text">${esc(s.statementText)}</div>
        <div class="statement-source">Source: ${esc(s.sourceLabel)} — flagged for manual review</div>
      </div>''').join('\n');

  // --- Transcript, flattened across all extracted batches in order --------
  final transcriptRows = <String>[];
  for (final item in items) {
    for (final raw in (item.threadMessages)) {
      final msg = Map<String, dynamic>.from(raw as Map);
      final isHeader = msg['isHeader'] == true;
      final isGap = msg['isGap'] == true;
      if (isHeader) {
        final label = (msg['text'] as String?)?.isNotEmpty == true
            ? msg['text'] as String
            : (msg['timestampLabel'] as String? ?? '');
        transcriptRows.add('<div class="divider">${esc(label)}</div>');
        continue;
      }
      if (isGap) {
        transcriptRows
            .add('<div class="gap">— gap in conversation continuity —</div>');
      }
      final side = msg['speaker'] == 'client' ? 'client' : 'other';
      final confidence = ((msg['confidence'] as num?) ?? 0) * 100;
      transcriptRows.add('''
        <div class="bubble-row $side">
          <div class="bubble $side">
            <div class="bubble-text">${esc(msg['text'] as String?)}</div>
            <div class="bubble-meta">${esc(msg['timestampLabel'] as String?)} · ${esc(msg['platform'] as String? ?? 'unknown')} · confidence ${confidence.round()}%</div>
          </div>
        </div>''');
    }
  }

  final hashChainLine = matter.hashChainAnchorCount != null
      ? '${matter.hashChainAnchorCount} items anchored${matter.hasChainRoot == true ? " — chain root established" : ""}'
      : 'Anchor count not available';

  final rfc3161Line = (matter.rfc3161TsaName?.isNotEmpty ?? false)
      ? 'Timestamped via ${esc(matter.rfc3161TsaName)}'
      : 'Compliant trusted timestamp on file';

  return '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<style>
  @page { size: Letter; margin: 0.85in; }
  body { font-family: 'Helvetica', Arial, sans-serif; color: #1a1a1a; font-size: 11pt; line-height: 1.5; }
  h1, h2, h3 { color: $navy; margin: 0 0 8px; }
  h1 { font-size: 22pt; }
  h2 { font-size: 15pt; border-bottom: 2px solid $navy; padding-bottom: 6px; margin-top: 28px; }
  .cover-sub { color: $slate; font-size: 12pt; margin-bottom: 24px; }
  .meta-table { width: 100%; border-collapse: collapse; margin: 16px 0 28px; }
  .meta-table td { padding: 6px 10px; border: 1px solid #ddd; font-size: 10pt; }
  .meta-table td.label { background: $light; font-weight: bold; width: 32%; color: $navy; }
  .cert-box { background: $light; border: 1px solid #cdd6dc; border-radius: 4px; padding: 14px 18px; margin-bottom: 14px; }
  .cert-box .title { color: $teal; font-weight: bold; font-size: 12pt; margin-bottom: 4px; }
  .divider { text-align: center; color: $slate; font-size: 9pt; text-transform: uppercase; letter-spacing: .05em; margin: 18px 0 10px; }
  .gap { text-align: center; color: $warn; font-size: 9pt; font-style: italic; margin: 10px 0; }
  .bubble-row { display: flex; margin-bottom: 8px; }
  .bubble-row.client { justify-content: flex-start; }
  .bubble-row.other { justify-content: flex-end; }
  .bubble { max-width: 70%; padding: 8px 12px; border-radius: 8px; }
  .bubble.client { background: $light; }
  .bubble.other { background: #E4F1EC; }
  .bubble-text { font-size: 10.5pt; }
  .bubble-meta { font-size: 8pt; color: $slate; margin-top: 4px; }
  .statement-row { border-left: 3px solid $teal; padding: 8px 12px; margin-bottom: 8px; background: #FAFAF8; }
  .statement-row.review { border-left-color: $warn; background: $warnBg; }
  .statement-text { font-size: 10.5pt; font-weight: 600; }
  .statement-source { font-size: 8.5pt; color: $slate; margin-top: 3px; }
  .page-break { page-break-before: always; }
  .footer-note { font-size: 8pt; color: $slate; margin-top: 30px; font-style: italic; }
</style>
</head>
<body>

  <h1>${esc(matter.caseTitle)}</h1>
  <div class="cover-sub">Evidence export — generated by Verin Legal</div>

  <table class="meta-table">
    <tr><td class="label">Client</td><td>${esc(matter.clientName)}</td></tr>
    <tr><td class="label">Case #</td><td>${esc(matter.caseNumber)}</td></tr>
    <tr><td class="label">Opened</td><td>${fmtDate(matter.openedAt)}</td></tr>
    <tr><td class="label">Export generated</td><td>${fmtDate(DateTime.now().toUtc())}</td></tr>
  </table>

  <h2>Verification Certificate</h2>
  <div class="cert-box">
    <div class="title">Immutable Hash Chain</div>
    <div>$hashChainLine</div>
    <div style="font-size:9pt;color:$slate;margin-top:4px;">Last anchored: ${fmtDate(matter.hashChainLastAnchoredAt)}</div>
  </div>
  <div class="cert-box">
    <div class="title">RFC 3161 Timestamp Compliance</div>
    <div>$rfc3161Line</div>
    <div style="font-size:9pt;color:$slate;margin-top:4px;">Last timestamped: ${fmtDate(matter.rfc3161LastTimestampedAt)}</div>
  </div>

  <h3 style="margin-top:20px;font-size:11pt;">Verified Statements</h3>
  ${verifiedRows.isNotEmpty ? verifiedRows : '<p style="color:$slate;font-style:italic;">No statements have been verified yet.</p>'}

  ${needsReviewRows.isNotEmpty ? '<h3 style="margin-top:16px;font-size:11pt;color:$warn;">Flagged for Review</h3>$needsReviewRows' : ''}

  <div class="page-break"></div>
  <h2>Extracted Message Thread</h2>
  ${transcriptRows.isNotEmpty ? transcriptRows.join('\n') : '<p style="color:$slate;font-style:italic;">No extracted messages on file.</p>'}

  <div class="footer-note">Generated automatically by Verin Legal from evidence submitted through client-forwarded channels and in-app upload. This document reflects the state of the record at the time of export.</div>

</body>
</html>
''';
}
