//
//  CardWidget.swift
//  Homescreen-Widget der Visitenkarten-App.
//
//  Diese Datei ersetzt den Code, den Xcode beim Anlegen des Ziels
//  "Widget Extension" erzeugt. Die Schritte dazu stehen in docs/ios-widget.md.
//
//  Anders als auf Android wird hier kein fertiges PNG angezeigt: Das Widget
//  liest den Rohtext der vCard aus der geteilten App Group und erzeugt den
//  QR-Code selbst. Das spart die Dateiuebergabe zwischen den Sandkaesten und
//  bleibt in jeder Widget-Groesse scharf.
//

import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import WidgetKit

// MARK: - Gemeinsame Daten

/// App Group und Schluessel muessen zu `WidgetBridge` in
/// lib/services/widget_bridge.dart passen.
private enum Shared {
    static let appGroupId = "group.de.cyb8.qrcode"

    static let vCard = "card_vcard"
    static let name = "card_name"
    static let subtitle = "card_subtitle"
    static let backgroundTop = "card_bg_top"
    static let backgroundBottom = "card_bg_bottom"
    static let foreground = "card_fg"
}

/// Das Widget hat nur fuenf eigene Texte - dafuer lohnt keine Strings-Datei.
private enum Strings {
    private static var isGerman: Bool {
        Locale.preferredLanguages.first?.hasPrefix("de") ?? false
    }

    // Wortgleich mit den Android-Texten in res/values*/strings.xml.
    static var displayName: String { isGerman ? "Visitenkarte" : "Business card" }
    static var description: String {
        isGerman
            ? "Zeigt den QR-Code deiner Visitenkarte zum Abscannen."
            : "Shows the QR code of your business card, ready to scan."
    }

    static var emptyTitle: String {
        isGerman ? "Visitenkarte einrichten" : "Set up your card"
    }

    static var qrDescription: String {
        isGerman ? "QR-Code der Visitenkarte" : "Business card QR code"
    }

    static var hint: String {
        isGerman ? "Mit der Kamera scannen" : "Scan with the camera"
    }
}

// MARK: - Eintrag

struct CardEntry: TimelineEntry {
    let date: Date
    let vCard: String
    let name: String
    let subtitle: String
    let backgroundTop: Color
    let backgroundBottom: Color
    let foreground: Color

    var hasCard: Bool { !vCard.isEmpty }

    /// Farben von `CardStyle.marine`, dem Startzustand der App.
    private static let defaultTop = Color(red: 0.122, green: 0.227, blue: 0.373)
    private static let defaultBottom = Color(red: 0.047, green: 0.102, blue: 0.180)

    /// Vorschau in der Widget-Galerie, bevor echte Daten vorliegen.
    static let preview = CardEntry(
        date: Date(),
        vCard: """
        BEGIN:VCARD
        VERSION:3.0
        N:Morgan;Alex;;;
        FN:Alex Morgan
        TITLE:Head of Engineering
        ORG:Northfield Engineering Ltd
        END:VCARD
        """,
        name: "Alex Morgan",
        subtitle: "Head of Engineering · Northfield Engineering Ltd",
        backgroundTop: defaultTop,
        backgroundBottom: defaultBottom,
        foreground: .white
    )

    /// Liest den aktuellen Stand aus der App Group.
    ///
    /// Fehlt etwas, bleibt es beim Ersatzwert - ein Widget darf nie leer
    /// bleiben, nur weil ein einzelner Schluessel noch nicht geschrieben ist.
    static func load() -> CardEntry {
        let defaults = UserDefaults(suiteName: Shared.appGroupId)
        return CardEntry(
            date: Date(),
            vCard: defaults?.string(forKey: Shared.vCard) ?? "",
            name: defaults?.string(forKey: Shared.name) ?? "",
            subtitle: defaults?.string(forKey: Shared.subtitle) ?? "",
            backgroundTop: Color(hex: defaults?.string(forKey: Shared.backgroundTop)) ?? defaultTop,
            backgroundBottom: Color(hex: defaults?.string(forKey: Shared.backgroundBottom)) ?? defaultBottom,
            foreground: Color(hex: defaults?.string(forKey: Shared.foreground)) ?? .white
        )
    }
}

// MARK: - Zeitplan

struct CardProvider: TimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        CardEntry.preview
    }

    func getSnapshot(in context: Context, completion: @escaping (CardEntry) -> Void) {
        completion(context.isPreview ? CardEntry.preview : CardEntry.load())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CardEntry>) -> Void) {
        // `.never`: Die Karte aendert sich nur, wenn der Nutzer sie aendert -
        // und dann stoesst die App ueber `HomeWidget.updateWidget` selbst ein
        // Neuladen an. Ein Zeitplan waere verschenkte Akkulaufzeit.
        completion(Timeline(entries: [CardEntry.load()], policy: .never))
    }
}

// MARK: - Darstellung

struct CardWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family

    let entry: CardEntry

    var body: some View {
        layout
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .widgetBackground(gradient)
    }

    private var gradient: LinearGradient {
        LinearGradient(
            colors: [entry.backgroundTop, entry.backgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var title: String {
        entry.name.isEmpty ? Strings.emptyTitle : entry.name
    }

    @ViewBuilder
    private var layout: some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 14) {
                qrTile
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(entry.foreground)
                        .lineLimit(2)
                    if !entry.subtitle.isEmpty {
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundColor(entry.foreground.opacity(0.72))
                            .lineLimit(3)
                    }
                    Spacer(minLength: 0)
                    Text(Strings.hint)
                        .font(.caption2)
                        .foregroundColor(entry.foreground.opacity(0.54))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        default:
            VStack(spacing: 5) {
                qrTile
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(entry.foreground)
                    .lineLimit(1)
                if !entry.subtitle.isEmpty {
                    Text(entry.subtitle)
                        .font(.caption2)
                        .foregroundColor(entry.foreground.opacity(0.72))
                        .lineLimit(1)
                }
            }
        }
    }

    /// Der Code bleibt schwarz auf weiss, auch wenn die Karte bunt ist -
    /// Scanner sind darauf ausgelegt.
    private var qrTile: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white)
            if entry.hasCard, let image = QRCode.image(for: entry.vCard) {
                Image(uiImage: image)
                    // Ohne das glaettet iOS die Module und der Code wird
                    // unschaerfer, je groesser das Widget ist.
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(5)
                    .accessibilityLabel(Strings.qrDescription)
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .padding(14)
                    .foregroundColor(.black.opacity(0.22))
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - QR-Code

private enum QRCode {
    private static let context = CIContext()

    /// Erzeugt den Code mit derselben Fehlerkorrektur wie die App (Stufe M).
    static func image(for text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        // CoreImage liefert ein Modul pro Pixel. Hochskaliert, damit aus dem
        // Winzbild ein brauchbares UIImage wird.
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
            return nil
        }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Hilfen

private extension Color {
    /// Liest "#RRGGBB". Alles andere ergibt `nil`, damit der Ersatzwert greift.
    init?(hex: String?) {
        guard var value = hex?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty
        else { return nil }

        if value.hasPrefix("#") { value.removeFirst() }
        guard value.count == 6, let number = UInt32(value, radix: 16) else {
            return nil
        }

        self.init(
            red: Double((number >> 16) & 0xFF) / 255,
            green: Double((number >> 8) & 0xFF) / 255,
            blue: Double(number & 0xFF) / 255
        )
    }
}

private extension View {
    /// Ab iOS 17 muss der Hintergrund eines Widgets als Container-Hintergrund
    /// gesetzt werden, sonst zeichnet das System seinen eigenen darueber.
    @ViewBuilder
    func widgetBackground<S: ShapeStyle>(_ style: S) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(style, for: .widget)
        } else {
            background(style)
        }
    }
}

// MARK: - Einstieg

struct CardWidget: Widget {
    /// Muss zu `WidgetBridge.iosWidgetName` passen, sonst erreicht das
    /// Neuladen aus der App dieses Widget nicht.
    private let kind = "CardWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CardProvider()) { entry in
            CardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(Strings.displayName)
        .description(Strings.description)
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct CardWidgetBundle: WidgetBundle {
    var body: some Widget {
        CardWidget()
    }
}
