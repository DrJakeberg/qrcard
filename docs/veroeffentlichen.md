# In den Stores veröffentlichen

Alles, was nötig ist, um die App über Codemagic in den **Google Play Store**
und den **Apple App Store** zu bringen. Die `codemagic.yaml` im
Wurzelverzeichnis ist fertig – hier steht, was drumherum einzurichten ist.

> **Wichtig:** Sobald `codemagic.yaml` im Repository liegt, ignoriert Codemagic
> die im Browser angeklickte Konfiguration vollständig. Was du dort eingestellt
> hast, hat ab jetzt keine Wirkung mehr.

---

## Vorab: zwei ehrliche Hinweise

**Der Debug-Schlüssel reicht nicht mehr.** Bisher wurden Release-Builds mit dem
Debug-Schlüssel signiert – zum Selbstinstallieren in Ordnung, vom Play Store
aber abgelehnt. Das ist jetzt umgebaut: Ohne hinterlegten Schlüssel baut die
App weiterhin (mit Debug-Signatur), mit hinterlegtem Schlüssel wird richtig
signiert. Du musst den Schlüssel also einmal erzeugen.

**Apples Prüfung kann heikel werden.** Apple lehnt Apps ab, die nur die Daten
einer einzigen Person zeigen (Richtlinie 4.2, „Minimum Functionality"). Diese
App ist ein allgemeines Werkzeug – jeder trägt seine eigenen Daten ein – und
das ist zulässig. Wichtig ist, dass die Store-Beschreibung sie auch so
darstellt: als Visitenkarten-App für alle, nicht als „Jake Bergs Karte".
Die Texte in [`store/listing-texte.md`](store/listing-texte.md) sind
entsprechend formuliert.

---

## Schritt 1: Signaturschlüssel erzeugen (einmalig)

```bash
keytool -genkey -v -keystore visitenkarte.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias visitenkarte
```

**Bewahre diese Datei und die Passwörter sicher auf.** Geht der Schlüssel
verloren, kannst du nie wieder ein Update für dieselbe App veröffentlichen –
Google verknüpft die App fest mit dieser Signatur.

Die Datei gehört **nicht** ins Repository; `android/.gitignore` schließt sie
bereits aus.

**Lokal verwenden:** `android/key.properties` anlegen (wird nicht eingecheckt):

```properties
storeFile=/absoluter/pfad/zu/visitenkarte.jks
storePassword=DEIN_PASSWORT
keyAlias=visitenkarte
keyPassword=DEIN_KEY_PASSWORT
```

**In Codemagic:** unter *Code signing identities → Android keystores* die
`.jks` hochladen, Passwörter und Alias eintragen und als Referenznamen
**`visitenkarte_keystore`** vergeben – genau so heißt sie in der
`codemagic.yaml`.

---

## Schritt 2: Google Play einrichten

### In der Play Console

1. **Entwicklerkonto** anlegen (einmalig 25 $).
2. **App erstellen** mit dem Paketnamen `de.jakeberg.qrcard`. Der Name ist
   unveränderlich – später lässt er sich nicht mehr korrigieren.
3. **Store-Eintrag** füllen. Was Google verlangt:

   | Pflichtangabe | Wo es liegt |
   |---|---|
   | App-Symbol 512×512 | [`store/play_icon_512.png`](store/play_icon_512.png) |
   | Feature-Grafik 1024×500 | [`store/feature_graphic.png`](store/feature_graphic.png) |
   | Mind. 2 Screenshots | `screenshot_card.png`, `screenshot_qr.png`, `screenshot_light.png`, `screenshot_profiles.png`, `screenshot_colors.png` |
   | Kurzbeschreibung (80 Zeichen) | [`store/listing-texte.md`](store/listing-texte.md) |
   | Vollständige Beschreibung | ebenda |
   | Datenschutzerklärung (URL) | siehe unten |

4. **Datensicherheit** ausfüllen: Es werden keine Daten erhoben, keine geteilt,
   kein Tracking. Die Tabelle in `store/listing-texte.md` hat die Antworten.
5. **Inhaltsbewertung** ausfüllen (Fragebogen, dauert fünf Minuten).
6. **Erste Version manuell hochladen.** Google verlangt das, bevor die
   automatische Auslieferung per Dienstkonto funktioniert. Danach übernimmt
   Codemagic.

### Dienstkonto für die Automatisierung

1. In der Play Console: *Einstellungen → API-Zugriff → neues Dienstkonto*.
2. Das führt in die Google Cloud Console – dort Dienstkonto anlegen und einen
   **JSON-Schlüssel** herunterladen.
3. Zurück in der Play Console dem Dienstkonto die Rolle *Release-Manager*
   geben (oder mindestens „Versionen für Testkanäle verwalten").
4. In Codemagic eine Umgebungsvariablen-**Gruppe `google_play`** anlegen mit
   der Variable `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` – Inhalt ist die
   komplette JSON-Datei. **Als „secure" markieren.**

### Datenschutzerklärung

Beide Stores verlangen eine öffentlich erreichbare URL. Da die App nichts
erhebt, reichen wenige Sätze. Am einfachsten über GitHub Pages: eine
`privacy.md` im Repo, Pages aktivieren, URL eintragen. Sag Bescheid, wenn ich
den Text und die Seite anlegen soll.

---

## Schritt 3: Apple App Store einrichten

1. **Apple Developer Program** (99 $/Jahr).
2. **Bundle-ID registrieren:** im Developer Portal unter *Identifiers* die ID
   `de.jakeberg.qrcard` anlegen. Muss exakt stimmen.
3. **App in App Store Connect anlegen**, dieselbe Bundle-ID wählen. Die
   App-ID (die lange Zahl in der URL) in `codemagic.yaml` bei
   `APP_STORE_APPLE_ID` eintragen – dort steht noch `0000000000`.
4. **App-Store-Connect-API-Key** erzeugen: *Benutzer und Zugriff →
   Integrationen → App Store Connect API*, Rolle *App Manager*. Du bekommst
   eine `.p8`-Datei (nur einmal herunterladbar), eine **Key-ID** und eine
   **Issuer-ID**.
5. In Codemagic unter *Integrations → Apple Developer Portal* eintragen und
   als **`visitenkarte_asc`** benennen – so heißt der Verweis in der
   `codemagic.yaml`.
6. **Store-Eintrag** füllen: Untertitel, Werbetext, Beschreibung, Keywords
   (alles in `store/listing-texte.md`), Screenshots und die
   Datenschutz-Angaben („Es werden keine Daten erfasst").

---

## Schritt 4: In Codemagic eintragen

| Was | Wo in Codemagic | Name (muss genau stimmen) |
|---|---|---|
| Android-Keystore | Code signing identities | `visitenkarte_keystore` |
| Play-Dienstkonto | Environment variables, Gruppe | `google_play` → `GCLOUD_SERVICE_ACCOUNT_CREDENTIALS` |
| Apple-API-Key | Integrations | `visitenkarte_asc` |
| Deine Mailadresse | direkt in `codemagic.yaml` | ersetzt `deine@mailadresse.de` |
| Apple App-ID | direkt in `codemagic.yaml` | ersetzt `0000000000` |

---

## Die drei Workflows

| Workflow | Läuft bei | Ergebnis |
|---|---|---|
| `android-apk` | Push auf `main` | APK als Artefakt zum Selbstinstallieren |
| `android-play` | Git-Tag `v*` | App Bundle im internen Play-Testkanal |
| `ios-appstore` | Git-Tag `v*` | Build in TestFlight |

**Eine neue Version veröffentlichen:**

```bash
# Versionsnummer in pubspec.yaml anpassen, z. B. auf 1.1.0+1
git commit -am "Version 1.1.0"
git tag v1.1.0
git push origin main --tags
```

Die Build-Nummer musst du **nicht** hochzählen – beide Store-Workflows fragen
die zuletzt hochgeladene Nummer ab und erhöhen sie selbst. Die *Versionsnummer*
(`1.1.0`) kommt aus `pubspec.yaml` und ist deine Sache.

Beide Workflows laden zunächst nur in den Testkanal und als Entwurf. Erst wenn
du in der `codemagic.yaml` `submit_as_draft: false` bzw.
`submit_to_app_store: true` setzt, geht es wirklich an die Öffentlichkeit.

---

## Checkliste vor der ersten Veröffentlichung

- [ ] Signaturschlüssel erzeugt und sicher gesichert
- [ ] `visitenkarte_keystore` in Codemagic hinterlegt
- [ ] Play-Entwicklerkonto, App mit `de.jakeberg.qrcard` angelegt
- [ ] Erste Version einmal manuell in die Play Console geladen
- [ ] Dienstkonto-JSON als `google_play`-Gruppe in Codemagic
- [ ] Apple Developer Program, Bundle-ID registriert
- [ ] App in App Store Connect angelegt, App-ID in `codemagic.yaml` eingetragen
- [ ] `visitenkarte_asc` in Codemagic hinterlegt
- [ ] Datenschutzerklärung online, URL in beiden Stores eingetragen
- [ ] Store-Texte und Grafiken aus `docs/store/` eingetragen
- [ ] Mailadresse in `codemagic.yaml` ersetzt
