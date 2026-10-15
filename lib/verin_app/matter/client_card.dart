// The card a firm sends its client: where to send things, in English or
// Spanish, with a short "what to send" note for the matter's practice.

import 'package:flutter/material.dart';

import '/backend/backend.dart';

import '../data/model.dart';
import '../theme/tokens.dart';
import '../widgets/atoms.dart';

enum CardLang { en, es }

String _pretty(String e164) {
  final m = RegExp(r'^\+1(\d{3})(\d{3})(\d{4})$').firstMatch(e164);
  return m == null ? e164 : '(${m[1]}) ${m[2]}-${m[3]}';
}

/// "family" | "injury" | "immigration" | "civil" | "criminal"
String practiceKey(String practice) {
  final p = practice.toLowerCase();
  if (p.contains('injury') || p.contains('accident')) return 'injury';
  if (p.contains('immigra')) return 'immigration';
  if (p.contains('criminal')) return 'criminal';
  if (p.contains('civil') || p.contains('litigation') || p.contains('contract') || p.contains('estate') || p.contains('probate')) return 'civil';
  return 'family';
}

const _whatToSend = {
  'family': (
    'Texts and emails with the other parent, photos of exchanges, school and medical notices, and anything about the schedule.',
    'Mensajes y correos con el otro padre o la otra madre, fotos de los intercambios, avisos de la escuela o del médico, y todo lo relacionado con el horario.',
  ),
  'injury': (
    'Photos of the scene and your injuries, medical bills and visit notes, messages from insurance adjusters, and anything about missed work.',
    'Fotos del lugar y de sus lesiones, facturas y notas médicas, mensajes de los ajustadores del seguro, y todo lo relacionado con el trabajo que perdió.',
  ),
  'immigration': (
    'Letters and notices you receive, documents that show where you live and work, photos and messages that show your relationships, and any receipts.',
    'Cartas y avisos que reciba, documentos que muestren dónde vive y trabaja, fotos y mensajes que muestren sus relaciones, y cualquier recibo.',
  ),
  'civil': (
    'Contracts, invoices, change orders, and texts or emails about the agreement — including ones that seem minor.',
    'Contratos, facturas, órdenes de cambio, y mensajes o correos sobre el acuerdo, incluso los que parezcan poco importantes.',
  ),
  'criminal': (
    'Texts, call logs, photos, receipts and app screenshots that show where you were and when, especially around the dates in your case.',
    'Mensajes, registros de llamadas, fotos, recibos y capturas de aplicaciones que muestren dónde estaba y cuándo, sobre todo cerca de las fechas de su caso.',
  ),
};

String clientInstructions(MattersRecord matter, CardLang lang) {
  final es = lang == CardLang.es;
  final what = _whatToSend[practiceKey(matterPractice(matter))]!;
  final lines = <String>[es ? 'Cómo enviar pruebas para su caso' : 'How to send evidence for your case', ''];
  if (matter.emailAddress.isNotEmpty) {
    lines.add(es
        ? 'Correo: reenvíe mensajes, fotos, capturas de pantalla o documentos a ${matter.emailAddress}'
        : 'Email: forward messages, photos, screenshots or documents to ${matter.emailAddress}');
  }
  if (matter.smsNumber.isNotEmpty) {
    lines.add(es
        ? 'Texto: envíe fotos o capturas de pantalla al ${_pretty(matter.smsNumber)} desde su propio teléfono'
        : 'Text: send photos or screenshots to ${_pretty(matter.smsNumber)} from your own phone');
    if (matter.snapshotData['whatsapp'] == true) {
      lines.add(es
          ? 'WhatsApp: también puede enviarlas por WhatsApp al mismo número'
          : 'WhatsApp: you can also send them on WhatsApp to the same number');
    }
  }
  lines.addAll([
    '',
    es ? 'Qué enviar: ${what.$2}' : 'What to send: ${what.$1}',
    '',
    es
        ? 'Envíe las cosas tal como las tiene, sin cambiarles el nombre ni editarlas. Todo llega de forma segura a su abogado.'
        : 'Send things exactly as you have them — no need to rename or edit. Everything is received securely for your attorney.',
    es
        ? 'Este número y este correo no se revisan las 24 horas. En una emergencia, llame al 911.'
        : 'This number and address are not watched around the clock. In an emergency, call 911.',
  ]);
  return lines.join('\n');
}

// ---------------------------------------------------------------------------

/// The card as the client sees it.
///
/// The website shows firms a sample of this; the app showed only a Copy
/// button, so nobody could tell what they were about to hand over. This is the
/// same card, filled in with the matter's own address and number, and it is
/// what the Copy buttons put on the clipboard.
class ClientCardPreview extends StatefulWidget {
  const ClientCardPreview({super.key, required this.matter, required this.firmName});

  final MattersRecord matter;
  final String firmName;

  @override
  State<ClientCardPreview> createState() => _ClientCardPreviewState();
}

class _ClientCardPreviewState extends State<ClientCardPreview> {
  bool _es = false;

  @override
  Widget build(BuildContext context) {
    final c = VC.of(context);
    final m = widget.matter;
    final what = _whatToSend[practiceKey(matterPractice(m))]!;
    final firm = widget.firmName.trim().isEmpty ? 'Your law firm' : widget.firmName.trim();

    Widget line(IconData icon, String value, String copyLabel) => Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            children: [
              Icon(icon, size: 15.0, color: c.teal),
              const SizedBox(width: 10.0),
              Expanded(child: SelectableText(value, style: VT.mono(context, size: 13.0, color: c.teal))),
              VIconButton(
                icon: Icons.content_copy,
                size: 13.0,
                tooltip: 'Copy',
                onPressed: () => copyToClipboard(context, value, what: '$copyLabel copied'),
              ),
            ],
          ),
        );

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(_es ? 'TARJETA PARA EL CLIENTE' : 'CLIENT CARD', style: VT.eyebrow(context, size: 10.0)),
          const SizedBox(height: 8.0),
          Text(firm, style: VT.h3(context, size: 18.0)),
          const SizedBox(height: 6.0),
          Text(
            _es
                ? 'Envíe cualquier cosa sobre su caso. Reenvíe correos y mande fotos, capturas de pantalla y videos por mensaje de texto.'
                : 'Send anything about your case. Forward emails and text photos, screenshots and videos.',
            style: VT.muted(context, size: 13.0),
          ),
          if (m.emailAddress.isNotEmpty) line(Icons.mail_outline_rounded, m.emailAddress, 'Address'),
          if (m.smsNumber.isNotEmpty) line(Icons.chat_bubble_outline_rounded, _pretty(m.smsNumber), 'Number'),
          if (m.snapshotData['whatsapp'] == true)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                _es ? 'También por WhatsApp al mismo número.' : 'WhatsApp works on the same number.',
                style: VT.muted(context, size: 11.5),
              ),
            ),
          const SizedBox(height: 14.0),
          Text(_es ? 'QUÉ ENVIAR' : 'WHAT TO SEND', style: VT.eyebrow(context, size: 10.0)),
          const SizedBox(height: 4.0),
          Text(_es ? what.$2 : what.$1, style: VT.body(context, size: 12.5)),
          const SizedBox(height: 14.0),
          Row(
            children: [
              // The site offers the card in Spanish; so does this, and the
              // Copy button follows whichever language is showing.
              VHover(
                onTap: () => setState(() => _es = !_es),
                builder: (context, hovered) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  decoration: BoxDecoration(
                    color: hovered ? c.panel : c.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _es ? 'Show in English' : 'También en español',
                    style: VT.body(context, size: 11.5, weight: FontWeight.w600),
                  ),
                ),
              ),
              const Spacer(),
              VButton(
                label: _es ? 'Copiar la tarjeta' : 'Copy this card',
                icon: Icons.assignment_outlined,
                size: VButtonSize.sm,
                onPressed: () => copyToClipboard(
                  context,
                  clientInstructions(m, _es ? CardLang.es : CardLang.en),
                  what: _es ? 'Instrucciones copiadas' : 'Client instructions copied',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            _es
                ? 'Verin nunca contacta a su cliente. Las preguntas del cliente son para usted.'
                : 'Verin never contacts your client. Client questions stay with you.',
            style: VT.muted(context, size: 11.0),
          ),
        ],
      ),
    );
  }
}
