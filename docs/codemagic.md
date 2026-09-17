# Codemagic einrichten

Diese Anleitung listet **jede** Einstellung, die du in Codemagic vornehmen
musst – getrennt nach Android und iOS.

> **Kurz vorweg:** Für Android brauchst du Codemagic nicht. Der
> GitHub-Actions-Workflow im Repo baut die APK kostenlos und hängt sie als
> Artefakt an. Codemagic lohnt sich für **iOS**, weil es die Apple-Signierung
> übernimmt.

---

## Grundsatzentscheidung zuerst: UI-Editor oder `codemagic.yaml`

Codemagic kennt zwei Wege, und sie schließen einander aus:

| | Workflow-Editor (UI) | `codemagic.yaml` |
|---|---|---|
| Konfiguration | im Browser angeklickt | Datei im Repo |
| Versionierung | nicht im Repo | mit dem Code versioniert |
| Gilt, sobald | keine yaml-Datei existiert | die Datei im Repo liegt |

**Sobald eine `codemagic.yaml` im Repo-Wurzelverzeichnis liegt, ignoriert
Codemagic die UI-Konfiguration vollständig.** Entscheide dich für einen Weg.

---

## Projektwerte dieser App

Diese Werte brauchst du in beiden Wegen:

| Einstellung | Wert |
|---|---|
| Bundle ID / Application ID | `de.jakeberg.qrcard` |
| App-Name | Visitenkarte |
| Version | `1.0.0+1` (in `pubspec.yaml`) |
| Flutter-Version | `3.47.4` (damit entwickelt und getestet) |
| iOS-Minimum | 15.0 |
| Android `minSdk` | Flutter-Standard |

---

## Android

### Was einzustellen ist

1. **Build-Format: APK, nicht App Bundle.** Im Workflow-Editor unter den
   Build-Einstellungen. Ein `.aab` ist ein reines Play-Store-Upload-Format und
   lässt sich **nicht** auf einem Telefon installieren.
2. **Build-Modus: Release**, nicht Debug.
3. **Flutter-Version** auf `3.47.4` festnageln.

Mehr ist für den Eigengebrauch nicht nötig: `flutter create` legt die
Release-Konfiguration so an, dass mit dem Debug-Schlüssel signiert wird – die
APK ist also direkt installierbar.

### Optional: eigener Signaturschlüssel

Der Debug-Schlüssel wird auf jedem Build-Rechner neu erzeugt. Eine APK von
Codemagic, eine von GitHub Actions und eine vom eigenen Rechner haben deshalb
**drei verschiedene Signaturen** – Android lässt dich keine über die andere
installieren, du müsstest jedes Mal deinstallieren und verlierst die
eingetragene Visitenkarte.

Wenn dich das stört, einmalig einen eigenen Schlüssel erzeugen:

```bash
keytool -genkey -v -keystore visitenkarte.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias visitenkarte
```

Diesen `.jks` in Codemagic unter den Code-Signing-Einstellungen für Android
hochladen und dort Keystore-Passwort, Alias und Key-Passwort hinterlegen.
**Die Datei gehört nicht ins Repo.**

---

## iOS

Hier liegt der eigentliche Nutzen von Codemagic. Ohne Apple-Developer-Account
(99 $/Jahr) geht nichts davon – das ist eine Apple-Vorgabe, keine Grenze von
Codemagic.

### Schritt für Schritt

1. **App Store Connect API-Key erzeugen**
   In App Store Connect unter *Benutzer und Zugriff → Integrationen →
   App-Store-Connect-API* einen Schlüssel mit der Rolle *App Manager* anlegen.
   Du bekommst eine `.p8`-Datei (nur einmal herunterladbar), eine **Key-ID**
   und eine **Issuer-ID**.

2. **Den Key in Codemagic hinterlegen**
   In den Team- bzw. App-Einstellungen unter *Integrations → Apple Developer
   Portal* die drei Angaben eintragen. Codemagic übernimmt damit die
   Signierung selbst.

3. **Bundle ID registrieren**
   Im Apple Developer Portal unter *Identifiers* eine App-ID für
   `de.jakeberg.qrcard` anlegen. Muss exakt übereinstimmen, sonst schlägt die
   Signierung fehl.

4. **Code Signing im Workflow aktivieren**
   *Automatic code signing* wählen, den hinterlegten API-Key auswählen und den
   Verteilungstyp setzen:

   | Verteilungstyp | Wofür | Zusätzlich nötig |
   |---|---|---|
   | **Ad Hoc** | Installation auf deinen eigenen Geräten | UDID jedes Geräts im Developer Portal registrieren |
   | **App Store** | Verteilung über TestFlight | App in App Store Connect anlegen |
   | **Development** | Test während der Entwicklung | Geräte registrieren |

   Für „nur ich will die App auf meinem iPhone" ist **Ad Hoc** der kürzeste
   Weg. Für bequeme Updates ist **TestFlight** angenehmer.

5. **Build-Nummer hochzählen** *(nur bei TestFlight/App Store)*
   Apple lehnt einen Upload ab, wenn die Build-Nummer schon vergeben ist.
   In den Build-Argumenten:

   ```
   --build-number=$(($PROJECT_BUILD_NUMBER))
   ```

   oder Codemagics `latest_build_number` verwenden, das die letzte Nummer aus
   App Store Connect zieht und um eins erhöht.

### Was der Runner bei iOS nicht kann

Ohne die Schritte 1–4 kann **kein** Dienst eine installierbare `.ipa`
erzeugen. Der iOS-Job in GitHub Actions baut deshalb nur mit `--no-codesign`
und prüft, dass der Build durchläuft.

---

## Berechtigungen, die diese App mitbringt

Codemagic braucht dafür keine Extra-Einstellung – gut zu wissen ist es
trotzdem, weil Apple bei der Review danach fragt:

| Berechtigung | Wofür | Wo deklariert |
|---|---|---|
| Fotobibliothek | Profilbild auswählen | `ios/Runner/Info.plist` |
| Kamera | Profilbild aufnehmen | `ios/Runner/Info.plist` |
| NFC (Android) | Karte per Antippen übertragen | `AndroidManifest.xml` |

Die App fordert **keine** Netzwerkberechtigung an und sendet nichts.

---

## Wenn du doch `codemagic.yaml` willst

Dann diese Datei ins Wurzelverzeichnis legen und die UI-Konfiguration
vergessen. Die Umgebungsvariablen-Gruppen und den Signierungs-Verweis musst du
in Codemagic vorher anlegen.

```yaml
workflows:
  android:
    name: Android APK
    instance_type: linux_x2
    environment:
      flutter: 3.47.4
    scripts:
      - flutter pub get
      - flutter analyze
      - flutter test
      - flutter build apk --release
    artifacts:
      - build/**/outputs/**/*.apk

  ios:
    name: iOS
    instance_type: mac_mini_m2
    environment:
      flutter: 3.47.4
      ios_signing:
        distribution_type: ad_hoc      # oder app_store
        bundle_identifier: de.jakeberg.qrcard
    scripts:
      - flutter pub get
      - flutter test
      - keychain initialize
      - xcode-project use-profiles
      - flutter build ipa --release
          --export-options-plist=/Users/builder/export_options.plist
    artifacts:
      - build/ios/ipa/*.ipa
```

Die Codemagic-Dokumentation zu den Signierungsschritten steht unter
<https://docs.codemagic.io/yaml-code-signing/signing-ios/>.
