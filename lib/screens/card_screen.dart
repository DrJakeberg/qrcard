import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/contact_card.dart';
import '../services/card_storage.dart';
import '../services/vcard.dart';
import '../widgets/qr_panel.dart';
import 'edit_screen.dart';
import 'qr_fullscreen.dart';

/// Farben der Visitenkarte. Bewusst unabhaengig vom Hell-/Dunkel-Modus, damit
/// die Karte immer gleich aussieht - wie eine gedruckte Karte.
const Color _cardTop = Color(0xFF1F3A5F);
const Color _cardBottom = Color(0xFF0C1A2E);
const Color _accent = Color(0xFF6FB4F5);

/// Die Visitenkarte - alles auf genau einer Seite, ohne Scrollen.
class CardScreen extends StatefulWidget {
  const CardScreen({
    required this.card,
    required this.storage,
    required this.onCardChanged,
    super.key,
  });

  final ContactCard card;
  final CardStorage storage;
  final ValueChanged<ContactCard> onCardChanged;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  @override
  void initState() {
    super.initState();
    // Beim allerersten Start direkt die Eingabemaske oeffnen.
    if (widget.card.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
    }
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<ContactCard>(
      MaterialPageRoute<ContactCard>(
        builder: (_) => EditScreen(card: widget.card, storage: widget.storage),
      ),
    );
    if (result != null) widget.onCardChanged(result);
  }

  void _openFullscreenQr() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QrFullscreenScreen(card: widget.card),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konnte nicht geoeffnet werden.')),
      );
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label kopiert'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<_Detail> get _details {
    final card = widget.card;
    return <_Detail>[
      if (card.addressBlock.isNotEmpty)
        _Detail(
          icon: Icons.location_on_outlined,
          label: 'Adresse',
          text: card.addressBlock,
          lines: 2,
        ),
      if (card.phone.isNotEmpty)
        _Detail(
          icon: Icons.phone_outlined,
          label: 'Telefon',
          text: card.phone,
          uri: Uri(scheme: 'tel', path: card.phone.replaceAll(' ', '')),
        ),
      if (card.mobile.isNotEmpty)
        _Detail(
          icon: Icons.smartphone_outlined,
          label: 'Mobil',
          text: card.mobile,
          uri: Uri(scheme: 'tel', path: card.mobile.replaceAll(' ', '')),
        ),
      if (card.email.isNotEmpty)
        _Detail(
          icon: Icons.mail_outline,
          label: 'E-Mail',
          text: card.email,
          uri: Uri(scheme: 'mailto', path: card.email),
        ),
      if (card.website.isNotEmpty)
        _Detail(
          icon: Icons.language,
          label: 'Web',
          text: card.website,
          uri: Uri.tryParse(websiteUrl(card.website)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final vCard = buildVCard(widget.card);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cardTop, _cardBottom],
          ),
        ),
        child: SafeArea(
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.2,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final landscape = constraints.maxWidth > constraints.maxHeight;
                return Column(
                  children: [
                    _buildToolbar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: landscape
                            ? _buildLandscape(vCard)
                            : _buildPortrait(vCard),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _openEditor,
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Visitenkarte bearbeiten',
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- Hochformat
  Widget _buildPortrait(String vCard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final avatarSize = (h * 0.16).clamp(56.0, 108.0);
        final qrSize = math.min(w * 0.62, h * 0.32).clamp(104.0, 260.0);
        final gap = (h * 0.025).clamp(8.0, 22.0);

        return Column(
          children: [
            _Identity(card: widget.card, avatarSize: avatarSize, maxHeight: h),
            SizedBox(height: gap),
            QrPanel(data: vCard, size: qrSize, onTap: _openFullscreenQr),
            const SizedBox(height: 8),
            const _ScanHint(),
            SizedBox(height: gap),
            Expanded(child: _buildDetails()),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------- Querformat
  Widget _buildLandscape(String vCard) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        final avatarSize = (h * 0.24).clamp(48.0, 96.0);
        final qrSize = math.min(w * 0.34, h * 0.78).clamp(104.0, 260.0);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Identity(
                    card: widget.card,
                    avatarSize: avatarSize,
                    maxHeight: h * 0.5,
                    alignLeft: true,
                  ),
                  SizedBox(height: (h * 0.04).clamp(6.0, 18.0)),
                  Flexible(child: _buildDetails()),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrPanel(data: vCard, size: qrSize, onTap: _openFullscreenQr),
                const SizedBox(height: 8),
                const _ScanHint(),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Die Kontaktzeilen. Die Zeilenhoehe wird aus dem verfuegbaren Platz
  /// berechnet - dadurch passt der Block immer auf die Seite.
  Widget _buildDetails() {
    final details = _details;
    if (details.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _openEditor,
          icon: const Icon(Icons.add, color: _accent),
          label: const Text(
            'Kontaktdaten hinzufuegen',
            style: TextStyle(color: _accent),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWeight = details.fold<int>(
          0,
          (sum, detail) => sum + detail.lines,
        );
        final unit = constraints.maxHeight / totalWeight;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final detail in details)
              SizedBox(
                height: unit * detail.lines,
                child: _DetailRow(
                  detail: detail,
                  onTap: detail.uri == null ? null : () => _launch(detail.uri!),
                  onLongPress: () => _copy(detail.label, detail.text),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Foto, Name, Position und Firma.
class _Identity extends StatelessWidget {
  const _Identity({
    required this.card,
    required this.avatarSize,
    required this.maxHeight,
    this.alignLeft = false,
  });

  final ContactCard card;
  final double avatarSize;
  final double maxHeight;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    final nameSize = (maxHeight * 0.048).clamp(20.0, 30.0);
    final roleSize = (maxHeight * 0.030).clamp(13.0, 17.0);
    final companySize = (maxHeight * 0.028).clamp(12.0, 16.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: alignLeft
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        _Avatar(card: card, size: avatarSize),
        SizedBox(height: (maxHeight * 0.02).clamp(6.0, 14.0)),
        if (card.fullName.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.fullName,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontSize: nameSize,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ),
        if (card.jobTitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.jobTitle,
              maxLines: 1,
              style: TextStyle(
                color: _accent,
                fontSize: roleSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        if (card.company.isNotEmpty) ...[
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.company.toUpperCase(),
              maxLines: 1,
              style: TextStyle(
                color: Colors.white70,
                fontSize: companySize,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.card, required this.size});

  final ContactCard card;
  final double size;

  @override
  Widget build(BuildContext context) {
    final path = card.photoPath;
    final hasPhoto = path != null && File(path).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white10,
        border: Border.all(color: Colors.white24, width: 2),
        image: hasPhoto
            ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              card.initials,
              style: TextStyle(
                color: Colors.white70,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Eine Kontaktzeile (Icon + Text).
class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.detail, this.onTap, this.onLongPress});

  final _Detail detail;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final iconSize = (h / detail.lines * 0.46).clamp(15.0, 22.0);
        final fontSize = (h / detail.lines * 0.34).clamp(11.0, 15.0);

        return InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(detail.icon, size: iconSize, color: _accent),
                SizedBox(width: iconSize * 0.6),
                Expanded(
                  child: Text(
                    detail.text,
                    maxLines: detail.lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Detail {
  const _Detail({
    required this.icon,
    required this.label,
    required this.text,
    this.uri,
    this.lines = 1,
  });

  final IconData icon;
  final String label;
  final String text;
  final Uri? uri;
  final int lines;
}

/// Kleiner Hinweis, dass der QR-Code fuer das Scannen vergroessert werden kann.
class _ScanHint extends StatelessWidget {
  const _ScanHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_scanner, size: 13, color: Colors.white54),
        SizedBox(width: 5),
        Flexible(
          child: Text(
            'Antippen zum Vergroessern',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white54, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}
