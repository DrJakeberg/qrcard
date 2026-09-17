# Homescreen-Widget und NFC

Zwei Wege, die Visitenkarte weiterzugeben, ohne die App zu öffnen. Beide sind
**auf Android umgesetzt**. Bei iOS gibt es harte Plattformgrenzen – die stehen
unten ehrlich beschrieben.

---

## Homescreen-Widget (Android)

Legt den QR-Code direkt auf den Startbildschirm. Antippen öffnet die App.

**So fügst du es hinzu:** Lange auf eine freie Stelle des Startbildschirms
tippen → *Widgets* → *Visitenkarte* → auf den Startbildschirm ziehen. Es lässt
sich frei in der Größe ziehen.

### Wie es funktioniert

Ein Android-Widget kann kein Flutter darstellen – es kennt nur einfache
Bausteine wie Bild und Text. Deshalb:

1. Beim Speichern einer Karte rendert die App den QR-Code als PNG
   (`lib/services/widget_bridge.dart`) und legt den Dateipfad zusammen mit
   Name und Untertitel ab.
2. Der Widget-Anbieter in Kotlin
   (`android/app/src/main/kotlin/de/jakeberg/qrcard/CardWidgetProvider.kt`)
   lädt das Bild und zeigt es an.

Das Bild wird nur erzeugt, wenn sich die Karte ändert – öfter ist es nicht
nötig. Das Widget zeigt immer das **aktive** Profil.

### iOS

iOS-Widgets brauchen eine eigene **WidgetKit-Extension**, also ein zusätzliches
Ziel im Xcode-Projekt. Das lässt sich nicht durch Bearbeiten von Textdateien
zuverlässig anlegen, sondern nur in Xcode selbst:

1. `ios/Runner.xcworkspace` in Xcode öffnen
2. *File → New → Target… → Widget Extension*
3. In der Extension das Bild aus einer geteilten App-Group lesen; dafür in der
   App `HomeWidget.setAppGroupId(...)` aufrufen und dieselbe App-Group in
   beiden Zielen aktivieren.

Das Paket `home_widget` ist bereits eingebunden und unterstützt genau diesen
Aufbau – es fehlt nur der Xcode-Schritt.

---

## NFC: Karte durch Antippen übertragen (Android)

Das Telefon gibt sich als NFC-Tag aus. Hältst du es an ein anderes Gerät,
liest dieses die Visitenkarte – ohne dass du etwas scannen musst.

**Voraussetzungen:** Android-Telefon mit NFC, NFC in den Einstellungen
aktiviert, Bildschirm an und entsperrt.

### Wie es funktioniert

`CardApduService.kt` bildet den Standard **NFC Forum Type 4 Tag** nach. Das
lesende Gerät wählt nacheinander die NDEF-Anwendung, die Beschreibungsdatei und
die Datendatei aus; der Dienst antwortet mit einer NDEF-Nachricht, die einen
`text/vcard`-Datensatz mit derselben vCard enthält, die auch im QR-Code steckt.
Die vCard kommt aus demselben Speicher wie die Widget-Daten – es gibt nur eine
Quelle für die Kartendaten.

### Was auf welcher Gegenstelle klappt

| Gegenstelle | Ergebnis |
|---|---|
| Android-Telefon | Liest die Karte zuverlässig |
| iPhone mit NFC-Reader-App | Liest die Karte |
| iPhone ohne App (Hintergrund-Erkennung) | Unzuverlässig – iOS zeigt die Banner-Meldung vor allem bei Webadressen, nicht bei `text/vcard` |

Für ein iPhone-Gegenüber ist der **QR-Code der sichere Weg** – den liest die
Kamera-App ohne Zusatzsoftware.

### iOS als Sender: geht nicht

Ein iPhone kann **nicht** als NFC-Tag auftreten. Apple gibt die dafür nötige
Host Card Emulation für NDEF nicht frei; Core NFC kann nur lesen und
physische Tags beschreiben. Das ist keine Lücke in dieser App, sondern eine
Einschränkung der Plattform. Auf einem iPhone bleibt der QR-Code der Weg,
die Karte weiterzugeben.

---

## Was noch nicht geprüft ist

Widget und NFC sind **nicht auf echter Hardware getestet** – in der
Entwicklungsumgebung gab es kein Android-Gerät mit NFC. Geprüft ist:

- dass der QR-Code, den das Widget anzeigt, sich zu einer korrekten vCard
  dekodieren lässt (`docs/widget_qr.png`, gegengeprüft mit einem unabhängigen
  Decoder),
- dass der Android-Build mit Widget und NFC-Dienst durchläuft (GitHub Actions).

Was ein Gerätetest noch zeigen müsste: ob das Widget in der Widget-Liste
auftaucht und sich aktualisiert, und ob die NFC-Übertragung mit einem echten
Gegengerät funktioniert.
