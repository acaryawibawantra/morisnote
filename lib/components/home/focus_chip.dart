import 'package:flutter/material.dart';
import 'package:saber/data/focus_timer.dart';

/// Morisnote: shows the focus timer while a study session is running.
class FocusChip extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<Duration?>(
      valueListenable: FocusTimer.remaining,
      builder: (context, remaining, _) {
        if (remaining == null) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sesi fokus'),
                content: Text(
                  'Sisa ${FocusTimer.format(remaining)}. '
                  'Selesaikan sesi atau hentikan sekarang.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Lanjut belajar'),
                  ),
                  FilledButton(
                    onPressed: () {
                      FocusTimer.stop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Hentikan'),
                  ),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  Icon(Icons.timer_outlined, size: 20, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    FocusTimer.format(remaining),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
