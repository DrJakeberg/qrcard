import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:qrcard/l10n/app_localizations.dart';
import 'package:qrcard/models/card_profile.dart';
import 'package:qrcard/models/card_style.dart';
import 'package:qrcard/models/contact_card.dart';
import 'package:qrcard/screens/card_screen.dart';
import 'package:qrcard/screens/profiles_screen.dart';
import 'package:qrcard/screens/qr_fullscreen.dart';
import 'package:qrcard/screens/style_editor.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:qrcard/services/card_storage.dart';
import 'package:qrcard/services/vcard.dart';
import 'package:qrcard/theme.dart';

/// Erzeugt die Vorschaubilder in docs/ (nur fuer die Dokumentation).
///
/// Liegt bewusst ausserhalb von test/, damit `flutter test` es nicht mitlaeuft:
/// Die Bilder haengen von den lokal installierten Schriften ab und wuerden auf
/// einem anderen Rechner oder auf dem CI-Runner abweichen.
///
/// Aufruf:
///   flutter test tool/generate_previews_test.dart --update-goldens
const ContactCard _demo = ContactCard(
  firstName: 'Alex',
  lastName: 'Morgan',
  jobTitle: 'Managing Director',
  company: 'Northfield Engineering Ltd',
  street: '14 Fairmont Road',
  postalCode: 'M1 4BT',
  city: 'Manchester',
  country: 'United Kingdom',
  phone: '+44 161 496 0114',
  mobile: '+44 7700 900123',
  email: 'a.morgan@northfield-eng.co.uk',
  website: 'northfield-eng.co.uk',
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

const ContactCard _privateCard = ContactCard(
  firstName: 'Alex',
  lastName: 'Morgan',
  jobTitle: 'Photography',
  company: 'Morgan Studio',
  city: 'Manchester',
  country: 'United Kingdom',
  mobile: '+44 7700 900123',
  email: 'hello@morganstudio.co.uk',
  website: 'morganstudio.co.uk',
);

final ProfileSet _twoProfiles = ProfileSet(
  profiles: const [
    CardProfile(id: 'demo', name: 'Work', card: _demo, style: CardStyle.marine),
    CardProfile(
      id: 'privat',
      name: 'Personal',
      card: _privateCard,
      style: CardStyle.sand,
    ),
  ],
  activeId: 'demo',
);

final ProfileSet _demoSet = ProfileSet(
  profiles: const [
    CardProfile(id: 'demo', name: '', card: _demo, style: CardStyle.marine),
  ],
  activeId: 'demo',
);

void main() {
  testWidgets('Vorschau der Visitenkarte', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CardScreen(
          profiles: _demoSet,
          storage: CardStorage(),
          onProfilesChanged: (_) {},
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
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: CardScreen(
          profiles: _demoSet,
          storage: CardStorage(),
          onProfilesChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CardScreen),
      matchesGoldenFile('../docs/screenshot_landscape.png'),
    );
  });

  testWidgets('Vorschau der hellen Farbvorlage', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(
        CardScreen(
          profiles: ProfileSet(
            profiles: [_twoProfiles.profiles[1]],
            activeId: 'privat',
          ),
          storage: CardStorage(),
          onProfilesChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CardScreen),
      matchesGoldenFile('../docs/screenshot_light.png'),
    );
  });

  testWidgets('Vorschau der Profilliste', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(ProfilesScreen(profiles: _twoProfiles, storage: CardStorage())),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProfilesScreen),
      matchesGoldenFile('../docs/screenshot_profiles.png'),
    );
  });

  testWidgets('Vorschau des Farbeditors', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 852) * 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(const StyleEditorScreen(style: CardStyle.bordeaux)),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(StyleEditorScreen),
      matchesGoldenFile('../docs/screenshot_colors.png'),
    );
  });

  testWidgets('Vorschau des Homescreen-Widgets', (tester) async {
    await _loadRealFonts();
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(320, 400);
    addTearDown(tester.view.reset);

    // Genau die Darstellung, die auch WidgetBridge.renderQrPng erzeugt:
    // schwarz auf weiss mit ruhiger Zone rundum.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: 300,
            height: 300,
            color: const Color(0xFFFFFFFF),
            padding: const EdgeInsets.all(18),
            child: CustomPaint(
              painter: QrPainter(
                data: buildVCard(_demo),
                version: QrVersions.auto,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                gapless: true,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF000000),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF000000),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(CustomPaint).last,
      matchesGoldenFile('../docs/widget_qr.png'),
    );
  });
}

/// Rahmen fuer alle Vorschaubilder. Die Oberflaeche wird auf Englisch
/// gerendert, weil die Bilder in den Stores und in der README landen.
Widget _app(Widget home) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: const Locale('en'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: buildAppTheme(Brightness.light),
    home: home,
  );
}
