// The card a firm sends its client: where to send things, in English or
// Spanish, with a short "what to send" note for the matter's practice.

import '/backend/backend.dart';

import '../data/model.dart';

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
    'Letters and notices you receive, proof of where you live and work, photos and messages that show your relationships, and any receipts.',
    'Cartas y avisos que reciba, comprobantes de dónde vive y trabaja, fotos y mensajes que muestren sus relaciones, y cualquier recibo.',
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
