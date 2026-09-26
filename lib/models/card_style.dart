import 'dart:math' as math;
import 'dart:ui';

/// Die Farben einer Visitenkarte.
///
/// Der QR-Code ist bewusst nicht einfaerbbar - er bleibt immer schwarz auf
/// weiss, weil Scanner darauf ausgelegt sind.
class CardStyle {
  const CardStyle({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.text,
    required this.accent,
  });

  factory CardStyle.fromJson(Map<String, dynamic> json) {
    int read(String key, int fallback) {
      final value = json[key];
      return value is int ? value : fallback;
    }

    const fallback = CardStyle.marine;
    return CardStyle(
      backgroundTop: Color(
        read('backgroundTop', fallback.backgroundTop.toARGB32()),
      ),
      backgroundBottom: Color(
        read('backgroundBottom', fallback.backgroundBottom.toARGB32()),
      ),
      text: Color(read('text', fallback.text.toARGB32())),
      accent: Color(read('accent', fallback.accent.toARGB32())),
    );
  }

  /// Oberer Verlaufston des Hintergrunds.
  final Color backgroundTop;

  /// Unterer Verlaufston des Hintergrunds.
  final Color backgroundBottom;

  /// Farbe von Name, Firma und Kontaktzeilen.
  final Color text;

  /// Farbe fuer Position, Icons und Hervorhebungen.
  final Color accent;

  static const CardStyle marine = CardStyle(
    backgroundTop: Color(0xFF1F3A5F),
    backgroundBottom: Color(0xFF0C1A2E),
    text: Color(0xFFFFFFFF),
    accent: Color(0xFF6FB4F5),
  );

  static const CardStyle graphite = CardStyle(
    backgroundTop: Color(0xFF3A3F44),
    backgroundBottom: Color(0xFF17191C),
    text: Color(0xFFF5F5F5),
    accent: Color(0xFFB0BEC5),
  );

  static const CardStyle bordeaux = CardStyle(
    backgroundTop: Color(0xFF5E2130),
    backgroundBottom: Color(0xFF26090F),
    text: Color(0xFFFDF2F4),
    accent: Color(0xFFE79AAA),
  );

  static const CardStyle forest = CardStyle(
    backgroundTop: Color(0xFF24503F),
    backgroundBottom: Color(0xFF0D2119),
    text: Color(0xFFF1F7F3),
    accent: Color(0xFF7FCBA4),
  );

  static const CardStyle sand = CardStyle(
    backgroundTop: Color(0xFFE8DCC8),
    backgroundBottom: Color(0xFFC9B79A),
    text: Color(0xFF2E2415),
    accent: Color(0xFF8A6A32),
  );

  static const CardStyle paper = CardStyle(
    backgroundTop: Color(0xFFFFFFFF),
    backgroundBottom: Color(0xFFE9ECEF),
    text: Color(0xFF1B1F24),
    accent: Color(0xFF2F6FB0),
  );

  /// Ein heller Hintergrund braucht dunkle Status-Bar-Symbole.
  bool get isLight => _luminanceOf(backgroundTop) > 0.5;

  /// Abgeschwaechte Schriftfarbe fuer Nebensaechliches (Firma, Hinweise).
  Color get mutedText => text.withValues(alpha: 0.72);

  /// Noch dezenter - fuer den Hinweis unter dem QR-Code.
  Color get faintText => text.withValues(alpha: 0.54);

  /// Kontrast zwischen Schrift und Hintergrund nach WCAG.
  ///
  /// Gemessen wird gegen den helleren der beiden Verlaufstoene, denn dort ist
  /// der Kontrast am ungünstigsten.
  double get textContrast {
    final background =
        _luminanceOf(backgroundTop) > _luminanceOf(backgroundBottom)
        ? backgroundTop
        : backgroundBottom;
    final a = _luminanceOf(text);
    final b = _luminanceOf(background);
    final lighter = a > b ? a : b;
    final darker = a > b ? b : a;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Unter 3:1 ist die Karte praktisch nicht mehr lesbar.
  bool get hasPoorContrast => textContrast < 3.0;

  CardStyle copyWith({
    Color? backgroundTop,
    Color? backgroundBottom,
    Color? text,
    Color? accent,
  }) {
    return CardStyle(
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      text: text ?? this.text,
      accent: accent ?? this.accent,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'backgroundTop': backgroundTop.toARGB32(),
    'backgroundBottom': backgroundBottom.toARGB32(),
    'text': text.toARGB32(),
    'accent': accent.toARGB32(),
  };

  @override
  bool operator ==(Object other) =>
      other is CardStyle &&
      other.backgroundTop == backgroundTop &&
      other.backgroundBottom == backgroundBottom &&
      other.text == text &&
      other.accent == accent;

  @override
  int get hashCode =>
      Object.hash(backgroundTop, backgroundBottom, text, accent);
}

/// Relative Leuchtdichte nach WCAG 2.1.
double _luminanceOf(Color color) {
  double channel(double value) {
    return value <= 0.03928
        ? value / 12.92
        : math.pow((value + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * channel(color.r) +
      0.7152 * channel(color.g) +
      0.0722 * channel(color.b);
}
