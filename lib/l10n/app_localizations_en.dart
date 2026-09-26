// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Business Card';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get reset => 'Reset';

  @override
  String get editCard => 'Edit business card';

  @override
  String get scanHint => 'Tap to enlarge';

  @override
  String get addContactData => 'Add contact details';

  @override
  String copiedToClipboard(String label) {
    return '$label copied';
  }

  @override
  String get couldNotOpen => 'Could not be opened.';

  @override
  String get labelAddress => 'Address';

  @override
  String get labelPhone => 'Phone';

  @override
  String get labelMobile => 'Mobile';

  @override
  String get labelEmail => 'Email';

  @override
  String get labelWeb => 'Web';

  @override
  String get qrScreenTitle => 'Ready to scan';

  @override
  String get qrScreenHint =>
      'Scan with the camera – the contact can be saved straight away.';

  @override
  String get sectionPerson => 'Person';

  @override
  String get sectionCompany => 'Company';

  @override
  String get sectionContact => 'Contact';

  @override
  String get fieldFirstName => 'First name';

  @override
  String get fieldLastName => 'Last name';

  @override
  String get fieldJobTitle => 'Position / title';

  @override
  String get hintJobTitle => 'e.g. Managing Director';

  @override
  String get fieldCompany => 'Company name';

  @override
  String get fieldStreet => 'Street and number';

  @override
  String get fieldPostalCode => 'Postcode';

  @override
  String get fieldCity => 'City';

  @override
  String get fieldCountry => 'Country';

  @override
  String get fieldPhoneWork => 'Phone (work)';

  @override
  String get fieldMobile => 'Mobile';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldWebsite => 'Website';

  @override
  String get hintWebsite => 'e.g. company.com';

  @override
  String get invalidEmail => 'Please enter a valid email address';

  @override
  String get privacyNote =>
      'Everything stays on this device. The app never sends anything to a server.';

  @override
  String get photoAdd => 'Add photo';

  @override
  String get photoChange => 'Change photo';

  @override
  String get photoFromGallery => 'Choose from gallery';

  @override
  String get photoFromCamera => 'Take a photo';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String photoError(String error) {
    return 'Could not load the photo: $error';
  }

  @override
  String get profiles => 'Profiles';

  @override
  String get profileName => 'Profile name';

  @override
  String get hintProfileName => 'e.g. Work or Personal';

  @override
  String get newProfile => 'New profile';

  @override
  String get duplicateProfile => 'Duplicate profile';

  @override
  String get deleteProfile => 'Delete profile';

  @override
  String deleteProfileQuestion(String name) {
    return 'Really delete the profile “$name”?';
  }

  @override
  String get lastProfileHint => 'The last remaining profile cannot be deleted.';

  @override
  String get switchProfile => 'Switch profile';

  @override
  String get untitledProfile => 'Untitled';

  @override
  String get appearance => 'Appearance';

  @override
  String get colorPresets => 'Colour presets';

  @override
  String get colorCustom => 'Custom colour';

  @override
  String get colorBackgroundTop => 'Background top';

  @override
  String get colorBackgroundBottom => 'Background bottom';

  @override
  String get colorText => 'Text';

  @override
  String get colorAccent => 'Accent';

  @override
  String get contrastWarning =>
      'Text and background are too similar – the card will be hard to read.';

  @override
  String get qrStaysWhite =>
      'The QR code always stays black on white so every scanner reads it reliably.';

  @override
  String get preview => 'Preview';

  @override
  String get presetMarine => 'Marine';

  @override
  String get presetGraphite => 'Graphite';

  @override
  String get presetBordeaux => 'Bordeaux';

  @override
  String get presetForest => 'Forest';

  @override
  String get presetSand => 'Sand';

  @override
  String get presetPaper => 'Paper';
}
