// Verin Legal — "Upload screenshots" card: the in-app AI Agent (guide §14).
//
// Each picked image goes to the ingestScreenshot Cloud Function, which stores
// the original bytes, hashes them, appends the receipt to this matter's hash
// chain, and has Claude read the messages. The receipt shows up on the
// Reciepts and Thread tabs by itself (they stream Firestore); this card only
// reports progress and failures for what was uploaded in this session.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';

import '../screenshot_picker.dart';
import '../verin_api.dart';
import '../verin_config.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

enum _UploadState { uploading, extracted, noConversation, failed }

class _Upload {
  _Upload(this.name);
  final String name;
  _UploadState state = _UploadState.uploading;
  String detail = '';
  String receiptId = '';
}

class ScreenshotUploadCard extends StatefulWidget {
  const ScreenshotUploadCard({super.key, required this.matter, this.compact = false});

  final MattersRecord matter;

  /// Compact variant for the Thread tab's left rail.
  final bool compact;

  @override
  State<ScreenshotUploadCard> createState() => _ScreenshotUploadCardState();
}

class _ScreenshotUploadCardState extends State<ScreenshotUploadCard> {
  final List<_Upload> _uploads = [];
  String _clientSide = 'right';
  bool _busy = false;

  Future<void> _pickAndUpload() async {
    List<PickedImage> files;
    try {
      files = await pickScreenshots();
    } catch (e) {
      if (mounted) showVerinSnack(context, 'Could not open the file picker: $e', error: true);
      return;
    }
    if (files.isEmpty || !mounted) return;

    setState(() => _busy = true);
    // One at a time: each upload appends to the matter's hash chain, and
    // sequential uploads keep the chain order the same as the pick order.
    for (final f in files) {
      final u = _Upload(f.name);
      setState(() => _uploads.insert(0, u));
      if (f.bytes.length > kMaxScreenshotBytes) {
        setState(() {
          u.state = _UploadState.failed;
          u.detail = 'File is ${(f.bytes.length / 1048576).toStringAsFixed(1)} MB; the limit is 7 MB.';
        });
        continue;
      }
      try {
        final r = await VerinApi.ingestScreenshot(
          matterId: widget.matter.reference.id,
          bytes: f.bytes,
          fileName: f.name,
          clientSide: _clientSide,
        );
        if (!mounted) return;
        setState(() => _applyResult(u, r));
      } on VerinApiException catch (e) {
        if (!mounted) return;
        setState(() {
          u.state = _UploadState.failed;
          u.detail = e.message;
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  void _applyResult(_Upload u, Map<String, dynamic> r) {
    u.receiptId = (r['receiptId'] ?? '').toString();
    final status = (r['status'] ?? '').toString();
    final count = r['messageCount'] is num ? (r['messageCount'] as num).toInt() : 0;
    final platform = (r['platform'] ?? '').toString();
    final dup = r['isDuplicate'] == true;
    if (status == 'extracted') {
      u.state = _UploadState.extracted;
      u.detail = '${pluralize(count, 'message')} read'
          '${platform.isNotEmpty && platform != 'Unknown' ? ' from $platform' : ''}'
          '${dup ? ' · same file was already on this matter' : ''}';
    } else if (status == 'no_conversation_detected') {
      u.state = _UploadState.noConversation;
      u.detail = 'Saved and hashed, but no conversation was found in this image.';
    } else {
      u.state = _UploadState.failed;
      final errors = r['errors'];
      final first = errors is List && errors.isNotEmpty ? errors.first.toString() : 'Extraction failed.';
      u.detail = 'Saved and hashed, but reading it failed: $first';
    }
  }

  Future<void> _retry(_Upload u) async {
    if (u.receiptId.isEmpty) return;
    setState(() {
      u.state = _UploadState.uploading;
      u.detail = 'Retrying…';
    });
    try {
      final r = await VerinApi.retryExtraction(u.receiptId, clientSide: _clientSide);
      if (!mounted) return;
      setState(() => _applyResult(u, {...r, 'receiptId': u.receiptId}));
    } on VerinApiException catch (e) {
      if (!mounted) return;
      setState(() {
        u.state = _UploadState.failed;
        u.detail = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return VerinCard(
      padding: EdgeInsets.all(widget.compact ? 16.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(color: t.secondary10, borderRadius: BorderRadius.circular(6.0)),
                child: Icon(Icons.auto_awesome_rounded, color: t.secondary, size: widget.compact ? 18.0 : 24.0),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  widget.compact ? 'Add screenshots' : 'Upload conversation screenshots',
                  style: widget.compact ? VerinText.titleSmall(context) : VerinText.title(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            widget.compact
                ? 'Hashed on arrival, then read into the thread.'
                : 'Screenshots of text, WhatsApp, iMessage or email threads. Each one is hashed and added '
                    'to this matter\'s chain the moment it arrives, then AI reads the messages into the Thread tab. '
                    'The original image is kept unchanged.',
            style: VerinText.small(context),
          ),
          const SizedBox(height: 16.0),
          Text('Client\'s messages are on the', style: VerinText.label(context)),
          const SizedBox(height: 6.0),
          Wrap(
            spacing: 8.0,
            children: [
              ChoiceChip(
                label: const Text('Right side'),
                selected: _clientSide == 'right',
                onSelected: _busy ? null : (_) => setState(() => _clientSide = 'right'),
              ),
              ChoiceChip(
                label: const Text('Left side'),
                selected: _clientSide == 'left',
                onSelected: _busy ? null : (_) => setState(() => _clientSide = 'left'),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          VerinButton(
            label: _busy ? 'Uploading…' : 'Choose screenshots',
            icon: Icons.upload_file_rounded,
            variant: VerinButtonVariant.primary,
            loading: _busy,
            fullWidth: widget.compact,
            onPressed: _busy ? null : _pickAndUpload,
          ),
          if (_uploads.isNotEmpty) ...[
            const SizedBox(height: 16.0),
            for (final u in _uploads) _UploadRow(upload: u, onRetry: () => _retry(u)),
          ],
        ],
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  const _UploadRow({required this.upload, required this.onRetry});

  final _Upload upload;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    Widget leading;
    Color color;
    switch (upload.state) {
      case _UploadState.uploading:
        leading = SizedBox(
          width: 16.0,
          height: 16.0,
          child: CircularProgressIndicator(strokeWidth: 2.0, color: t.secondary),
        );
        color = t.secondaryText;
        break;
      case _UploadState.extracted:
        leading = Icon(Icons.check_circle_rounded, size: 16.0, color: t.success);
        color = t.success;
        break;
      case _UploadState.noConversation:
        leading = Icon(Icons.info_outline_rounded, size: 16.0, color: t.info);
        color = t.info;
        break;
      case _UploadState.failed:
        leading = Icon(Icons.error_outline_rounded, size: 16.0, color: t.error);
        color = t.error;
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 2.0), child: leading),
          const SizedBox(width: 8.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upload.name, style: VerinText.label(context, color: t.primaryText), overflow: TextOverflow.ellipsis),
                Text(
                  upload.state == _UploadState.uploading && upload.detail.isEmpty
                      ? 'Uploading and reading…'
                      : upload.detail,
                  style: VerinText.small(context, color: color),
                ),
              ],
            ),
          ),
          if (upload.state == _UploadState.failed && upload.receiptId.isNotEmpty)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
