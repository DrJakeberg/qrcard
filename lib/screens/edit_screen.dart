import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/card_profile.dart';
import '../models/card_style.dart';
import '../models/contact_card.dart';
import '../services/card_storage.dart';
import 'style_editor.dart';

/// Eingabemaske fuer eine Visitenkarte.
///
/// Gibt das geaenderte Profil beim Speichern via [Navigator.pop] zurueck.
class EditScreen extends StatefulWidget {
  const EditScreen({required this.profile, required this.storage, super.key});

  final CardProfile profile;
  final CardStorage storage;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final Map<String, TextEditingController> _controllers;
  late CardStyle _style = widget.profile.style;
  String? _photoPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final card = widget.profile.card;
    _controllers = {
      'profileName': TextEditingController(text: widget.profile.name),
      'firstName': TextEditingController(text: card.firstName),
      'lastName': TextEditingController(text: card.lastName),
      'jobTitle': TextEditingController(text: card.jobTitle),
      'company': TextEditingController(text: card.company),
      'street': TextEditingController(text: card.street),
      'postalCode': TextEditingController(text: card.postalCode),
      'city': TextEditingController(text: card.city),
      'country': TextEditingController(text: card.country),
      'phone': TextEditingController(text: card.phone),
      'mobile': TextEditingController(text: card.mobile),
      'email': TextEditingController(text: card.email),
      'website': TextEditingController(text: card.website),
    };
    _photoPath = card.photoPath;
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _value(String key) => _controllers[key]!.text.trim();

  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picked = await _picker.pickImage(
        source: source,
        // Begrenzung spart Speicher - fuer ein rundes Profilbild reicht das.
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      if (picked == null) return;

      final stored = await widget.storage.importPhoto(File(picked.path));
      if (!mounted) return;
      setState(() => _photoPath = stored);
    } on Exception catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.photoError(error.toString()))),
      );
    }
  }

  void _removePhoto() {
    // Die Datei selbst wird erst beim Speichern aufgeraeumt - so bleibt ein
    // Abbrechen folgenlos, und andere Profile behalten ihr Bild.
    setState(() => _photoPath = null);
  }

  void _showPhotoOptions() {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.photoFromGallery),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.photoFromCamera),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.photoRemove),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openStyleEditor() async {
    final result = await Navigator.of(context).push<CardStyle>(
      MaterialPageRoute<CardStyle>(
        builder: (_) => StyleEditorScreen(style: _style),
      ),
    );
    if (result != null) setState(() => _style = result);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final profile = widget.profile.copyWith(
      name: _value('profileName'),
      style: _style,
      card: ContactCard(
        firstName: _value('firstName'),
        lastName: _value('lastName'),
        jobTitle: _value('jobTitle'),
        company: _value('company'),
        street: _value('street'),
        postalCode: _value('postalCode'),
        city: _value('city'),
        country: _value('country'),
        phone: _value('phone'),
        mobile: _value('mobile'),
        email: _value('email'),
        website: _value('website'),
        photoPath: _photoPath,
      ),
    );
    Navigator.of(context).pop(profile);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editCard),
        actions: [
          TextButton(onPressed: _busy ? null : _save, child: Text(l10n.save)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: _PhotoPicker(path: _photoPath, onTap: _showPhotoOptions),
            ),
            const SizedBox(height: 24),
            _field('profileName', l10n.profileName, hint: l10n.hintProfileName),
            _StyleTile(
              style: _style,
              label: l10n.appearance,
              onTap: _openStyleEditor,
            ),
            const SizedBox(height: 20),
            _SectionTitle(l10n.sectionPerson),
            _field(
              'firstName',
              l10n.fieldFirstName,
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'lastName',
              l10n.fieldLastName,
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'jobTitle',
              l10n.fieldJobTitle,
              hint: l10n.hintJobTitle,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.sectionCompany),
            _field(
              'company',
              l10n.fieldCompany,
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'street',
              l10n.fieldStreet,
              textCapitalization: TextCapitalization.words,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: _field(
                    'postalCode',
                    l10n.fieldPostalCode,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'city',
                    l10n.fieldCity,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            _field(
              'country',
              l10n.fieldCountry,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            _SectionTitle(l10n.sectionContact),
            _field(
              'phone',
              l10n.fieldPhoneWork,
              keyboardType: TextInputType.phone,
            ),
            _field(
              'mobile',
              l10n.fieldMobile,
              keyboardType: TextInputType.phone,
            ),
            _field(
              'email',
              l10n.fieldEmail,
              keyboardType: TextInputType.emailAddress,
              validator: (value) => _validateEmail(value, l10n),
            ),
            _field(
              'website',
              l10n.fieldWebsite,
              hint: l10n.hintWebsite,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: Text(l10n.save),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.privacyNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String key,
    String label, {
    String? hint,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : l10n.invalidEmail;
  }
}

/// Zeile, die die aktuellen Kartenfarben zeigt und den Farbeditor oeffnet.
class _StyleTile extends StatelessWidget {
  const _StyleTile({
    required this.style,
    required this.label,
    required this.onTap,
  });

  final CardStyle style;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [style.backgroundTop, style.backgroundBottom],
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'Aa',
          style: TextStyle(color: style.text, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final hasPhoto = path != null && File(path!).existsSync();

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 116,
            height: 116,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.surfaceContainerHighest,
              border: Border.all(color: scheme.outlineVariant, width: 2),
              image: hasPhoto
                  ? DecorationImage(
                      image: FileImage(File(path!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            alignment: Alignment.center,
            child: hasPhoto
                ? null
                : Icon(
                    Icons.add_a_photo_outlined,
                    size: 32,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onTap,
          child: Text(hasPhoto ? l10n.photoChange : l10n.photoAdd),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
