import 'dart:ui';

/// Waehlt die Sprache der App anhand der Systemsprache des Telefons.
///
/// Flutter wuerde bei einer nicht uebersetzten Sprache die erste unterstuetzte
/// nehmen - das waere Deutsch. Fuer ein franzoesisches oder spanisches Telefon
/// ist Englisch der bessere Rueckfall, deshalb diese eigene Aufloesung.
Locale resolveLocale(Locale? deviceLocale, Iterable<Locale> supported) {
  if (deviceLocale != null) {
    // Erst die genaue Entsprechung inklusive Land versuchen ...
    for (final candidate in supported) {
      if (candidate.languageCode == deviceLocale.languageCode &&
          candidate.countryCode == deviceLocale.countryCode) {
        return candidate;
      }
    }
    // ... dann nur die Sprache, damit z. B. de_AT auch Deutsch bekommt.
    for (final candidate in supported) {
      if (candidate.languageCode == deviceLocale.languageCode) {
        return candidate;
      }
    }
  }

  const fallback = Locale('en');
  return supported.contains(fallback) ? fallback : supported.first;
}
