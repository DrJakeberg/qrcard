import 'package:flutter_test/flutter_test.dart';
import 'package:qrcard/models/contact_card.dart';
import 'package:qrcard/services/vcard.dart';

void main() {
  group('buildVCard', () {
    const card = ContactCard(
      firstName: 'Jake',
      lastName: 'Berg',
      jobTitle: 'Geschaeftsfuehrer',
      company: 'Muster GmbH',
      street: 'Musterweg 1',
      postalCode: '12345',
      city: 'Berlin',
      country: 'Deutschland',
      phone: '+49 30 123456',
      mobile: '+49 170 1234567',
      email: 'jake@muster.de',
      website: 'muster.de',
    );

    test('beginnt und endet mit den vCard-Markern', () {
      final vcard = buildVCard(card);
      expect(vcard.startsWith('BEGIN:VCARD\r\nVERSION:3.0'), isTrue);
      expect(vcard.endsWith('END:VCARD'), isTrue);
    });

    test('verwendet CRLF als Zeilenende', () {
      expect(buildVCard(card).split('\r\n').length, greaterThan(5));
    });

    test('enthaelt Name, Position und Firma', () {
      final vcard = buildVCard(card);
      expect(vcard, contains('N:Berg;Jake;;;'));
      expect(vcard, contains('FN:Jake Berg'));
      expect(vcard, contains('TITLE:Geschaeftsfuehrer'));
      expect(vcard, contains('ORG:Muster GmbH'));
    });

    test('enthaelt die Firmenanschrift in der richtigen Feldreihenfolge', () {
      expect(
        buildVCard(card),
        contains('ADR;TYPE=WORK:;;Musterweg 1;Berlin;;12345;Deutschland'),
      );
    });

    test('nutzt fuer die E-Mail ein sauberes Label', () {
      final vcard = buildVCard(card);
      expect(vcard, contains('EMAIL;TYPE=WORK:jake@muster.de'));
      // PREF/INTERNET tauchen bei manchen Scannern als Label auf.
      expect(vcard, isNot(contains('PREF')));
      expect(vcard, isNot(contains('INTERNET')));
    });

    test('unterscheidet Festnetz und Mobil', () {
      final vcard = buildVCard(card);
      expect(vcard, contains('TEL;TYPE=WORK,VOICE:+49 30 123456'));
      expect(vcard, contains('TEL;TYPE=CELL,VOICE:+49 170 1234567'));
    });

    test('ergaenzt fehlendes https:// bei der Website', () {
      expect(buildVCard(card), contains('URL:https://muster.de'));
      expect(
        buildVCard(card.copyWith(website: 'http://muster.de')),
        contains('URL:http://muster.de'),
      );
    });

    test('laesst leere Felder weg', () {
      const minimal = ContactCard(firstName: 'Jake', lastName: 'Berg');
      final vcard = buildVCard(minimal);
      expect(vcard, isNot(contains('ORG:')));
      expect(vcard, isNot(contains('TEL')));
      expect(vcard, isNot(contains('ADR')));
    });

    test('maskiert Sonderzeichen', () {
      const tricky = ContactCard(
        firstName: 'Jake',
        lastName: 'Berg',
        company: 'Muster, Meier & Co.; GmbH',
      );
      expect(buildVCard(tricky), contains(r'ORG:Muster\, Meier & Co.\; GmbH'));
    });

    test('nutzt die Firma als FN, wenn kein Name gesetzt ist', () {
      const onlyCompany = ContactCard(company: 'Muster GmbH');
      expect(buildVCard(onlyCompany), contains('FN:Muster GmbH'));
    });
  });

  group('ContactCard', () {
    test('ueberlebt einen Speicher-/Ladezyklus', () {
      const card = ContactCard(
        firstName: 'Jake',
        lastName: 'Berg',
        company: 'Muster GmbH',
        photoPath: '/data/photo.jpg',
      );
      final restored = ContactCard.decode(card.encode());
      expect(restored.fullName, 'Jake Berg');
      expect(restored.company, 'Muster GmbH');
      expect(restored.photoPath, '/data/photo.jpg');
    });

    test('faengt defekte gespeicherte Daten ab', () {
      expect(ContactCard.decode('kein json').isEmpty, isTrue);
    });

    test('bildet Initialen und Adressblock', () {
      const card = ContactCard(
        firstName: 'Jake',
        lastName: 'Berg',
        street: 'Musterweg 1',
        postalCode: '12345',
        city: 'Berlin',
        country: 'Deutschland',
      );
      expect(card.initials, 'JB');
      expect(card.addressBlock, 'Musterweg 1\n12345 Berlin, Deutschland');
    });

    test('clearPhoto entfernt den Bildpfad', () {
      const card = ContactCard(photoPath: '/data/photo.jpg');
      expect(card.copyWith(clearPhoto: true).photoPath, isNull);
    });
  });
}
