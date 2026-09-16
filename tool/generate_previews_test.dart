import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrcard/models/contact_card.dart';
import 'package:qrcard/screens/card_screen.dart';
import 'package:qrcard/screens/qr_fullscreen.dart';
import 'package:qrcard/services/card_storage.dart';

/// Erzeugt die Vorschaubilder in docs/ (nur fuer die Dokumentation).
///
/// Liegt bewusst ausserhalb von test/, damit `flutter test` es nicht mitlaeuft:
/// Die Bilder haengen von den lokal installierten Schriften ab und wuerden auf
/// einem anderen Rechner oder auf dem CI-Runner abweichen.
///
/// Aufruf:
///   flutter test tool/generate_previews_test.dart --update-goldens
const ContactCard _demo = ContactCard(
  firstName: 'Jake',
  lastName: 'Berg',
  jobTitle: 'Geschaeftsfuehrer',
  company: 'Muster Maschinenbau GmbH',
  street: 'Industriestrasse 14',
  postalCode: '70173',
  city: 'Stuttgart',
  country: 'Deutschland',
  phone: '+49 711 123456-0',
  mobile: '+49 170 9876543',
  email: 'j.berg@muster-maschinenbau.de',
  website: 'muster-maschinenbau.de',
);

/// Laedt echte Schriften, damit die Vorschau so aussieht wie auf dem Geraet.
/// Ohne das rendert der Test-Renderer nur Platzhalter-Rechtecke.
Future<void> _loadFont(String family, String path) async {
  final file = File(path);
  if (!file.existsSync()) return;
  final bytes = file.readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

Future<void> _loadRealFonts() async {
  await _loadFont('Roboto', '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf');
  await _loadFont(
    'MaterialIcons',
    '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
}

void main() {
  testWidgets('Vorschau der Visitenkarte', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CardScreen(
          card: _demo,
          storage: CardStorage(),
          onCardChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CardScreen),
      matchesGoldenFile('../docs/screenshot_card.png'),
    );

    // Vollbildansicht des QR-Codes.
    await tester.tap(find.bySemanticsLabel('QR-Code mit den Kontaktdaten'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(QrFullscreenScreen),
      matchesGoldenFile('../docs/screenshot_qr.png'),
    );
  });

  testWidgets('Vorschau im Querformat', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(852, 393) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: CardScreen(
          card: _demo,
          storage: CardStorage(),
          onCardChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CardScreen),
      matchesGoldenFile('../docs/screenshot_landscape.png'),
    );
  });
}
