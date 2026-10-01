import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/card_profile.dart';
import 'vcard.dart';

/// Versorgt das Homescreen-Widget mit dem QR-Code der aktiven Karte.
///
/// Ein Android-Widget kann kein Flutter darstellen. Deshalb wird der QR-Code
/// hier als PNG gerendert und abgelegt; das Widget zeigt nur noch dieses Bild.
/// Erzeugt wird es genau dann, wenn sich die Karte aendert - das reicht, denn
/// oefter aendert sie sich nicht.
///
/// Das iOS-Widget braucht das PNG nicht: Es erzeugt den Code aus [keyVCard]
/// selbst mit CoreImage und bleibt so in jeder Widget-Groesse scharf. Beide
/// Seiten lesen dieselben Schluessel - was hier umbenannt wird, muss auch in
/// CardWidgetProvider.kt und CardWidget.swift nachgezogen werden.
class WidgetBridge {
  /// Muss zum Namen der Kotlin-Klasse passen (AndroidManifest.xml).
  static const String androidProviderName = 'CardWidgetProvider';

  /// Muss zum `kind` in ios/widget/CardWidget.swift passen.
  static const String iosWidgetName = 'CardWidget';

  /// Gemeinsamer Datentopf von App und iOS-Widget. Zwei getrennte Programme
  /// mit getrennten Sandboxes kommen nur ueber eine App Group aneinander.
  /// Auf Android ist der Aufruf wirkungslos.
  static const String iosAppGroupId = 'group.de.cyb8.qrcode';

  /// Schluessel, unter denen das Widget die Daten erwartet.
  static const String keyImagePath = 'card_qr_path';
  static const String keyName = 'card_name';
  static const String keySubtitle = 'card_subtitle';

  /// Farben der aktiven Karte als "#RRGGBB" - damit das iOS-Widget zur Karte
  /// passt, statt immer gleich auszusehen.
  static const String keyBackgroundTop = 'card_bg_top';
  static const String keyBackgroundBottom = 'card_bg_bottom';
  static const String keyForeground = 'card_fg';

  /// Rohtext der vCard - den liest der NFC-Dienst beim Antippen aus, und auf
  /// iOS erzeugt das Widget daraus selbst seinen QR-Code.
  static const String keyVCard = 'card_vcard';

  static const String _fileName = 'widget_qr.png';

  /// Groesse des gerenderten Bildes. Grosszuegig gewaehlt, damit der Code auch
  /// auf einem grossen Widget scharf bleibt.
  static const double _imageSize = 640;

  /// Schreibt den QR-Code und die Beschriftung fuer das Widget.
  ///
  /// Fehler werden bewusst geschluckt: Ein nicht aktualisiertes Widget darf
  /// niemals das Speichern der Visitenkarte verhindern.
  static Future<void> update(CardProfile profile) async {
    try {
      // Muss vor dem Schreiben stehen: Erst damit landen die Daten auf iOS in
      // der geteilten App Group statt im Sandkasten der App.
      await HomeWidget.setAppGroupId(iosAppGroupId);

      final vCard = buildVCard(profile.card);
      final path = await renderQrToFile(vCard);

      await HomeWidget.saveWidgetData<String>(keyVCard, vCard);
      await HomeWidget.saveWidgetData<String>(keyImagePath, path);
      await HomeWidget.saveWidgetData<String>(keyName, profile.card.fullName);
      await HomeWidget.saveWidgetData<String>(
        keySubtitle,
        [
          profile.card.jobTitle,
          profile.card.company,
        ].where((part) => part.isNotEmpty).join(' · '),
      );
      await HomeWidget.saveWidgetData<String>(
        keyBackgroundTop,
        hexOf(profile.style.backgroundTop),
      );
      await HomeWidget.saveWidgetData<String>(
        keyBackgroundBottom,
        hexOf(profile.style.backgroundBottom),
      );
      await HomeWidget.saveWidgetData<String>(
        keyForeground,
        hexOf(profile.style.text),
      );
      await HomeWidget.updateWidget(
        name: androidProviderName,
        iOSName: iosWidgetName,
      );
    } on Object catch (error, stack) {
      debugPrint('Widget konnte nicht aktualisiert werden: $error\n$stack');
    }
  }

  /// Schreibt eine Farbe als "#RRGGBB".
  ///
  /// Die Transparenz faellt weg: Ein Widget liegt auf dem Hintergrundbild des
  /// Nutzers, da ist eine halbdurchsichtige Flaeche nicht vorhersehbar.
  static String hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// Rendert den QR-Code als PNG und legt ihn im App-Verzeichnis ab.
  static Future<String> renderQrToFile(String data) async {
    final bytes = await renderQrPng(data);
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Erzeugt das PNG des QR-Codes.
  ///
  /// Schwarz auf weiss, wie ueberall in der App - Scanner sind darauf
  /// ausgelegt, und ein Widget kann auf jedem Hintergrund landen.
  ///
  /// Weisse Flaeche und Code entstehen in einem einzigen Zeichendurchgang.
  /// Der Umweg ueber ein zwischengespeichertes PNG braeuchte den Bild-Decoder,
  /// und der laesst sich in Widget-Tests nicht zuverlaessig ansteuern.
  static Future<Uint8List> renderQrPng(String data) async {
    final painter = QrPainter(
      data: data,
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
    );

    // Rand rundum: Ohne diese ruhige Zone tun sich Scanner schwer.
    const padding = _imageSize * 0.06;
    const canvasSize = _imageSize + padding * 2;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(
      recorder,
      const ui.Rect.fromLTWH(0, 0, canvasSize, canvasSize),
    );

    canvas.drawRect(
      const ui.Rect.fromLTWH(0, 0, canvasSize, canvasSize),
      ui.Paint()..color = const Color(0xFFFFFFFF),
    );

    canvas.save();
    canvas.translate(padding, padding);
    painter.paint(canvas, const ui.Size(_imageSize, _imageSize));
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasSize.round(), canvasSize.round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    picture.dispose();

    if (bytes == null) {
      throw StateError('QR-Code konnte nicht gerendert werden');
    }
    return bytes.buffer.asUint8List();
  }
}
