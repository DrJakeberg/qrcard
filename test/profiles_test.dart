import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qrcard/models/card_profile.dart';
import 'package:qrcard/models/card_style.dart';
import 'package:qrcard/l10n/app_localizations.dart';
import 'package:qrcard/l10n/locale_fallback.dart';
import 'package:qrcard/models/contact_card.dart';

CardProfile _profile(String id, {String name = ''}) => CardProfile(
  id: id,
  name: name,
  card: ContactCard(firstName: 'Jake', lastName: id),
  style: CardStyle.marine,
);

void main() {
  group('ProfileSet', () {
    test('startet mit genau einem Profil', () {
      final set = ProfileSet.initial();
      expect(set.profiles, hasLength(1));
      expect(set.activeId, set.profiles.first.id);
    });

    test('ueberlebt Speichern und Laden mitsamt Farben', () {
      final set = ProfileSet(
        profiles: [
          _profile('a').copyWith(style: CardStyle.bordeaux),
          _profile('b'),
        ],
        activeId: 'b',
      );
      final restored = ProfileSet.decode(set.encode());

      expect(restored.profiles, hasLength(2));
      expect(restored.activeId, 'b');
      expect(restored.profiles.first.style, CardStyle.bordeaux);
    });

    test('faengt defekte Daten ab', () {
      expect(ProfileSet.decode('kein json').profiles, hasLength(1));
    });

    test('faellt auf das erste Profil zurueck, wenn die aktive ID fehlt', () {
      final set = ProfileSet(profiles: [_profile('a')], activeId: 'weg');
      final restored = ProfileSet.decode(set.encode());
      expect(restored.activeId, 'a');
    });

    test('wechselt vorwaerts und rueckwaerts im Kreis', () {
      var set = ProfileSet(
        profiles: [_profile('a'), _profile('b'), _profile('c')],
        activeId: 'a',
      );
      set = set.next();
      expect(set.activeId, 'b');
      set = set.next().next();
      expect(
        set.activeId,
        'a',
        reason: 'nach dem letzten kommt wieder das erste',
      );
      set = set.previous();
      expect(set.activeId, 'c');
    });

    test('wechselt nicht, wenn es nur ein Profil gibt', () {
      final set = ProfileSet(profiles: [_profile('a')], activeId: 'a');
      expect(set.next().activeId, 'a');
      expect(set.previous().activeId, 'a');
    });

    test('das letzte Profil laesst sich nicht loeschen', () {
      final set = ProfileSet(profiles: [_profile('a')], activeId: 'a');
      expect(set.canDelete, isFalse);
      expect(set.remove('a').profiles, hasLength(1));
    });

    test('nach dem Loeschen des aktiven Profils ist ein anderes aktiv', () {
      final set = ProfileSet(
        profiles: [_profile('a'), _profile('b')],
        activeId: 'a',
      );
      final reduced = set.remove('a');
      expect(reduced.profiles, hasLength(1));
      expect(reduced.activeId, 'b');
    });

    test('ein neues Profil wird direkt aktiv', () {
      final set = ProfileSet(profiles: [_profile('a')], activeId: 'a');
      expect(set.add(_profile('b')).activeId, 'b');
    });

    test('replace tauscht nur das passende Profil', () {
      final set = ProfileSet(
        profiles: [_profile('a'), _profile('b')],
        activeId: 'a',
      );
      final updated = set.replace(_profile('b', name: 'Privat'));
      expect(updated.profiles.first.name, isEmpty);
      expect(updated.profiles.last.name, 'Privat');
    });
  });

  group('CardProfile', () {
    test('faellt beim Anzeigenamen sinnvoll zurueck', () {
      const fallback = 'Ohne Namen';
      expect(
        _profile('a', name: 'Firma').displayName(fallback: fallback),
        'Firma',
      );
      expect(_profile('a').displayName(fallback: fallback), 'Jake a');
      expect(
        const CardProfile(
          id: 'x',
          name: '',
          card: ContactCard(company: 'Muster GmbH'),
          style: CardStyle.marine,
        ).displayName(fallback: fallback),
        'Muster GmbH',
      );
      expect(
        const CardProfile(
          id: 'x',
          name: '',
          card: ContactCard(),
          style: CardStyle.marine,
        ).displayName(fallback: fallback),
        fallback,
      );
    });
  });

  group('CardStyle', () {
    test('ueberlebt Speichern und Laden', () {
      final restored = CardStyle.fromJson(CardStyle.forest.toJson());
      expect(restored, CardStyle.forest);
    });

    test('erkennt zu schwachen Kontrast', () {
      const unreadable = CardStyle(
        backgroundTop: Color(0xFFFFFFFF),
        backgroundBottom: Color(0xFFFFFFFF),
        text: Color(0xFFF0F0F0),
        accent: Color(0xFF888888),
      );
      expect(unreadable.hasPoorContrast, isTrue);
    });

    test('alle mitgelieferten Vorlagen sind gut lesbar', () {
      const presets = [
        CardStyle.marine,
        CardStyle.graphite,
        CardStyle.bordeaux,
        CardStyle.forest,
        CardStyle.sand,
        CardStyle.paper,
      ];
      for (final preset in presets) {
        expect(
          preset.hasPoorContrast,
          isFalse,
          reason:
              'Kontrast ${preset.textContrast.toStringAsFixed(1)}:1 zu gering',
        );
      }
    });

    test('erkennt helle Hintergruende fuer die Status-Bar', () {
      expect(CardStyle.paper.isLight, isTrue);
      expect(CardStyle.sand.isLight, isTrue);
      expect(CardStyle.marine.isLight, isFalse);
      expect(CardStyle.graphite.isLight, isFalse);
    });
  });

  group('Sprachauswahl', () {
    const supported = [Locale('de'), Locale('en')];

    test('nimmt die Systemsprache, wenn sie uebersetzt ist', () {
      expect(resolveLocale(const Locale('de'), supported), const Locale('de'));
      expect(resolveLocale(const Locale('en'), supported), const Locale('en'));
    });

    test('ignoriert das Land, wenn nur die Sprache passt', () {
      expect(
        resolveLocale(const Locale('de', 'AT'), supported),
        const Locale('de'),
      );
      expect(
        resolveLocale(const Locale('en', 'GB'), supported),
        const Locale('en'),
      );
    });

    test('faellt bei fremden Sprachen auf Englisch zurueck', () {
      expect(resolveLocale(const Locale('fr'), supported), const Locale('en'));
      expect(resolveLocale(const Locale('ja'), supported), const Locale('en'));
      expect(resolveLocale(null, supported), const Locale('en'));
    });

    test('deckt die tatsaechlich unterstuetzten Sprachen ab', () {
      expect(AppLocalizations.supportedLocales, contains(const Locale('de')));
      expect(AppLocalizations.supportedLocales, contains(const Locale('en')));
    });
  });
}
