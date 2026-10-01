import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:qrcard/models/card_style.dart';
import 'package:qrcard/services/widget_bridge.dart';

void main() {
  group('hexOf', () {
    test('schreibt #RRGGBB in Grossbuchstaben', () {
      expect(WidgetBridge.hexOf(const Color(0xFF1F3A5F)), '#1F3A5F');
      expect(WidgetBridge.hexOf(CardStyle.marine.text), '#FFFFFF');
    });

    test('fuellt kurze Werte auf sechs Stellen auf', () {
      expect(WidgetBridge.hexOf(const Color(0xFF000000)), '#000000');
      expect(WidgetBridge.hexOf(const Color(0xFF0A0B0C)), '#0A0B0C');
    });

    test('laesst die Transparenz weg', () {
      // Ein Widget liegt auf dem Hintergrundbild des Nutzers - was dort
      // durchscheint, ist nicht vorhersehbar.
      expect(WidgetBridge.hexOf(const Color(0x111F3A5F)), '#1F3A5F');
    });

    test('ergibt fuer jede Vorlage einen gueltigen Wert', () {
      const styles = <CardStyle>[
        CardStyle.marine,
        CardStyle.graphite,
        CardStyle.bordeaux,
        CardStyle.forest,
        CardStyle.sand,
        CardStyle.paper,
      ];
      final pattern = RegExp(r'^#[0-9A-F]{6}$');
      for (final style in styles) {
        expect(WidgetBridge.hexOf(style.backgroundTop), matches(pattern));
        expect(WidgetBridge.hexOf(style.backgroundBottom), matches(pattern));
        expect(WidgetBridge.hexOf(style.text), matches(pattern));
      }
    });
  });

  group('Schluessel sind ein Vertrag', () {
    // Android (Kotlin) und iOS (Swift) lesen diese Namen fest verdrahtet.
    // Wer sie hier aendert, muss beide Seiten nachziehen - der Test erinnert
    // daran, denn ein falscher Name faellt sonst erst auf dem Geraet auf.
    test('die Namen stimmen mit den Widgets ueberein', () {
      expect(WidgetBridge.keyVCard, 'card_vcard');
      expect(WidgetBridge.keyImagePath, 'card_qr_path');
      expect(WidgetBridge.keyName, 'card_name');
      expect(WidgetBridge.keySubtitle, 'card_subtitle');
      expect(WidgetBridge.keyBackgroundTop, 'card_bg_top');
      expect(WidgetBridge.keyBackgroundBottom, 'card_bg_bottom');
      expect(WidgetBridge.keyForeground, 'card_fg');
      expect(WidgetBridge.iosWidgetName, 'CardWidget');
      expect(WidgetBridge.iosAppGroupId, 'group.de.cyb8.qrcode');
    });

    test('die Kotlin-Seite nennt dieselben Schluessel', () {
      final kotlin = File(
        'android/app/src/main/kotlin/de/cyb8/qrcode/CardWidgetProvider.kt',
      ).readAsStringSync();
      for (final key in [
        WidgetBridge.keyImagePath,
        WidgetBridge.keyName,
        WidgetBridge.keySubtitle,
      ]) {
        expect(
          kotlin,
          contains('"$key"'),
          reason: 'fehlt in CardWidgetProvider.kt',
        );
      }
      expect(kotlin, contains('class ${WidgetBridge.androidProviderName}'));
    });

    test('die Swift-Seite nennt dieselben Schluessel', () {
      final swift = File('ios/widget/CardWidget.swift').readAsStringSync();
      for (final key in [
        WidgetBridge.keyVCard,
        WidgetBridge.keyName,
        WidgetBridge.keySubtitle,
        WidgetBridge.keyBackgroundTop,
        WidgetBridge.keyBackgroundBottom,
        WidgetBridge.keyForeground,
      ]) {
        expect(swift, contains('"$key"'), reason: 'fehlt in CardWidget.swift');
      }
      expect(swift, contains('"${WidgetBridge.iosAppGroupId}"'));
      expect(swift, contains('kind = "${WidgetBridge.iosWidgetName}"'));
    });
  });
}
