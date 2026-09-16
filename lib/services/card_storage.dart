import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contact_card.dart';

/// Speichert die Visitenkarte lokal auf dem Geraet.
///
/// Die Textdaten liegen in den SharedPreferences, das Foto als Datei im
/// privaten App-Verzeichnis. Nichts davon verlaesst das Geraet.
class CardStorage {
  static const String _prefsKey = 'contact_card_v1';
  static const String _photoDirName = 'card_photo';

  Future<ContactCard> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const ContactCard();

    final card = ContactCard.decode(raw);
    // Foto koennte zwischenzeitlich geloescht worden sein (z. B. Neuinstallation).
    final path = card.photoPath;
    if (path != null && !File(path).existsSync()) {
      return card.copyWith(clearPhoto: true);
    }
    return card;
  }

  Future<void> save(ContactCard card) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, card.encode());
  }

  /// Kopiert das ausgewaehlte Bild in das App-Verzeichnis und gibt den neuen
  /// Pfad zurueck. Der Dateiname enthaelt einen Zeitstempel, damit Flutter das
  /// alte Bild nicht aus dem Bild-Cache wiederverwendet.
  Future<String> importPhoto(File source) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${docsDir.path}/$_photoDirName');
    if (!photoDir.existsSync()) {
      await photoDir.create(recursive: true);
    }

    final extension = _extensionOf(source.path);
    final target =
        '${photoDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}$extension';
    await source.copy(target);

    // Aeltere Fotos aufraeumen, damit nicht bei jedem Wechsel Platz belegt bleibt.
    for (final entity in photoDir.listSync()) {
      if (entity is File && entity.path != target) {
        try {
          entity.deleteSync();
        } on FileSystemException {
          // Nicht kritisch - das alte Bild bleibt dann einfach liegen.
        }
      }
    }
    return target;
  }

  /// Entfernt das hinterlegte Foto vom Geraet.
  Future<void> deletePhoto(String? path) async {
    if (path == null) return;
    final file = File(path);
    if (file.existsSync()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Ignorieren - die Karte zeigt dann trotzdem die Initialen.
      }
    }
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot < path.lastIndexOf('/')) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.jpg';
  }
}
