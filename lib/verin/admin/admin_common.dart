// Verin Legal — shared pieces for the Admin Portal pages (guide §12):
// the role gate, the firm-account / receipts stream builders, record-lag math,
// plan formatting, and the plan card shown on both Billing and Program.
//
// Single-tenant for now: `users` docs have no link to a firmAccount, so the
// admin pages read the first firmAccount document and scope Matters by
// currentFirmId().

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

import '../verin_format.dart';
import '../verin_ui.dart';

// ---------------------------------------------------------------------------
// Roles
// ---------------------------------------------------------------------------

/// Admin console access: users.role is "admin" or "owner" (any casing).
bool isAdminRole(String? role) {
  final r = (role ?? '').trim().toLowerCase();
  return r == 'admin' || r == 'owner';
}

/// Shows [child] only to admins/owners; everyone else gets an empty state
/// with a way back to the Matters list. Listens to the signed-in user's own
/// users doc so a role change applies without a reload.
class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({super.key, required this.child});

  final Widget child;

  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  Stream<UsersRecord>? _userStream;

  /// Created once, as soon as there is a signed-in user.
  Stream<UsersRecord>? _streamForCurrentUser() {
    if (_userStream == null) {
      final ref = currentUserReference;
      if (ref != null) _userStream = UsersRecord.getDocument(ref);
    }
    return _userStream;
  }

  @override
  Widget build(BuildContext context) {
    final stream = _streamForCurrentUser();
    if (stream == null) {
      // Auth not restored yet: rebuild when the signed-in user doc arrives.
      return AuthUserStreamWidget(
        builder: (context) {
          final user = currentUserDocument;
          return (user != null && isAdminRole(user.role))
              ? widget.child
              : const AdminNoAccess();
        },
      );
    }
    return StreamBuilder<UsersRecord>(
      stream: stream,
      builder: (context, snapshot) {
        final user = snapshot.data ?? currentUserDocument;
        if (user == null) {
          if (snapshot.hasError ||
              snapshot.connectionState == ConnectionState.done) {
            return const AdminNoAccess();
          }
          return Container(
            color: FlutterFlowTheme.of(context).primaryBackground,
            child: const VerinLoading(),
          );
        }
        return isAdminRole(user.role) ? widget.child : const AdminNoAccess();
      },
    );
  }
}

class AdminNoAccess extends StatelessWidget {
  const AdminNoAccess({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FlutterFlowTheme.of(context).primaryBackground,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440.0),
        child: VerinCard(
          child: VerinEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Admin access required',
            message:
                'The admin console is only available to firm admins and owners. Ask an admin on your team to update your role.',
            action: VerinButton(
              label: 'Back to matters',
              icon: Icons.arrow_back_rounded,
              variant: VerinButtonVariant.primary,
              onPressed: () => context.goNamed('MattersList'),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data
// ---------------------------------------------------------------------------

/// The firm's account record (first firmAccount doc), or null if none exists.
Stream<FirmAccountRecord?> firmAccountStream() =>
    queryFirmAccountRecord(singleRecord: true)
        .map((list) => list.isEmpty ? null : list.first);

/// Rebuilds with the firm's account record (null while loading or missing).
class FirmAccountBuilder extends StatefulWidget {
  const FirmAccountBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, FirmAccountRecord? firm) builder;

  @override
  State<FirmAccountBuilder> createState() => _FirmAccountBuilderState();
}

class _FirmAccountBuilderState extends State<FirmAccountBuilder> {
  late final Stream<FirmAccountRecord?> _stream = firmAccountStream();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<FirmAccountRecord?>(
      stream: _stream,
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }
}

/// Rebuilds with every Receipts doc (null while loading). Receipts carry no
/// firm field; the app is single-tenant, so this is the firm's evidence.
class AllReceiptsBuilder extends StatefulWidget {
  const AllReceiptsBuilder({super.key, required this.builder});

  final Widget Function(BuildContext context, List<ReceiptsRecord>? receipts)
      builder;

  @override
  State<AllReceiptsBuilder> createState() => _AllReceiptsBuilderState();
}

class _AllReceiptsBuilderState extends State<AllReceiptsBuilder> {
  late final Stream<List<ReceiptsRecord>> _stream = queryReceiptsRecord();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReceiptsRecord>>(
      stream: _stream,
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }
}

// ---------------------------------------------------------------------------
// Record lag
// ---------------------------------------------------------------------------

/// Firm-wide median of (receivedAt − resolvedDate) in days over receipts that
/// have a resolvedDate; null when none do. Same math as the matter Integrity
/// tab (negative gaps, i.e. bad dates, are skipped).
double? firmMedianRecordLagDays(List<ReceiptsRecord> receipts) {
  final gaps = <num>[];
  for (final r in receipts) {
    final resolved = r.resolvedDate;
    final received = r.receivedAt;
    if (resolved == null || received == null) continue;
    final days = received.difference(resolved).inHours / 24.0;
    if (days >= 0) gaps.add(days);
  }
  return median(gaps);
}

/// "1.2d" / "33d" for the stat tile; '—' when unknown.
String fmtLagShort(double? days) {
  if (days == null) return kDash;
  return days < 10 ? '${days.toStringAsFixed(1)}d' : '${days.round()}d';
}

/// "1.2 days" / "33 days"; '—' when unknown.
String fmtLagLong(double? days) {
  if (days == null) return kDash;
  return days < 10
      ? '${days.toStringAsFixed(1)} days'
      : pluralize(days.round(), 'day');
}

// ---------------------------------------------------------------------------
// Plan / greeting formatting
// ---------------------------------------------------------------------------

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  return 'Good evening';
}

/// First word of the display name, else the part of the email before '@'.
String firstNameOf(String displayName, {String email = ''}) {
  final parts = displayName.trim().split(RegExp(r'\s+'));
  if (parts.isNotEmpty && parts.first.isNotEmpty) return parts.first;
  final at = email.indexOf('@');
  return at > 0 ? email.substring(0, at) : '';
}

/// 1 during the first year after [memberSince], 2 during the second, ...
int? planYear(DateTime? memberSince, {DateTime? now}) {
  if (memberSince == null) return null;
  final n = now ?? DateTime.now();
  var years = n.year - memberSince.year;
  if (n.month < memberSince.month ||
      (n.month == memberSince.month && n.day < memberSince.day)) {
    years -= 1;
  }
  return years < 0 ? 1 : years + 1;
}

String fmtPlanYear(DateTime? memberSince) {
  final y = planYear(memberSince);
  return y == null ? kDash : 'Year $y';
}

String fmtCents(int cents) =>
    NumberFormat.simpleCurrency(name: 'USD').format(cents / 100.0);

/// "past_due" -> "Past due".
String humanizeStatus(String s) {
  final t = s.trim().replaceAll('_', ' ').replaceAll('-', ' ');
  if (t.isEmpty) return '';
  return '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
}

// ---------------------------------------------------------------------------
// Text style helper (same fonts the FlutterFlow pages use)
// ---------------------------------------------------------------------------

enum AdminFont { plex, spectral, grotesk, roboto, inter }

TextStyle adminText(
  TextStyle base,
  AdminFont font, {
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? lineHeight,
}) {
  final w = fontWeight ?? base.fontWeight;
  final s = base.fontStyle;
  TextStyle f = GoogleFonts.ibmPlexSans(fontWeight: w, fontStyle: s);
  if (font == AdminFont.spectral) {
    f = GoogleFonts.spectral(fontWeight: w, fontStyle: s);
  } else if (font == AdminFont.grotesk) {
    f = GoogleFonts.spaceGrotesk(fontWeight: w, fontStyle: s);
  } else if (font == AdminFont.roboto) {
    f = GoogleFonts.roboto(fontWeight: w, fontStyle: s);
  } else if (font == AdminFont.inter) {
    f = GoogleFonts.inter(fontWeight: w, fontStyle: s);
  }
  return base.override(
    font: f,
    color: color,
    fontSize: fontSize,
    letterSpacing: 0.0,
    fontWeight: w,
    fontStyle: s,
    lineHeight: lineHeight,
  );
}

// ---------------------------------------------------------------------------
// Plan card (Billing §12c and Program §12e share the same bindings)
// ---------------------------------------------------------------------------

class AdminPlanCard extends StatelessWidget {
  const AdminPlanCard({super.key, required this.firm, this.width = 640.0});

  final FirmAccountRecord? firm;
  final double width;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final f = firm;

    final planName = orDash(f?.planName);
    String price = kDash;
    if (f != null && f.hasPlanPriceCents()) {
      final annual = f.planName.toLowerCase().contains('annual');
      price = annual
          ? '${fmtCents(f.planPriceCents)} / per year'
          : fmtCents(f.planPriceCents);
    }
    final renews = f?.planRenewsAt;
    final renewal = 'Next renewal: ${renews == null ? kDash : fmtDate(renews)}';
    final storage = orDash(f?.storageTier);
    final seats =
        (f != null && f.seatLimit > 0) ? 'Up to ${f.seatLimit}' : kDash;
    final integrations = (f == null || f.connectedIntegrations.isEmpty)
        ? kDash
        : f.connectedIntegrations.join(' · ');

    final labelStyle =
        adminText(t.bodySmall, AdminFont.plex, color: t.primaryBackground, lineHeight: 1.5);
    final valueStyle =
        adminText(t.bodySmall, AdminFont.plex, color: const Color(0xC1E2E0DB), lineHeight: 1.5);
    final bulletStyle =
        adminText(t.bodyMedium, AdminFont.plex, color: t.onSurface, lineHeight: 1.5);

    Widget stat(String label, String value) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4.0),
            Text(value, style: valueStyle, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        );

    return Row(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: const Color(0xFF093F49),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: t.alternate, width: 1.0),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          planName,
                          overflow: TextOverflow.ellipsis,
                          style: adminText(t.titleLarge, AdminFont.plex,
                              color: t.alternate,
                              fontWeight: FontWeight.bold,
                              lineHeight: 1.4),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      AdminPlanStatusLabel(status: f?.planStatus ?? ''),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    price,
                    style: adminText(t.headlineSmall, AdminFont.spectral,
                        color: t.primaryBackground, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    renewal,
                    style: adminText(t.labelMedium, AdminFont.plex,
                        color: const Color(0xAEE2E0DB), lineHeight: 1.4),
                  ),
                  const SizedBox(height: 8.0),
                  Divider(height: 16.0, thickness: 1.0, color: t.alternate),
                  const SizedBox(height: 8.0),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: stat('Matters', storage)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('•', style: bulletStyle),
                      ),
                      Expanded(child: stat('Team Stats', seats)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('•', style: bulletStyle),
                      ),
                      Expanded(flex: 2, child: stat('Integrations', integrations)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Plan status as a plain label (it used to be a button that did nothing).
class AdminPlanStatusLabel extends StatelessWidget {
  const AdminPlanStatusLabel({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final t = FlutterFlowTheme.of(context);
    final s = status.trim().toLowerCase();
    final isActive = s == 'active';
    final label = s.isEmpty ? kDash : humanizeStatus(status);
    final bg = isActive
        ? const Color(0x4D2F7D5B)
        : (s.isEmpty ? const Color(0x26FFFFFF) : const Color(0x4DC98D26));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(25.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (s.isNotEmpty) ...[
            Icon(
              isActive ? Icons.check : Icons.info_outline_rounded,
              size: 15.0,
              color: Colors.white,
            ),
            const SizedBox(width: 6.0),
          ],
          Text(
            label,
            style: adminText(t.titleSmall, AdminFont.plex, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
