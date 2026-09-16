import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/contact_card.dart';
import '../services/card_storage.dart';

/// Eingabemaske fuer die Visitenkarte.
///
/// Gibt die geaenderte Karte beim Speichern via [Navigator.pop] zurueck.
class EditScreen extends StatefulWidget {
  const EditScreen({required this.card, required this.storage, super.key});

  final ContactCard card;
  final CardStorage storage;

  @override
  State<EditScreen> createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  late final Map<String, TextEditingController> _controllers;
  String? _photoPath;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final card = widget.card;
    _controllers = {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto konnte nicht geladen werden: $error')),
      );
    }
  }

  Future<void> _removePhoto() async {
    await widget.storage.deletePhoto(_photoPath);
    if (!mounted) return;
    setState(() => _photoPath = null);
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Aus der Galerie waehlen'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Foto aufnehmen'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Foto entfernen'),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final card = ContactCard(
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
    );
    await widget.storage.save(card);

    if (!mounted) return;
    Navigator.of(context).pop(card);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visitenkarte bearbeiten'),
        actions: [
          TextButton(
            onPressed: _busy ? null : _save,
            child: const Text('Speichern'),
          ),
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
            const _SectionTitle('Person'),
            _field(
              'firstName',
              'Vorname',
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'lastName',
              'Nachname',
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'jobTitle',
              'Position / Titel',
              hint: 'z. B. Geschaeftsfuehrer',
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Firma'),
            _field(
              'company',
              'Firmenname',
              textCapitalization: TextCapitalization.words,
            ),
            _field(
              'street',
              'Strasse und Hausnummer',
              textCapitalization: TextCapitalization.words,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: _field(
                    'postalCode',
                    'PLZ',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(
                    'city',
                    'Ort',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            _field(
              'country',
              'Land',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Kontakt'),
            _field(
              'phone',
              'Telefon (Firma)',
              keyboardType: TextInputType.phone,
            ),
            _field('mobile', 'Mobil', keyboardType: TextInputType.phone),
            _field(
              'email',
              'E-Mail',
              keyboardType: TextInputType.emailAddress,
              validator: _validateEmail,
            ),
            _field(
              'website',
              'Website',
              hint: 'z. B. firma.de',
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy ? null : _save,
              icon: const Icon(Icons.check),
              label: const Text('Speichern'),
            ),
            const SizedBox(height: 16),
            Text(
              'Alle Angaben bleiben auf diesem Geraet. Die App sendet nichts '
              'an einen Server.',
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

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text);
    return valid ? null : 'Bitte eine gueltige E-Mail-Adresse eingeben';
  }
}

class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({required this.path, required this.onTap});

  final String? path;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
          child: Text(hasPhoto ? 'Foto aendern' : 'Foto hinzufuegen'),
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
