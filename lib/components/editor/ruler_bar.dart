import 'package:flutter/material.dart';

/// Morisnote: a compact ruler control that keeps every stroke at a fixed
/// angle, so tables, underlines and parallel lines come out straight.
class RulerBar extends StatelessWidget {
  const new({
    super.key,
    required this.angleDegrees,
    required this.onChanged,
    required this.onClose,
  });

  final double angleDegrees;
  final ValueChanged<double> onChanged;
  final VoidCallback onClose;

  static const _presets = <double>[0, 45, 90, 135];

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final normalised = ((angleDegrees % 360) + 360) % 360;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.all(8),
      child: Center(
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(24),
          color: colorScheme.surfaceContainerHigh,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Putar -5°',
                  icon: const Icon(Icons.rotate_left),
                  onPressed: () => onChanged(normalised - 5),
                ),
                Text(
                  '${normalised.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                IconButton(
                  tooltip: 'Putar +5°',
                  icon: const Icon(Icons.rotate_right),
                  onPressed: () => onChanged(normalised + 5),
                ),
                for (final preset in _presets)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: ChoiceChip(
                      label: Text('${preset.toInt()}°'),
                      selected: (normalised - preset).abs() < 0.5,
                      onSelected: (_) => onChanged(preset),
                    ),
                  ),
                IconButton(
                  tooltip: 'Matikan penggaris',
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
