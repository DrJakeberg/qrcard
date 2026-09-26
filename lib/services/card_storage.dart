import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/card_profile.dart';
import '../models/contact_card.dart';

/// Speichert alle Profile lokal auf dem Geraet.
///
/// Die Texte und Farben liegen in den SharedPreferences, die Fotos als Dateien
/// im privaten App-Verzeichnis. Nichts davon verlaesst das Geraet.
class CardStorage {
  static const String _profilesKey = 'card_profiles_v2';

  /// Schluessel der ersten Fassung - wird beim ersten Start uebernommen.
  static const String _legacyCardKey = 'contact_card_v1';

  static const String _photoDirName = 'card_photo';

  Future<ProfileSet> load() async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_profilesKey);
    if (raw != null && raw.isNotEmpty) {
      return _withExistingPhotos(ProfileSet.decode(raw));
    }

    // Migration: eine einzelne Karte aus der ersten Version uebernehmen.
    final legacy = prefs.getString(_legacyCardKey);
    if (legacy != null && legacy.isNotEmpty) {
      final card = ContactCard.decode(legacy);
      final migrated = ProfileSet.initial();
      final profile = migrated.profiles.first.copyWith(card: card);
      final result = migrated.replace(profile);
      await save(result);
      await prefs.remove(_legacyCardKey);
      return _withExistingPhotos(result);
    }

    return ProfileSet.initial();
  }

  Future<void> save(ProfileSet profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profilesKey, profiles.encode());
  }

  /// Entfernt Bildpfade, deren Datei es nicht mehr gibt (z. B. nach einer
  /// Wiederherstellung aus einem Backup).
  ProfileSet _withExistingPhotos(ProfileSet set) {
    var changed = false;
    final cleaned = <CardProfile>[];
    for (final profile in set.profiles) {
      final path = profile.card.photoPath;
      if (path != null && !File(path).existsSync()) {
        cleaned.add(
          profile.copyWith(card: profile.card.copyWith(clearPhoto: true)),
        );
        changed = true;
      } else {
        cleaned.add(profile);
      }
    }
    if (!changed) return set;
    return ProfileSet(profiles: cleaned, activeId: set.activeId);
  }

  /// Kopiert das ausgewaehlte Bild in das App-Verzeichnis und gibt den neuen
  /// Pfad zurueck. Der Dateiname enthaelt einen Zeitstempel, damit Flutter das
  /// alte Bild nicht aus dem Bild-Cache wiederverwendet.
  Future<String> importPhoto(File source) async {
    final photoDir = await _photoDirectory();
    final extension = _extensionOf(source.path);
    final target =
        '${photoDir.path}/photo_${DateTime.now().millisecondsSinceEpoch}$extension';
    await source.copy(target);
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
        // Nicht kritisch - die Karte zeigt dann die Initialen.
      }
    }
  }

  /// Loescht Fotos, auf die kein Profil mehr zeigt.
  ///
  /// Seit es mehrere Profile gibt, darf nicht mehr pauschal alles ausser dem
  /// neuesten Bild geloescht werden - sonst verlieren die anderen Profile ihr
  /// Foto.
  Future<void> removeOrphanedPhotos(ProfileSet profiles) async {
    final photoDir = await _photoDirectory();
    final inUse = <String>{
      for (final profile in profiles.profiles)
        if (profile.card.photoPath != null) profile.card.photoPath!,
    };

    for (final entity in photoDir.listSync()) {
      if (entity is File && !inUse.contains(entity.path)) {
        try {
          entity.deleteSync();
        } on FileSystemException {
          // Nicht kritisch - das Bild belegt dann weiter Platz.
        }
      }
    }
  }

  Future<Directory> _photoDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final photoDir = Directory('${docsDir.path}/$_photoDirName');
    if (!photoDir.existsSync()) {
      await photoDir.create(recursive: true);
    }
    return photoDir;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot < path.lastIndexOf('/')) return '.jpg';
    final ext = path.substring(dot).toLowerCase();
    return ext.length <= 5 ? ext : '.jpg';
  }
}
