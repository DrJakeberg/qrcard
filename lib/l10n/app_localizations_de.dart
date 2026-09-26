// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Visitenkarte';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get delete => 'Löschen';

  @override
  String get done => 'Fertig';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get editCard => 'Visitenkarte bearbeiten';

  @override
  String get scanHint => 'Antippen zum Vergrößern';

  @override
  String get addContactData => 'Kontaktdaten hinzufügen';

  @override
  String copiedToClipboard(String label) {
    return '$label kopiert';
  }

  @override
  String get couldNotOpen => 'Konnte nicht geöffnet werden.';

  @override
  String get labelAddress => 'Adresse';

  @override
  String get labelPhone => 'Telefon';

  @override
  String get labelMobile => 'Mobil';

  @override
  String get labelEmail => 'E-Mail';

  @override
  String get labelWeb => 'Web';

  @override
  String get qrScreenTitle => 'Zum Scannen';

  @override
  String get qrScreenHint =>
      'Mit der Kamera scannen – der Kontakt kann direkt gespeichert werden.';

  @override
  String get sectionPerson => 'Person';

  @override
  String get sectionCompany => 'Firma';

  @override
  String get sectionContact => 'Kontakt';

  @override
  String get fieldFirstName => 'Vorname';

  @override
  String get fieldLastName => 'Nachname';

  @override
  String get fieldJobTitle => 'Position / Titel';

  @override
  String get hintJobTitle => 'z. B. Geschäftsführer';

  @override
  String get fieldCompany => 'Firmenname';

  @override
  String get fieldStreet => 'Straße und Hausnummer';

  @override
  String get fieldPostalCode => 'PLZ';

  @override
  String get fieldCity => 'Ort';

  @override
  String get fieldCountry => 'Land';

  @override
  String get fieldPhoneWork => 'Telefon (Firma)';

  @override
  String get fieldMobile => 'Mobil';

  @override
  String get fieldEmail => 'E-Mail';

  @override
  String get fieldWebsite => 'Website';

  @override
  String get hintWebsite => 'z. B. firma.de';

  @override
  String get invalidEmail => 'Bitte eine gültige E-Mail-Adresse eingeben';

  @override
  String get privacyNote =>
      'Alle Angaben bleiben auf diesem Gerät. Die App sendet nichts an einen Server.';

  @override
  String get photoAdd => 'Foto hinzufügen';

  @override
  String get photoChange => 'Foto ändern';

  @override
  String get photoFromGallery => 'Aus der Galerie wählen';

  @override
  String get photoFromCamera => 'Foto aufnehmen';

  @override
  String get photoRemove => 'Foto entfernen';

  @override
  String photoError(String error) {
    return 'Foto konnte nicht geladen werden: $error';
  }

  @override
  String get profiles => 'Profile';

  @override
  String get profileName => 'Profilname';

  @override
  String get hintProfileName => 'z. B. Firma oder Privat';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get duplicateProfile => 'Profil duplizieren';

  @override
  String get deleteProfile => 'Profil löschen';

  @override
  String deleteProfileQuestion(String name) {
    return 'Profil „$name“ wirklich löschen?';
  }

  @override
  String get lastProfileHint => 'Das letzte Profil kann nicht gelöscht werden.';

  @override
  String get switchProfile => 'Profil wechseln';

  @override
  String get untitledProfile => 'Ohne Namen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get colorPresets => 'Farbvorlagen';

  @override
  String get colorCustom => 'Eigene Farbe';

  @override
  String get colorBackgroundTop => 'Hintergrund oben';

  @override
  String get colorBackgroundBottom => 'Hintergrund unten';

  @override
  String get colorText => 'Schrift';

  @override
  String get colorAccent => 'Akzent';

  @override
  String get contrastWarning =>
      'Schrift und Hintergrund sind zu ähnlich – die Karte wird schwer lesbar.';

  @override
  String get qrStaysWhite =>
      'Der QR-Code bleibt immer schwarz auf weiß, damit ihn jeder Scanner sicher liest.';

  @override
  String get preview => 'Vorschau';

  @override
  String get presetMarine => 'Marine';

  @override
  String get presetGraphite => 'Graphit';

  @override
  String get presetBordeaux => 'Bordeaux';

  @override
  String get presetForest => 'Wald';

  @override
  String get presetSand => 'Sand';

  @override
  String get presetPaper => 'Papier';
}
