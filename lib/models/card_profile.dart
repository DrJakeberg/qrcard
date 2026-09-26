import 'dart:convert';

import 'card_style.dart';
import 'contact_card.dart';

/// Eine gespeicherte Visitenkarte samt Namen und Farben.
///
/// Mehrere Profile erlauben es, z. B. zwischen Firmen- und Privatkarte zu
/// wechseln, ohne die Daten jedes Mal neu einzutippen.
class CardProfile {
  const CardProfile({
    required this.id,
    required this.name,
    required this.card,
    required this.style,
  });

  factory CardProfile.fromJson(Map<String, dynamic> json) {
    final card = json['card'];
    final style = json['style'];
    return CardProfile(
      id: (json['id'] as String?)?.trim().isNotEmpty == true
          ? json['id'] as String
          : newId(),
      name: (json['name'] as String?)?.trim() ?? '',
      card: card is Map<String, dynamic>
          ? ContactCard.fromJson(card)
          : const ContactCard(),
      style: style is Map<String, dynamic>
          ? CardStyle.fromJson(style)
          : CardStyle.marine,
    );
  }

  final String id;

  /// Frei waehlbarer Name, z. B. "Firma" oder "Privat".
  final String name;
  final ContactCard card;
  final CardStyle style;

  /// Name fuer die Anzeige - faellt auf den Personennamen bzw. die Firma
  /// zurueck, solange kein eigener Profilname gesetzt ist.
  String displayName({required String fallback}) {
    if (name.isNotEmpty) return name;
    if (card.fullName.isNotEmpty) return card.fullName;
    if (card.company.isNotEmpty) return card.company;
    return fallback;
  }

  CardProfile copyWith({String? name, ContactCard? card, CardStyle? style}) {
    return CardProfile(
      id: id,
      name: name ?? this.name,
      card: card ?? this.card,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'card': card.toJson(),
    'style': style.toJson(),
  };

  /// Erzeugt eine hinreichend eindeutige ID aus Zeitstempel und Zufall.
  static String newId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return 'p$now${now.hashCode.abs() % 997}';
  }
}

/// Alle Profile plus die Angabe, welches gerade angezeigt wird.
class ProfileSet {
  const ProfileSet({required this.profiles, required this.activeId});

  factory ProfileSet.fromJson(Map<String, dynamic> json) {
    final raw = json['profiles'];
    final parsed = <CardProfile>[
      if (raw is List)
        for (final entry in raw)
          if (entry is Map<String, dynamic>) CardProfile.fromJson(entry),
    ];
    if (parsed.isEmpty) return ProfileSet.initial();

    final activeId = json['activeId'] as String?;
    final exists = parsed.any((p) => p.id == activeId);
    return ProfileSet(
      profiles: parsed,
      activeId: exists ? activeId! : parsed.first.id,
    );
  }

  /// Liest einen gespeicherten Stand. Bei defekten Daten wird ein frischer
  /// Satz zurueckgegeben, damit die App immer startet.
  factory ProfileSet.decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return ProfileSet.fromJson(decoded);
    } on FormatException {
      // Ignorieren - es wird der Startzustand verwendet.
    }
    return ProfileSet.initial();
  }

  /// Der Zustand beim allerersten Start: genau ein leeres Profil.
  factory ProfileSet.initial() {
    final profile = CardProfile(
      id: CardProfile.newId(),
      name: '',
      card: const ContactCard(),
      style: CardStyle.marine,
    );
    return ProfileSet(profiles: [profile], activeId: profile.id);
  }

  final List<CardProfile> profiles;
  final String activeId;

  CardProfile get active => profiles.firstWhere(
    (p) => p.id == activeId,
    orElse: () => profiles.first,
  );

  int get activeIndex {
    final index = profiles.indexWhere((p) => p.id == activeId);
    return index == -1 ? 0 : index;
  }

  bool get canDelete => profiles.length > 1;

  /// Ersetzt ein Profil anhand seiner ID.
  ProfileSet replace(CardProfile profile) {
    return ProfileSet(
      profiles: [
        for (final existing in profiles)
          existing.id == profile.id ? profile : existing,
      ],
      activeId: activeId,
    );
  }

  ProfileSet add(CardProfile profile) {
    return ProfileSet(profiles: [...profiles, profile], activeId: profile.id);
  }

  /// Entfernt ein Profil. Das letzte verbleibende bleibt erhalten.
  ProfileSet remove(String id) {
    if (profiles.length <= 1) return this;
    final remaining = profiles.where((p) => p.id != id).toList();
    return ProfileSet(
      profiles: remaining,
      activeId: activeId == id ? remaining.first.id : activeId,
    );
  }

  ProfileSet select(String id) {
    if (!profiles.any((p) => p.id == id)) return this;
    return ProfileSet(profiles: profiles, activeId: id);
  }

  /// Wechselt zum naechsten Profil (fuer das Wischen auf der Karte).
  ProfileSet next() {
    if (profiles.length < 2) return this;
    final index = (activeIndex + 1) % profiles.length;
    return select(profiles[index].id);
  }

  ProfileSet previous() {
    if (profiles.length < 2) return this;
    final index = (activeIndex - 1 + profiles.length) % profiles.length;
    return select(profiles[index].id);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'activeId': activeId,
    'profiles': [for (final profile in profiles) profile.toJson()],
  };

  String encode() => jsonEncode(toJson());
}
