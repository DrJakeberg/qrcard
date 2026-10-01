# Homescreen-Widget und NFC

Zwei Wege, die Visitenkarte weiterzugeben, ohne die App zu öffnen. Beide sind
**auf Android umgesetzt**. Für das iPhone-Widget liegt der Code fertig bereit
und braucht noch ein paar Schritte in Xcode; NFC als Sender geht auf iOS
grundsätzlich nicht. Beides steht unten ehrlich beschrieben.

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
   (`android/app/src/main/kotlin/de/cyb8/qrcode/CardWidgetProvider.kt`)
   lädt das Bild und zeigt es an.

Das Bild wird nur erzeugt, wenn sich die Karte ändert – öfter ist es nicht
nötig. Das Widget zeigt immer das **aktive** Profil.

---

## Homescreen-Widget (iOS)

iOS-Widgets brauchen eine eigene **WidgetKit-Extension**: ein zusätzliches
Programm neben der App, mit eigener Bundle-ID und eigener Sandbox. Flutter
kann darin nicht laufen, der Inhalt ist SwiftUI.

Der komplette Code dafür liegt in
[`ios/widget/CardWidget.swift`](../ios/widget/CardWidget.swift), die Dart-Seite
ist angepasst. Was fehlt, ist das Anlegen des Ziels im Xcode-Projekt – das
geht nur auf einem Mac, dauert aber keine Viertelstunde.

**→ Schritt für Schritt: [`docs/ios-widget.md`](ios-widget.md)**

Ein Unterschied zu Android ist bewusst gewählt: Das iOS-Widget bekommt **kein
fertiges PNG**, sondern erzeugt den QR-Code aus dem vCard-Text selbst
(CoreImage, Fehlerkorrektur M – dieselbe Stufe wie in der App). So muss keine
Datei zwischen zwei Sandboxes wandern, und der Code bleibt in jeder
Widget-Größe scharf. Die Farben des aktiven Profils übernimmt es mit.

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

Der Swift-Code des iOS-Widgets ist **nie kompiliert worden** – es gab keinen
Mac und keine Apple-SDKs. Geprüft sind seine Syntax (mit einem Swift-Parser),
die Schlüsselnamen gegen die Dart-Seite (`test/widget_bridge_test.dart`) und
die Idee, den Code aus dem vCard-Text neu zu erzeugen (unabhängig kodiert und
wieder dekodiert, Ergebnis identisch). Nicht geprüft sind die Aufrufe der
Apple-Bibliotheken selbst.
