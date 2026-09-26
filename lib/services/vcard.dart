import '../models/contact_card.dart';

/// Erzeugt den vCard-Text, der im QR-Code steckt.
///
/// Es wird bewusst vCard 3.0 verwendet: Dieses Format erkennen die
/// Standard-Kameras von Android und iOS sowie praktisch jede QR-Scanner-App,
/// sodass der Kontakt direkt gespeichert werden kann.
///
/// Das Foto wird absichtlich *nicht* in die vCard eingebettet - ein Bild
/// wuerde den QR-Code so gross machen, dass er kaum noch scannbar waere.
String buildVCard(ContactCard card) {
  final lines = <String>['BEGIN:VCARD', 'VERSION:3.0'];

  // N: Nachname;Vorname;;;
  lines.add('N:${_esc(card.lastName)};${_esc(card.firstName)};;;');

  final fullName = card.fullName.isNotEmpty ? card.fullName : card.company;
  if (fullName.isNotEmpty) lines.add('FN:${_esc(fullName)}');
  if (card.company.isNotEmpty) lines.add('ORG:${_esc(card.company)}');
  if (card.jobTitle.isNotEmpty) lines.add('TITLE:${_esc(card.jobTitle)}');
  if (card.phone.isNotEmpty) {
    lines.add('TEL;TYPE=WORK,VOICE:${_esc(card.phone)}');
  }
  if (card.mobile.isNotEmpty) {
    lines.add('TEL;TYPE=CELL,VOICE:${_esc(card.mobile)}');
  }
  if (card.email.isNotEmpty) {
    // Bewusst TYPE=WORK statt PREF/INTERNET: Scanner zeigen den TYPE als Label
    // an, und "PREF" bzw. "INTERNET" sieht dort unschoen aus.
    lines.add('EMAIL;TYPE=WORK:${_esc(card.email)}');
  }
  if (card.website.isNotEmpty) {
    lines.add('URL:${_esc(_withScheme(card.website))}');
  }

  // ADR: Postfach;Zusatz;Strasse;Ort;Region;PLZ;Land
  final hasAddress = [
    card.street,
    card.postalCode,
    card.city,
    card.country,
  ].any((p) => p.isNotEmpty);
  if (hasAddress) {
    lines.add(
      'ADR;TYPE=WORK:;;${_esc(card.street)};${_esc(card.city)};;'
      '${_esc(card.postalCode)};${_esc(card.country)}',
    );
  }

  lines.add('END:VCARD');

  // vCard verlangt CRLF als Zeilenende.
  return lines.join('\r\n');
}

/// Maskiert die in vCard reservierten Zeichen (RFC 6350, Abschnitt 3.4).
String _esc(String value) => value
    .trim()
    .replaceAll(r'\', r'\\')
    .replaceAll(';', r'\;')
    .replaceAll(',', r'\,')
    .replaceAll('\r\n', r'\n')
    .replaceAll('\n', r'\n')
    .replaceAll('\r', r'\n');

/// Ergaenzt "https://", damit die URL auch beim Scannen anklickbar ist.
String _withScheme(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }
  return 'https://$trimmed';
}

/// Die Website als aufrufbare URL (fuer den Tap auf die Detailzeile).
String websiteUrl(String website) => _withScheme(website);
