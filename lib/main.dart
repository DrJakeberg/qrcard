import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models/contact_card.dart';
import 'screens/card_screen.dart';
import 'services/card_storage.dart';
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

  ContactCard _card = const ContactCard();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final card = await _storage.load();
    if (!mounted) return;
    setState(() {
      _card = card;
      _loading = false;
    });
  }

  Future<void> _updateCard(ContactCard card) async {
    setState(() => _card = card);
    await _storage.save(card);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Visitenkarte',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      home: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: _loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : CardScreen(
                card: _card,
                storage: _storage,
                onCardChanged: _updateCard,
              ),
      ),
    );
  }
}
