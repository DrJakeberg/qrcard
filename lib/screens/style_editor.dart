import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/card_style.dart';

/// Farbauswahl fuer Hintergrund, Schrift und Akzent - mit Live-Vorschau.
class StyleEditorScreen extends StatefulWidget {
  const StyleEditorScreen({required this.style, super.key});

  final CardStyle style;

  @override
  State<StyleEditorScreen> createState() => _StyleEditorScreenState();
}

class _StyleEditorScreenState extends State<StyleEditorScreen> {
  late CardStyle _style = widget.style;

  List<(String, CardStyle)> _presets(AppLocalizations l10n) => [
    (l10n.presetMarine, CardStyle.marine),
    (l10n.presetGraphite, CardStyle.graphite),
    (l10n.presetBordeaux, CardStyle.bordeaux),
    (l10n.presetForest, CardStyle.forest),
    (l10n.presetSand, CardStyle.sand),
    (l10n.presetPaper, CardStyle.paper),
  ];

  Future<void> _pickColor({
    required String title,
    required Color current,
    required ValueChanged<Color> onPicked,
  }) async {
    final picked = await showModalBottomSheet<Color>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ColorSheet(title: title, initial: current),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appearance),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_style),
            child: Text(l10n.done),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          _StylePreview(style: _style),
          if (_style.hasPoorContrast) ...[
            const SizedBox(height: 12),
            _WarningBanner(text: l10n.contrastWarning),
          ],
          const SizedBox(height: 24),
          _SectionTitle(l10n.colorPresets),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final (name, preset) in _presets(l10n))
                _PresetChip(
                  name: name,
                  style: preset,
                  selected: preset == _style,
                  onTap: () => setState(() => _style = preset),
                ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(l10n.colorCustom),
          _ColorRow(
            label: l10n.colorBackgroundTop,
            color: _style.backgroundTop,
            onTap: () => _pickColor(
              title: l10n.colorBackgroundTop,
              current: _style.backgroundTop,
              onPicked: (c) =>
                  setState(() => _style = _style.copyWith(backgroundTop: c)),
            ),
          ),
          _ColorRow(
            label: l10n.colorBackgroundBottom,
            color: _style.backgroundBottom,
            onTap: () => _pickColor(
              title: l10n.colorBackgroundBottom,
              current: _style.backgroundBottom,
              onPicked: (c) =>
                  setState(() => _style = _style.copyWith(backgroundBottom: c)),
            ),
          ),
          _ColorRow(
            label: l10n.colorText,
            color: _style.text,
            onTap: () => _pickColor(
              title: l10n.colorText,
              current: _style.text,
              onPicked: (c) =>
                  setState(() => _style = _style.copyWith(text: c)),
            ),
          ),
          _ColorRow(
            label: l10n.colorAccent,
            color: _style.accent,
            onTap: () => _pickColor(
              title: l10n.colorAccent,
              current: _style.accent,
              onPicked: (c) =>
                  setState(() => _style = _style.copyWith(accent: c)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(
                Icons.qr_code_2,
                size: 18,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.qrStaysWhite,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => setState(() => _style = CardStyle.marine),
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.reset),
          ),
        ],
      ),
    );
  }
}

/// Zeigt die gewaehlten Farben so, wie sie auf der Karte wirken.
class _StylePreview extends StatelessWidget {
  const _StylePreview({required this.style});

  final CardStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [style.backgroundTop, style.backgroundBottom],
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.text.withValues(alpha: 0.08),
              border: Border.all(
                color: style.text.withValues(alpha: 0.22),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'AB',
              style: TextStyle(
                color: style.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Anna Beispiel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: style.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Geschäftsführerin',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: style.accent, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.mail_outline, size: 15, color: style.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'anna@beispiel.de',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: style.text, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onErrorContainer, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.name,
    required this.style,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final CardStyle style;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 96,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [style.backgroundTop, style.backgroundBottom],
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                'Aa',
                style: TextStyle(
                  color: style.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  const _ColorRow({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Container(
        width: 44,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}

/// Farbwahl ueber drei Schieberegler - kommt ohne Zusatzpaket aus.
class _ColorSheet extends StatefulWidget {
  const _ColorSheet({required this.title, required this.initial});

  final String title;
  final Color initial;

  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late double _r = (widget.initial.r * 255).roundToDouble();
  late double _g = (widget.initial.g * 255).roundToDouble();
  late double _b = (widget.initial.b * 255).roundToDouble();

  Color get _color => Color.fromARGB(255, _r.round(), _g.round(), _b.round());

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '#${_color.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                style: TextStyle(
                  color: _color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _Slider(
              label: 'R',
              value: _r,
              color: Colors.red,
              onChanged: (v) => setState(() => _r = v),
            ),
            _Slider(
              label: 'G',
              value: _g,
              color: Colors.green,
              onChanged: (v) => setState(() => _g = v),
            ),
            _Slider(
              label: 'B',
              value: _b,
              color: Colors.blue,
              onChanged: (v) => setState(() => _b = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_color),
                    child: Text(l10n.done),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Slider extends StatelessWidget {
  const _Slider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 18, child: Text(label)),
        Expanded(
          child: Slider(
            value: value,
            max: 255,
            divisions: 255,
            activeColor: color,
            label: value.round().toString(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
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
