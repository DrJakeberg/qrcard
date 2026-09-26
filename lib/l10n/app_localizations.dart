import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In de, this message translates to:
  /// **'Visitenkarte'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In de, this message translates to:
  /// **'Abbrechen'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In de, this message translates to:
  /// **'Speichern'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In de, this message translates to:
  /// **'Löschen'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In de, this message translates to:
  /// **'Fertig'**
  String get done;

  /// No description provided for @reset.
  ///
  /// In de, this message translates to:
  /// **'Zurücksetzen'**
  String get reset;

  /// No description provided for @editCard.
  ///
  /// In de, this message translates to:
  /// **'Visitenkarte bearbeiten'**
  String get editCard;

  /// No description provided for @scanHint.
  ///
  /// In de, this message translates to:
  /// **'Antippen zum Vergrößern'**
  String get scanHint;

  /// No description provided for @addContactData.
  ///
  /// In de, this message translates to:
  /// **'Kontaktdaten hinzufügen'**
  String get addContactData;

  /// No description provided for @copiedToClipboard.
  ///
  /// In de, this message translates to:
  /// **'{label} kopiert'**
  String copiedToClipboard(String label);

  /// No description provided for @couldNotOpen.
  ///
  /// In de, this message translates to:
  /// **'Konnte nicht geöffnet werden.'**
  String get couldNotOpen;

  /// No description provided for @labelAddress.
  ///
  /// In de, this message translates to:
  /// **'Adresse'**
  String get labelAddress;

  /// No description provided for @labelPhone.
  ///
  /// In de, this message translates to:
  /// **'Telefon'**
  String get labelPhone;

  /// No description provided for @labelMobile.
  ///
  /// In de, this message translates to:
  /// **'Mobil'**
  String get labelMobile;

  /// No description provided for @labelEmail.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get labelEmail;

  /// No description provided for @labelWeb.
  ///
  /// In de, this message translates to:
  /// **'Web'**
  String get labelWeb;

  /// No description provided for @qrScreenTitle.
  ///
  /// In de, this message translates to:
  /// **'Zum Scannen'**
  String get qrScreenTitle;

  /// No description provided for @qrScreenHint.
  ///
  /// In de, this message translates to:
  /// **'Mit der Kamera scannen – der Kontakt kann direkt gespeichert werden.'**
  String get qrScreenHint;

  /// No description provided for @sectionPerson.
  ///
  /// In de, this message translates to:
  /// **'Person'**
  String get sectionPerson;

  /// No description provided for @sectionCompany.
  ///
  /// In de, this message translates to:
  /// **'Firma'**
  String get sectionCompany;

  /// No description provided for @sectionContact.
  ///
  /// In de, this message translates to:
  /// **'Kontakt'**
  String get sectionContact;

  /// No description provided for @fieldFirstName.
  ///
  /// In de, this message translates to:
  /// **'Vorname'**
  String get fieldFirstName;

  /// No description provided for @fieldLastName.
  ///
  /// In de, this message translates to:
  /// **'Nachname'**
  String get fieldLastName;

  /// No description provided for @fieldJobTitle.
  ///
  /// In de, this message translates to:
  /// **'Position / Titel'**
  String get fieldJobTitle;

  /// No description provided for @hintJobTitle.
  ///
  /// In de, this message translates to:
  /// **'z. B. Geschäftsführer'**
  String get hintJobTitle;

  /// No description provided for @fieldCompany.
  ///
  /// In de, this message translates to:
  /// **'Firmenname'**
  String get fieldCompany;

  /// No description provided for @fieldStreet.
  ///
  /// In de, this message translates to:
  /// **'Straße und Hausnummer'**
  String get fieldStreet;

  /// No description provided for @fieldPostalCode.
  ///
  /// In de, this message translates to:
  /// **'PLZ'**
  String get fieldPostalCode;

  /// No description provided for @fieldCity.
  ///
  /// In de, this message translates to:
  /// **'Ort'**
  String get fieldCity;

  /// No description provided for @fieldCountry.
  ///
  /// In de, this message translates to:
  /// **'Land'**
  String get fieldCountry;

  /// No description provided for @fieldPhoneWork.
  ///
  /// In de, this message translates to:
  /// **'Telefon (Firma)'**
  String get fieldPhoneWork;

  /// No description provided for @fieldMobile.
  ///
  /// In de, this message translates to:
  /// **'Mobil'**
  String get fieldMobile;

  /// No description provided for @fieldEmail.
  ///
  /// In de, this message translates to:
  /// **'E-Mail'**
  String get fieldEmail;

  /// No description provided for @fieldWebsite.
  ///
  /// In de, this message translates to:
  /// **'Website'**
  String get fieldWebsite;

  /// No description provided for @hintWebsite.
  ///
  /// In de, this message translates to:
  /// **'z. B. firma.de'**
  String get hintWebsite;

  /// No description provided for @invalidEmail.
  ///
  /// In de, this message translates to:
  /// **'Bitte eine gültige E-Mail-Adresse eingeben'**
  String get invalidEmail;

  /// No description provided for @privacyNote.
  ///
  /// In de, this message translates to:
  /// **'Alle Angaben bleiben auf diesem Gerät. Die App sendet nichts an einen Server.'**
  String get privacyNote;

  /// No description provided for @photoAdd.
  ///
  /// In de, this message translates to:
  /// **'Foto hinzufügen'**
  String get photoAdd;

  /// No description provided for @photoChange.
  ///
  /// In de, this message translates to:
  /// **'Foto ändern'**
  String get photoChange;

  /// No description provided for @photoFromGallery.
  ///
  /// In de, this message translates to:
  /// **'Aus der Galerie wählen'**
  String get photoFromGallery;

  /// No description provided for @photoFromCamera.
  ///
  /// In de, this message translates to:
  /// **'Foto aufnehmen'**
  String get photoFromCamera;

  /// No description provided for @photoRemove.
  ///
  /// In de, this message translates to:
  /// **'Foto entfernen'**
  String get photoRemove;

  /// No description provided for @photoError.
  ///
  /// In de, this message translates to:
  /// **'Foto konnte nicht geladen werden: {error}'**
  String photoError(String error);

  /// No description provided for @profiles.
  ///
  /// In de, this message translates to:
  /// **'Profile'**
  String get profiles;

  /// No description provided for @profileName.
  ///
  /// In de, this message translates to:
  /// **'Profilname'**
  String get profileName;

  /// No description provided for @hintProfileName.
  ///
  /// In de, this message translates to:
  /// **'z. B. Firma oder Privat'**
  String get hintProfileName;

  /// No description provided for @newProfile.
  ///
  /// In de, this message translates to:
  /// **'Neues Profil'**
  String get newProfile;

  /// No description provided for @duplicateProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil duplizieren'**
  String get duplicateProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil löschen'**
  String get deleteProfile;

  /// No description provided for @deleteProfileQuestion.
  ///
  /// In de, this message translates to:
  /// **'Profil „{name}“ wirklich löschen?'**
  String deleteProfileQuestion(String name);

  /// No description provided for @lastProfileHint.
  ///
  /// In de, this message translates to:
  /// **'Das letzte Profil kann nicht gelöscht werden.'**
  String get lastProfileHint;

  /// No description provided for @switchProfile.
  ///
  /// In de, this message translates to:
  /// **'Profil wechseln'**
  String get switchProfile;

  /// No description provided for @untitledProfile.
  ///
  /// In de, this message translates to:
  /// **'Ohne Namen'**
  String get untitledProfile;

  /// No description provided for @appearance.
  ///
  /// In de, this message translates to:
  /// **'Darstellung'**
  String get appearance;

  /// No description provided for @colorPresets.
  ///
  /// In de, this message translates to:
  /// **'Farbvorlagen'**
  String get colorPresets;

  /// No description provided for @colorCustom.
  ///
  /// In de, this message translates to:
  /// **'Eigene Farbe'**
  String get colorCustom;

  /// No description provided for @colorBackgroundTop.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund oben'**
  String get colorBackgroundTop;

  /// No description provided for @colorBackgroundBottom.
  ///
  /// In de, this message translates to:
  /// **'Hintergrund unten'**
  String get colorBackgroundBottom;

  /// No description provided for @colorText.
  ///
  /// In de, this message translates to:
  /// **'Schrift'**
  String get colorText;

  /// No description provided for @colorAccent.
  ///
  /// In de, this message translates to:
  /// **'Akzent'**
  String get colorAccent;

  /// No description provided for @contrastWarning.
  ///
  /// In de, this message translates to:
  /// **'Schrift und Hintergrund sind zu ähnlich – die Karte wird schwer lesbar.'**
  String get contrastWarning;

  /// No description provided for @qrStaysWhite.
  ///
  /// In de, this message translates to:
  /// **'Der QR-Code bleibt immer schwarz auf weiß, damit ihn jeder Scanner sicher liest.'**
  String get qrStaysWhite;

  /// No description provided for @preview.
  ///
  /// In de, this message translates to:
  /// **'Vorschau'**
  String get preview;

  /// No description provided for @presetMarine.
  ///
  /// In de, this message translates to:
  /// **'Marine'**
  String get presetMarine;

  /// No description provided for @presetGraphite.
  ///
  /// In de, this message translates to:
  /// **'Graphit'**
  String get presetGraphite;

  /// No description provided for @presetBordeaux.
  ///
  /// In de, this message translates to:
  /// **'Bordeaux'**
  String get presetBordeaux;

  /// No description provided for @presetForest.
  ///
  /// In de, this message translates to:
  /// **'Wald'**
  String get presetForest;

  /// No description provided for @presetSand.
  ///
  /// In de, this message translates to:
  /// **'Sand'**
  String get presetSand;

  /// No description provided for @presetPaper.
  ///
  /// In de, this message translates to:
  /// **'Papier'**
  String get presetPaper;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
