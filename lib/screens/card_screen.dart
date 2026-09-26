import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/card_profile.dart';
import '../models/card_style.dart';
import '../models/contact_card.dart';
import '../services/card_storage.dart';
import '../services/vcard.dart';
import '../widgets/qr_panel.dart';
import 'edit_screen.dart';
import 'profiles_screen.dart';
import 'qr_fullscreen.dart';

/// Die Visitenkarte - alles auf genau einer Seite, ohne Scrollen.
class CardScreen extends StatefulWidget {
  const CardScreen({
    required this.profiles,
    required this.storage,
    required this.onProfilesChanged,
    super.key,
  });

  final ProfileSet profiles;
  final CardStorage storage;
  final ValueChanged<ProfileSet> onProfilesChanged;

  @override
  State<CardScreen> createState() => _CardScreenState();
}

class _CardScreenState extends State<CardScreen> {
  CardProfile get _profile => widget.profiles.active;
  ContactCard get _card => _profile.card;
  CardStyle get _style => _profile.style;

  @override
  void initState() {
    super.initState();
    // Beim allerersten Start direkt die Eingabemaske oeffnen.
    if (_card.isEmpty && widget.profiles.profiles.length == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
    }
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<CardProfile>(
      MaterialPageRoute<CardProfile>(
        builder: (_) => EditScreen(profile: _profile, storage: widget.storage),
      ),
    );
    if (result != null) {
      widget.onProfilesChanged(widget.profiles.replace(result));
    }
  }

  Future<void> _openProfiles() async {
    final result = await Navigator.of(context).push<ProfileSet>(
      MaterialPageRoute<ProfileSet>(
        builder: (_) =>
            ProfilesScreen(profiles: widget.profiles, storage: widget.storage),
      ),
    );
    if (result != null) widget.onProfilesChanged(result);
  }

  void _openFullscreenQr() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => QrFullscreenScreen(card: _card),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _launch(Uri uri) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotOpen)));
    }
  }

  void _copy(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).copiedToClipboard(label)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Wischen wechselt zwischen den Profilen.
  void _onHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 200 || widget.profiles.profiles.length < 2) return;
    widget.onProfilesChanged(
      velocity < 0 ? widget.profiles.next() : widget.profiles.previous(),
    );
  }

  List<_Detail> _details(AppLocalizations l10n) {
    final card = _card;
    return <_Detail>[
      if (card.addressBlock.isNotEmpty)
        _Detail(
          icon: Icons.location_on_outlined,
          label: l10n.labelAddress,
          text: card.addressBlock,
          lines: 2,
        ),
      if (card.phone.isNotEmpty)
        _Detail(
          icon: Icons.phone_outlined,
          label: l10n.labelPhone,
          text: card.phone,
          uri: Uri(scheme: 'tel', path: card.phone.replaceAll(' ', '')),
        ),
      if (card.mobile.isNotEmpty)
        _Detail(
          icon: Icons.smartphone_outlined,
          label: l10n.labelMobile,
          text: card.mobile,
          uri: Uri(scheme: 'tel', path: card.mobile.replaceAll(' ', '')),
        ),
      if (card.email.isNotEmpty)
        _Detail(
          icon: Icons.mail_outline,
          label: l10n.labelEmail,
          text: card.email,
          uri: Uri(scheme: 'mailto', path: card.email),
        ),
      if (card.website.isNotEmpty)
        _Detail(
          icon: Icons.language,
          label: l10n.labelWeb,
          text: card.website,
          uri: Uri.tryParse(websiteUrl(card.website)),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final vCard = buildVCard(_card);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: style.isLight
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [style.backgroundTop, style.backgroundBottom],
            ),
          ),
          child: SafeArea(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: GestureDetector(
                onHorizontalDragEnd: _onHorizontalDrag,
                behavior: HitTestBehavior.opaque,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final landscape =
                        constraints.maxWidth > constraints.maxHeight;
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
                        _buildProfileDots(),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final l10n = AppLocalizations.of(context);
    final style = _style;
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: _openProfiles,
            icon: Icon(Icons.badge_outlined, color: style.text),
            tooltip: l10n.profiles,
          ),
          IconButton(
            onPressed: _openEditor,
            icon: Icon(Icons.edit_outlined, color: style.text),
            tooltip: l10n.editCard,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  /// Punkte unter der Karte zeigen, wie viele Profile es gibt.
  Widget _buildProfileDots() {
    final profiles = widget.profiles.profiles;
    if (profiles.length < 2) return const SizedBox(height: 4);

    final style = _style;
    final activeIndex = widget.profiles.activeIndex;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < profiles.length; i++)
            GestureDetector(
              onTap: () => widget.onProfilesChanged(
                widget.profiles.select(profiles[i].id),
              ),
              child: Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == activeIndex
                      ? style.accent
                      : style.text.withValues(alpha: 0.3),
                ),
              ),
            ),
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
            _Identity(
              card: _card,
              style: _style,
              avatarSize: avatarSize,
              maxHeight: h,
            ),
            SizedBox(height: gap),
            QrPanel(data: vCard, size: qrSize, onTap: _openFullscreenQr),
            const SizedBox(height: 8),
            _ScanHint(style: _style),
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
                    card: _card,
                    style: _style,
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
                _ScanHint(style: _style),
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
    final l10n = AppLocalizations.of(context);
    final style = _style;
    final details = _details(l10n);

    if (details.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: _openEditor,
          icon: Icon(Icons.add, color: style.accent),
          label: Text(
            l10n.addContactData,
            style: TextStyle(color: style.accent),
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
                  style: style,
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
    required this.style,
    required this.avatarSize,
    required this.maxHeight,
    this.alignLeft = false,
  });

  final ContactCard card;
  final CardStyle style;
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
        _Avatar(card: card, style: style, size: avatarSize),
        SizedBox(height: (maxHeight * 0.02).clamp(6.0, 14.0)),
        if (card.fullName.isNotEmpty)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              card.fullName,
              maxLines: 1,
              style: TextStyle(
                color: style.text,
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
                color: style.accent,
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
                color: style.mutedText,
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
  const _Avatar({required this.card, required this.style, required this.size});

  final ContactCard card;
  final CardStyle style;
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
        color: style.text.withValues(alpha: 0.08),
        border: Border.all(color: style.text.withValues(alpha: 0.22), width: 2),
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
                color: style.mutedText,
                fontSize: size * 0.36,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}

/// Eine Kontaktzeile (Icon + Text).
class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.detail,
    required this.style,
    this.onTap,
    this.onLongPress,
  });

  final _Detail detail;
  final CardStyle style;
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
                Icon(detail.icon, size: iconSize, color: style.accent),
                SizedBox(width: iconSize * 0.6),
                Expanded(
                  child: Text(
                    detail.text,
                    maxLines: detail.lines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.text,
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
  const _ScanHint({required this.style});

  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_scanner, size: 13, color: style.faintText),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            AppLocalizations.of(context).scanHint,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: style.faintText, fontSize: 11.5),
          ),
        ),
      ],
    );
  }
}
