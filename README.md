# Visitenkarte (qrcard)

Eine Flutter-App für Android und iOS, die deine Visitenkarte auf **einer
einzigen Seite** anzeigt – mit Foto, Kontaktdaten und einem QR-Code, den jeder
Standard-Scanner als Kontakt erkennt.

Alles bleibt auf dem Gerät. Die App hat keinen Server, keinen Account und
keinen Netzwerkzugriff.

| Visitenkarte | Vollbild zum Scannen |
|---|---|
| ![Visitenkarte](docs/screenshot_card.png) | ![QR-Code](docs/screenshot_qr.png) |

## Was die App kann

- **Alles auf einer Seite** – kein Scrollen. Das Layout rechnet die Größen aus
  dem verfügbaren Platz aus und passt vom kleinen 320-px-Gerät bis zum Tablet,
  im Hoch- und im Querformat.
- **QR-Code als vCard 3.0** – die Standard-Kamera von Android und iOS erkennt
  ihn und bietet direkt „Kontakt speichern“ an. Es wird kein Link und kein
  Dienst dazwischengeschaltet, die Kontaktdaten stehen komplett im Code.
- **Eigenes Foto** – aus der Galerie oder direkt mit der Kamera aufgenommen.
  Das Bild wird in das private App-Verzeichnis kopiert.
- **Antippen zum Vergrößern** – der QR-Code lässt sich formatfüllend anzeigen,
  damit das Gegenüber ihn auch über den Tisch hinweg scannen kann.
- **Tippen und Halten** – ein Tipp auf Telefon/E-Mail/Web startet Anruf, Mail
  oder Browser, langes Drücken kopiert den Wert in die Zwischenablage.

## Felder

Person (Vorname, Nachname, Position/Titel), Firma (Name, Straße, PLZ, Ort,
Land) und Kontakt (Telefon, Mobil, E-Mail, Website). Leere Felder werden
weder angezeigt noch in den QR-Code geschrieben.

## Selbst bauen

Voraussetzung ist das [Flutter SDK](https://docs.flutter.dev/get-started/install).
`flutter doctor` sagt dir, was noch fehlt.

```bash
git clone https://github.com/DrJakeberg/qrcard.git
cd qrcard
flutter pub get
flutter run          # Telefon per USB angeschlossen, oder Emulator/Simulator
```

Beim ersten Start öffnet sich direkt die Eingabemaske. Danach kommst du über
das Stift-Symbol oben rechts wieder hinein.

**Android** (braucht Android Studio bzw. das Android SDK):

```bash
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk
```

Die APK auf das Telefon kopieren und antippen. Android fragt einmalig nach der
Erlaubnis, Apps aus dieser Quelle zu installieren. Die Release-Builds sind mit
dem Debug-Schlüssel signiert – das reicht für den eigenen Gebrauch, für den
Play Store bräuchte es einen eigenen Signaturschlüssel.

**iOS** (braucht einen Mac mit Xcode):

```bash
flutter build ios --release
open ios/Runner.xcworkspace   # Signierung setzen, dann auf das Gerät laden
```

Zum Installieren auf dem eigenen iPhone reicht eine kostenlose Apple-ID; die
App läuft dann 7 Tage und muss danach neu geladen werden. Ein
Apple-Developer-Account (99 $/Jahr) hebt diese Grenze auf.

## Bauen lassen statt selbst bauen

In `.github/workflows/ci.yml` liegt ein GitHub-Actions-Workflow. Er läuft bei
jedem Push und jedem Pull Request und macht drei Dinge:

| Job | Läuft auf | Was er tut |
|---|---|---|
| Analyse und Tests | Ubuntu | `dart format`-Prüfung, `flutter analyze`, `flutter test` |
| Android-APK bauen | Ubuntu | baut die Release-APK und hängt sie als Artefakt an |
| iOS-Build prüfen | macOS | `flutter build ios --no-codesign` – prüft, dass der iOS-Build durchläuft |

Die fertige APK holst du dir unter **Actions → der jeweilige Lauf → Artifacts →
`visitenkarte-android-apk`**. Damit brauchst du für Android gar keine lokale
Entwicklungsumgebung. Für öffentliche Repositories sind die Runner kostenlos.

Eine direkt installierbare `.ipa` kann der Runner nicht erzeugen – dafür
müssten Apple-Zertifikat und Provisioning-Profil als Secrets hinterlegt sein.
Dienste wie [Codemagic](https://codemagic.io) sind darauf spezialisiert und
nehmen einem die Signierung ab; ein Apple-Developer-Account wird trotzdem
gebraucht.

## Aufbau

```
lib/
  main.dart                    App-Start, lädt und speichert die Karte
  theme.dart                   Farben und Material-3-Theme
  models/contact_card.dart     Datenmodell + JSON
  services/vcard.dart          Erzeugt den vCard-Text für den QR-Code
  services/card_storage.dart   Lokales Speichern (Text + Foto)
  screens/card_screen.dart     Die Visitenkarte (eine Seite, kein Scrollen)
  screens/edit_screen.dart     Eingabemaske
  screens/qr_fullscreen.dart   QR-Code formatfüllend
  widgets/qr_panel.dart        QR-Code auf weißem Grund
```

Der QR-Code steht bewusst immer auf weißem Grund mit schwarzen Modulen – auch
im Dunkelmodus –, weil Scanner darauf ausgelegt sind. Das Foto wird
**nicht** in die vCard eingebettet: Ein Bild würde den QR-Code so groß machen,
dass er kaum noch zu scannen wäre.

## Tests

```bash
flutter test
```

Abgedeckt sind die vCard-Erzeugung (Feldreihenfolge, Maskierung von
Sonderzeichen, weggelassene Leerfelder), das Speichern und Laden sowie das
Layout: Die Karte wird auf sieben Gerätegrößen gerendert und muss ohne
Überlauf und ohne Scrollbereich auskommen – auch bei doppelter
System-Schriftgröße.

Der Bild-Generator für `docs/` liegt bewusst außerhalb von `test/`, damit
`flutter test` ihn nicht mitläuft: Die Bilder hängen von den lokal
installierten Schriften ab und würden auf einem anderen Rechner abweichen.

```bash
flutter test tool/generate_previews_test.dart --update-goldens
```

## Datenschutz

Die App fordert keine Netzwerkberechtigung an und sendet nichts. Kontaktdaten
liegen in den SharedPreferences, das Foto im privaten App-Verzeichnis. Beim
Deinstallieren wird beides mit entfernt.
