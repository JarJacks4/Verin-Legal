// Verin Legal — Practice tab (guide §8): Clio connection, matter link, push
// the exported record into Clio, and the sync log.

import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../record_ext.dart';
import '../sheets/clio_link_sheet.dart';
import '../verin_api.dart';
import '../verin_config.dart';
import '../verin_format.dart';
import '../verin_ui.dart';

/// Live Clio connection status for the current firm (written only by the
/// Clio Cloud Functions).
Stream<Map<String, dynamic>> firmIntegrationStatus() {
  return FirebaseFirestore.instance
      .collection('integrationStatus')
      .doc(currentFirmId())
      .snapshots()
      .map((s) => s.data() ?? <String, dynamic>{});
}

/// Starts the Clio OAuth flow in a new browser tab.
Future<void> connectClio(BuildContext context) async {
  try {
    final url = await VerinApi.clioAuthStart();
    await launchURL(url);
    if (context.mounted) {
      showVerinSnack(context, 'Finish signing in to Clio in the new tab. This page updates by itself once you\'re connected.');
    }
  } on VerinApiException catch (e) {
    if (context.mounted) showVerinSnack(context, e.message, error: true);
  }
}

class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key, required this.matter});

  final MattersRecord matter;

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  bool _pushing = false;

  Future<void> _pushRecord() async {
    setState(() => _pushing = true);
    try {
      final export = await VerinApi.exportMatterRecord(widget.matter.reference.id);
      final path = (export['storagePath'] ?? '').toString();
      final name = (export['fileName'] ?? '').toString();
      if (path.isEmpty) throw VerinApiException('The record export did not return a file.');
      await VerinApi.clioPushDocument(
        matterId: widget.matter.reference.id,
        storagePath: path,
        documentName: name.isEmpty ? null : name,
      );
      if (mounted) showVerinSnack(context, 'Record uploaded to Clio.');
    } on VerinApiException catch (e) {
      if (mounted) showVerinSnack(context, 'Push to Clio failed: ${e.message}', error: true);
    } finally {
      if (mounted) setState(() => _pushing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final m = widget.matter;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Practice management', style: VerinText.heading(context)),
          const SizedBox(height: 4.0),
          Text(
            'Finished records and exhibit sets appear inside your practice management system.',
            style: VerinText.bodyMuted(context),
          ),
          const SizedBox(height: 32.0),
          StreamBuilder<Map<String, dynamic>>(
            stream: firmIntegrationStatus(),
            builder: (context, snap) {
              final status = snap.data ?? const <String, dynamic>{};
              final firmConnected = status['clioConnected'] == true;
              final clioUser = (status['clioUserName'] ?? '').toString();
              return _ProviderCard(
                icon: Icons.business_center,
                iconColor: t.primary,
                name: 'Clio Manage',
                subtitle: !firmConnected
                    ? 'Not connected'
                    : m.isClioLinked
                        ? 'Matched to ${m.clioMatterDisplayNumber.isNotEmpty ? m.clioMatterDisplayNumber : 'Clio matter ${m.clioMatterRef}'} (${orDash(m.title)})'
                        : 'Connected${clioUser.isNotEmpty ? ' as $clioUser' : ''} · this matter isn\'t linked yet',
                pill: firmConnected && m.clioSyncedAt != null
                    ? VerinTag(label: 'In Clio', icon: Icons.check_circle, background: t.success, foreground: Colors.white)
                    : firmConnected
                        ? VerinTag(label: 'Connected', background: t.secondary10, foreground: t.secondary)
                        : VerinTag(label: 'Not connected', background: t.alternate, foreground: t.secondaryText),
                body: !snap.hasData
                    ? const VerinLoading()
                    : !firmConnected
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect your firm\'s Clio account once, then link each Verin matter to its Clio matter. '
                                'Exported records are uploaded to that matter\'s Documents.',
                                style: VerinText.small(context),
                              ),
                              const SizedBox(height: 16.0),
                              VerinButton(
                                label: 'Connect Clio',
                                icon: Icons.link,
                                variant: VerinButtonVariant.primary,
                                onPressed: () => connectClio(context),
                              ),
                            ],
                          )
                        : !m.isClioLinked
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pick the Clio matter this record belongs to.',
                                    style: VerinText.small(context),
                                  ),
                                  const SizedBox(height: 16.0),
                                  VerinButton(
                                    label: 'Link to a Clio matter',
                                    icon: Icons.search_rounded,
                                    variant: VerinButtonVariant.primary,
                                    onPressed: () => showVerinSheet(context, ClioLinkSheet(matter: m)),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _SyncLog(matter: m),
                                  const SizedBox(height: 16.0),
                                  Wrap(
                                    spacing: 12.0,
                                    runSpacing: 12.0,
                                    children: [
                                      VerinButton(
                                        label: _pushing ? 'Uploading to Clio…' : 'Push record to Clio',
                                        icon: Icons.cloud_upload_rounded,
                                        variant: VerinButtonVariant.secondary,
                                        loading: _pushing,
                                        onPressed: _pushing ? null : _pushRecord,
                                      ),
                                      if (m.clioMatterUrl.isNotEmpty)
                                        VerinButton(
                                          label: 'View in Clio',
                                          icon: Icons.open_in_new,
                                          onPressed: () => launchURL(m.clioMatterUrl),
                                        ),
                                      VerinButton(
                                        label: 'Change link',
                                        icon: Icons.swap_horiz_rounded,
                                        variant: VerinButtonVariant.ghost,
                                        onPressed: () => showVerinSheet(context, ClioLinkSheet(matter: m)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
              );
            },
          ),
          const SizedBox(height: 16.0),
          _ProviderCard(
            icon: Icons.business,
            iconColor: t.secondaryText,
            name: 'MyCase',
            subtitle: 'Not connected',
            pill: VerinTag(label: 'Coming soon', background: t.alternate, foreground: t.secondaryText),
            body: Text(
              'MyCase API access needs partner approval from MyCase before it can be connected.',
              style: VerinText.small(context),
            ),
          ),
          const SizedBox(height: 16.0),
          _ProviderCard(
            icon: Icons.bolt,
            iconColor: t.secondaryText,
            name: 'Smokeball',
            subtitle: 'Not connected',
            pill: VerinTag(label: 'Coming soon', background: t.alternate, foreground: t.secondaryText),
            body: Text(
              'Smokeball support is planned after Clio.',
              style: VerinText.small(context),
            ),
          ),
          const SizedBox(height: 24.0),
          VerinCard(
            color: t.secondaryBackground30,
            child: Text(
              'Each push uploads a newly generated record; earlier uploads stay in Clio. Any failure is shown in the '
              'sync log — a write-back that fails silently is a trust incident, not a bug.',
              style: VerinText.small(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.subtitle,
    required this.pill,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String name;
  final String subtitle;
  final Widget pill;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return VerinCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: t.secondaryBackground,
                  borderRadius: BorderRadius.circular(6.0),
                  border: Border.all(color: t.alternate),
                ),
                child: Icon(icon, color: iconColor, size: 24.0),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: VerinText.title(context)),
                    Text(subtitle, style: VerinText.mono(context)),
                  ],
                ),
              ),
              pill,
            ],
          ),
          const SizedBox(height: 16.0),
          body,
        ],
      ),
    );
  }
}

class _SyncLog extends StatelessWidget {
  const _SyncLog({required this.matter});

  final MattersRecord matter;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    return StreamBuilder<List<ClioSyncLogRecord>>(
      stream: queryClioSyncLogRecord(
        queryBuilder: (q) => q.where('matterID', isEqualTo: matter.reference).orderBy('pushedAt', descending: true),
        limit: 10,
      ),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text('Sync log unavailable: ${snap.error}', style: VerinText.small(context, color: t.error));
        }
        if (!snap.hasData) return const VerinLoading();
        final rows = snap.data!;
        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(color: const Color(0x4DF1EFEA), borderRadius: BorderRadius.circular(6.0)),
          child: rows.isEmpty
              ? Text('Nothing pushed to Clio yet.', style: VerinText.small(context))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final r in rows)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              r.status == 'Synced' ? Icons.check_circle_outline : Icons.error_outline,
                              size: 16.0,
                              color: r.status == 'Synced' ? t.success : t.error,
                            ),
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(orDash(r.documentName), style: VerinText.body(context)),
                                  if (r.status != 'Synced' && r.error.isNotEmpty)
                                    Text(r.error, style: VerinText.small(context, color: t.error)),
                                ],
                              ),
                            ),
                            Text(
                              '${r.status.isEmpty ? kDash : r.status.toLowerCase()} ${fmtRelative(r.pushedAt)}',
                              style: VerinText.mono(context, color: t.primaryText),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}
