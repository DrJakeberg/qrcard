# iPhone-Widget einrichten

Der QR-Code auf dem iPhone-Homescreen – das Gegenstück zum Android-Widget.
Der ganze Code liegt fertig in
[`ios/widget/CardWidget.swift`](../ios/widget/CardWidget.swift). Was bleibt,
sind ein paar Schritte in Xcode, die sich **nur auf einem Mac** erledigen
lassen. Rechne mit zehn bis fünfzehn Minuten.

> **Warum nicht fertig eingebaut?** Ein iOS-Widget ist ein eigenes Programm
> neben der App – ein zusätzliches *Target* im Xcode-Projekt. Das anzulegen
> heißt, `ios/Runner.xcodeproj/project.pbxproj` umzuschreiben, eine generierte
> Datei voller Querverweise. Von Hand ist das riskant, und ohne Mac lässt es
> sich nicht gegenprüfen. Der Assistent in Xcode erledigt es in einem Dialog
> zuverlässig – deshalb dieser Weg.

---

## 1. App Group anlegen

App und Widget sind zwei getrennte Programme mit getrennten Sandboxes. Sie
kommen nur über eine **App Group** aneinander – einen gemeinsamen Datentopf.

Der Name ist im Code bereits festgelegt:

```
group.de.cyb8.qrcode
```

Du kannst die Gruppe vorab unter
[developer.apple.com](https://developer.apple.com/account/resources/identifiers/list/applicationGroup)
anlegen (*Identifiers → + → App Groups*) oder sie in Schritt 3 direkt aus
Xcode heraus erzeugen lassen. Beides führt zum selben Ergebnis.

## 2. Target anlegen

```bash
open ios/Runner.xcworkspace     # das Workspace, nicht das Projekt
```

*File → New → Target… → iOS → Widget Extension → Next*

| Feld | Wert |
|---|---|
| Product Name | `CardWidget` |
| Team | dein Entwicklerteam |
| Include Configuration App Intent | **abwählen** |
| Include Live Activity | **abwählen** |

*Finish* – und beim anschließenden „Activate scheme?" ruhig *Activate*.

## 3. Generierten Code durch den fertigen ersetzen

Xcode legt eine Gruppe `CardWidget` mit Beispielcode an. Der kommt weg:

1. In der Gruppe `CardWidget` diese Dateien markieren und *Move to Trash*:
   `CardWidget.swift`, `CardWidgetBundle.swift` sowie – falls vorhanden –
   `CardWidgetControl.swift` und `AppIntent.swift`.
   **`Info.plist` und `Assets.xcassets` bleiben.**
2. `ios/widget/CardWidget.swift` aus dem Finder in die Gruppe `CardWidget`
   ziehen. Im Dialog:
   - **„Copy items if needed" abwählen** – die Datei bleibt dort, wo Git sie
     kennt, und es gibt sie weiterhin nur einmal.
   - Bei *Add to targets* nur **`CardWidget`** ankreuzen, nicht `Runner`.

## 4. App Group auf beiden Zielen aktivieren

Das ist der Schritt, der am leichtesten vergessen wird – und ohne ihn bleibt
das Widget leer.

Für **beide** Targets (`Runner` **und** `CardWidget`) jeweils:

*Target auswählen → Signing & Capabilities → + Capability → App Groups*, dann
`group.de.cyb8.qrcode` ankreuzen (bzw. über das kleine **+** anlegen).

Danach gibt es zwei neue Dateien (`Runner.entitlements`,
`CardWidget.entitlements`) – die gehören mit ins Repository.

## 5. Mindestversion angleichen

*Target `CardWidget` → General → Minimum Deployments → iOS* auf **15.0**
setzen, passend zur App. Xcode trägt sonst gern die neueste Version ein, und
das Widget wäre auf älteren iPhones nicht verfügbar.

## 6. Bauen und ausprobieren

Auf einem echten Gerät bauen, die App **einmal starten** (erst dadurch landen
die Kartendaten in der App Group), dann:

Lange auf eine freie Stelle des Homescreens tippen → **+** → nach
*Visitenkarte* suchen → Größe wählen → *Widget hinzufügen*.

Es gibt zwei Größen: klein (nur QR-Code mit Namen) und mittel (QR-Code links,
Name, Position und Firma rechts).

---

## Was nicht nötig ist

- **Kein `pod install`.** Die Extension benutzt keine Flutter-Plugins, nur
  SwiftUI, WidgetKit und CoreImage – alles aus dem System.
- **Kein Eintrag in der `Podfile`.**
- **Keine Änderung am Dart-Code.** Der ist schon fertig: `WidgetBridge` ruft
  `HomeWidget.setAppGroupId(...)` auf und stößt nach jedem Speichern ein
  Neuladen des Widgets an.

## Wie es funktioniert

Anders als auf Android bekommt das Widget **kein fertiges Bild**. Es liest den
Rohtext der vCard aus der App Group und erzeugt den QR-Code selbst mit
CoreImage:

```swift
let filter = CIFilter.qrCodeGenerator()
filter.message = Data(text.utf8)
filter.correctionLevel = "M"
```

Das hat drei Vorteile: keine Datei muss zwischen zwei Sandboxes wandern, der
Code bleibt in jeder Widget-Größe scharf, und es gibt weiterhin nur **eine**
Quelle für die Kartendaten.

Diese Schlüssel teilen sich Dart und Swift:

| Schlüssel | Inhalt |
|---|---|
| `card_vcard` | der vCard-Text, aus dem der QR-Code entsteht |
| `card_name` | Name für die Beschriftung |
| `card_subtitle` | Position · Firma |
| `card_bg_top`, `card_bg_bottom` | Hintergrundverlauf als `#RRGGBB` |
| `card_fg` | Schriftfarbe als `#RRGGBB` |

Das Widget übernimmt damit die Farben des aktiven Profils. Der QR-Code selbst
bleibt schwarz auf weiß – Scanner sind darauf ausgelegt.

Der Zeitplan steht auf `.never`: Die Karte ändert sich nur, wenn du sie
änderst, und dann fordert die App das Neuladen selbst an. Das spart Akku
gegenüber einem festen Aktualisierungsintervall.

## Wenn es nicht klappt

| Symptom | Ursache |
|---|---|
| Widget bleibt leer, zeigt „Noch keine Karte" | App Group fehlt auf einem der beiden Targets (Schritt 4), oder die App wurde nach dem Einbau noch nicht gestartet |
| Widget taucht in der Galerie nicht auf | Mindestversion zu hoch (Schritt 5), oder die Extension wurde nicht mitinstalliert – App löschen und neu bauen |
| Build bricht mit „ambiguous `@main`" ab | In Schritt 3 blieb eine von Xcode generierte Datei liegen |
| Signierungsfehler zur App Group | Die Gruppe ist im Developer-Portal nicht angelegt, oder das Provisioning-Profil ist älter als die Gruppe – in Xcode *Signing* einmal neu auflösen lassen |
| Farben stimmen nicht | Ältere Daten in der App Group; Karte einmal speichern |

## Ehrlich gesagt

Dieser Swift-Code ist **nie kompiliert worden** – in der Entwicklungsumgebung
gab es keinen Mac und keine Apple-SDKs. Geprüft ist:

- die **Syntax**, mit einem Swift-Parser (tree-sitter), fehlerfrei;
- die **Grundidee**, den QR-Code aus dem vCard-Text neu zu erzeugen statt ein
  Bild zu übergeben: dieselbe Nutzlast, unabhängig kodiert (Fehlerkorrektur M,
  UTF-8-Bytes wie bei `Data(text.utf8)`) und wieder dekodiert, ergibt exakt
  den Ausgangstext – samt Umlaut und maskiertem Semikolon in der Adresse;
- die **Schlüsselnamen** zwischen Dart, Kotlin und Swift, durch einen Test
  (`test/widget_bridge_test.dart`), der bei einer Umbenennung auf einer Seite
  fehlschlägt.

Nicht geprüft sind die Aufrufe der Apple-Bibliotheken selbst. Rechne damit,
dass beim ersten Build in Xcode noch eine Kleinigkeit auffällt.
