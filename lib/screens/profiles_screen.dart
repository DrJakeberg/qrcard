import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_profile.dart';
import '../models/card_style.dart';
import '../models/contact_card.dart';
import '../services/card_storage.dart';
import 'edit_screen.dart';

/// Liste aller Visitenkarten mit Wechsel, Anlegen, Duplizieren und Loeschen.
class ProfilesScreen extends StatefulWidget {
  const ProfilesScreen({
    required this.profiles,
    required this.storage,
    super.key,
  });

  final ProfileSet profiles;
  final CardStorage storage;

  @override
  State<ProfilesScreen> createState() => _ProfilesScreenState();
}

class _ProfilesScreenState extends State<ProfilesScreen> {
  late ProfileSet _profiles = widget.profiles;

  void _select(String id) {
    setState(() => _profiles = _profiles.select(id));
  }

  Future<void> _edit(CardProfile profile) async {
    final result = await Navigator.of(context).push<CardProfile>(
      MaterialPageRoute<CardProfile>(
        builder: (_) => EditScreen(profile: profile, storage: widget.storage),
      ),
    );
    if (result == null) return;
    setState(() => _profiles = _profiles.replace(result));
  }

  Future<void> _addNew() async {
    final created = CardProfile(
      id: CardProfile.newId(),
      name: '',
      card: const ContactCard(),
      style: CardStyle.marine,
    );
    final result = await Navigator.of(context).push<CardProfile>(
      MaterialPageRoute<CardProfile>(
        builder: (_) => EditScreen(profile: created, storage: widget.storage),
      ),
    );
    if (result == null) return;
    setState(() => _profiles = _profiles.add(result));
  }

  void _duplicate(CardProfile profile) {
    final l10n = AppLocalizations.of(context);
    final copy = CardProfile(
      id: CardProfile.newId(),
      name: '${profile.displayName(fallback: l10n.untitledProfile)} (2)',
      card: profile.card,
      style: profile.style,
    );
    setState(() => _profiles = _profiles.add(copy));
  }

  Future<void> _delete(CardProfile profile) async {
    final l10n = AppLocalizations.of(context);
    if (!_profiles.canDelete) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.lastProfileHint)));
      return;
    }

    final name = profile.displayName(fallback: l10n.untitledProfile);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteProfile),
        content: Text(l10n.deleteProfileQuestion(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _profiles = _profiles.remove(profile.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_profiles);
      },
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.profiles)),
        body: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _profiles.profiles.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final profile = _profiles.profiles[index];
            final isActive = profile.id == _profiles.activeId;
            return ListTile(
              leading: _ProfileAvatar(profile: profile),
              title: Text(
                profile.displayName(fallback: l10n.untitledProfile),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
              subtitle: Text(
                [
                  profile.card.jobTitle,
                  profile.card.company,
                ].where((p) => p.isNotEmpty).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _edit(profile);
                        case 'duplicate':
                          _duplicate(profile);
                        case 'delete':
                          _delete(profile);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(l10n.editCard)),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Text(l10n.duplicateProfile),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(l10n.deleteProfile),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => _select(profile.id),
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _addNew,
          icon: const Icon(Icons.add),
          label: Text(l10n.newProfile),
        ),
      ),
    );
  }
}

/// Kleine Vorschau der Karte: Foto bzw. Initialen in den Profilfarben.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile});

  final CardProfile profile;

  @override
  Widget build(BuildContext context) {
    final path = profile.card.photoPath;
    final hasPhoto = path != null && File(path).existsSync();
    final style = profile.style;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.backgroundTop, style.backgroundBottom],
        ),
        image: hasPhoto
            ? DecorationImage(image: FileImage(File(path)), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(
              profile.card.initials,
              style: TextStyle(color: style.text, fontWeight: FontWeight.w600),
            ),
    );
  }
}
