import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrcard/models/contact_card.dart';
import 'package:qrcard/screens/card_screen.dart';
import 'package:qrcard/services/card_storage.dart';

/// Eine vollstaendig gefuellte Karte - der unguenstigste Fall fuer das Layout.
const ContactCard _fullCard = ContactCard(
  firstName: 'Maximiliane',
  lastName: 'Sonnenschein-Hollerbach',
  jobTitle: 'Geschaeftsfuehrende Gesellschafterin',
  company: 'Sonnenschein Maschinenbau GmbH & Co. KG',
  street: 'Industriestrasse 145a',
  postalCode: '70173',
  city: 'Stuttgart',
  country: 'Deutschland',
  phone: '+49 711 123456-0',
  mobile: '+49 170 9876543',
  email: 'm.sonnenschein@sonnenschein-maschinenbau.de',
  website: 'sonnenschein-maschinenbau.de',
);

/// Geraetegroessen in logischen Pixeln (klein bis gross, hoch und quer).
const Map<String, Size> _sizes = <String, Size>{
  'sehr kleines Geraet': Size(320, 568),
  'iPhone SE': Size(375, 667),
  'iPhone 15 Pro': Size(393, 852),
  'Pixel 8': Size(412, 915),
  'grosses Phablet': Size(430, 932),
  'Tablet hoch': Size(768, 1024),
  'Querformat': Size(852, 393),
};

Future<void> _pumpCard(
  WidgetTester tester,
  ContactCard card, {
  double textScale = 1.0,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: CardScreen(
        card: card,
        storage: CardStorage(),
        onCardChanged: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final entry in _sizes.entries) {
    testWidgets('Karte passt ohne Overflow auf ${entry.key}', (tester) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = entry.value * 3.0;
      addTearDown(tester.view.reset);

      await _pumpCard(tester, _fullCard);

      // Ein Overflow meldet sich im Test als Exception.
      expect(tester.takeException(), isNull);

      // Die Visitenkarte darf nicht scrollbar sein - alles auf einer Seite.
      expect(find.byType(Scrollable), findsNothing);

      // Die wichtigsten Angaben muessen sichtbar sein.
      expect(find.text('Maximiliane Sonnenschein-Hollerbach'), findsOneWidget);
      expect(find.text('Geschaeftsfuehrende Gesellschafterin'), findsOneWidget);
      expect(find.textContaining('SONNENSCHEIN'), findsOneWidget);
      expect(find.textContaining('Industriestrasse 145a'), findsOneWidget);
      expect(find.text('+49 711 123456-0'), findsOneWidget);
      expect(
        find.text('m.sonnenschein@sonnenschein-maschinenbau.de'),
        findsOneWidget,
      );
    });
  }

  testWidgets('Karte mit minimalen Daten rendert fehlerfrei', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await _pumpCard(
      tester,
      const ContactCard(firstName: 'Jake', lastName: 'Berg'),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Jake Berg'), findsOneWidget);
    expect(find.text('Kontaktdaten hinzufuegen'), findsOneWidget);
  });

  // Bei grosser System-Schrift darf die Karte ebenfalls nicht ueberlaufen.
  for (final entry in _sizes.entries) {
    testWidgets('Karte haelt grosse System-Schrift aus: ${entry.key}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 3.0;
      tester.view.physicalSize = entry.value * 3.0;
      addTearDown(tester.view.reset);

      await _pumpCard(tester, _fullCard, textScale: 2.0);

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsNothing);
    });
  }

  testWidgets('QR-Code oeffnet sich in der Vollbildansicht', (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await _pumpCard(tester, _fullCard);

    await tester.tap(find.bySemanticsLabel('QR-Code mit den Kontaktdaten'));
    await tester.pumpAndSettle();

    expect(find.text('Zum Scannen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
