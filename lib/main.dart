import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_fallback.dart';
import 'models/card_profile.dart';
import 'screens/card_screen.dart';
import 'services/card_storage.dart';
import 'services/widget_bridge.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QrCardApp());
}

class QrCardApp extends StatefulWidget {
  const QrCardApp({super.key});

  @override
  State<QrCardApp> createState() => _QrCardAppState();
}

class _QrCardAppState extends State<QrCardApp> {
  final CardStorage _storage = CardStorage();

  ProfileSet _profiles = ProfileSet.initial();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profiles = await _storage.load();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _loading = false;
    });
    // Widget und NFC-Uebertragung auf den aktuellen Stand bringen.
    await WidgetBridge.update(profiles.active);
  }

  Future<void> _updateProfiles(ProfileSet profiles) async {
    setState(() => _profiles = profiles);
    await _storage.save(profiles);
    await _storage.removeOrphanedPhotos(profiles);
    await WidgetBridge.update(profiles.active);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,

      // Die App folgt der Sprache des Telefons. Fuer alles ausser Deutsch
      // greift Englisch - das regelt Flutter ueber die Liste unten selbst.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,

      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: _loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : CardScreen(
              profiles: _profiles,
              storage: _storage,
              onProfilesChanged: _updateProfiles,
            ),
    );
  }
}
