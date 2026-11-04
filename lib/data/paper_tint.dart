import 'package:flutter/material.dart';

/// Morisnote: paper tint for the page background.
///
/// A tint overrides the theme-derived background so the page can look like
/// real paper (cream/sepia) or a dark board, and it decides whether the ruling
/// is drawn inverted to stay readable.
enum PaperTint {
  automatic('Otomatis (tema)', null, false),
  cream('Krem', Color(0xFFFBF3E0), false),
  sepia('Sepia', Color(0xFFF0E4CC), false),
  mint('Hijau muda', Color(0xFFE7F3EA), false),
  dark('Gelap', Color(0xFF1B1B1F), true);

  const PaperTint(this.label, this.color, this.forcesInvert);

  final String label;

  /// The page colour, or null to follow the app theme.
  final Color? color;

  /// Whether the ruling must be drawn inverted to stay visible.
  final bool forcesInvert;

  static PaperTint fromIndex(int index) {
    if (index < 0 || index >= values.length) return PaperTint.automatic;
    return values[index];
  }

}
