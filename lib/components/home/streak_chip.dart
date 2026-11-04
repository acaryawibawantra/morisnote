import 'package:flutter/material.dart';
import 'package:saber/data/focus_timer.dart';
import 'package:saber/data/streak.dart';

/// Morisnote: the daily streak flame, shown in the home app bar.
///
/// Lit while the user writes every day; a missed day puts it out.
class StreakChip extends StatelessWidget {
  const new({super.key});

  static const _flameColor = Color(0xFFFF7043);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<StreakData>(
      valueListenable: StreakTracker.streak,
      builder: (context, data, _) {
        final now = DateTime.now();
        final alive = data.isAlive(now);
        final current = data.currentFor(now);
        final color = alive ? _flameColor : colorScheme.outline;

        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 4),
          child: Tooltip(
            message: alive
                ? 'Streak $current hari — tulis sesuatu hari ini untuk '
                      'menjaga api tetap hidup'
                : 'Api padam. Tulis & simpan catatan untuk menyalakannya lagi',
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showStreakDialog(context, data),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Icon(
                      alive
                          ? Icons.local_fire_department
                          : Icons.local_fire_department_outlined,
                      size: 20,
                      color: color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$current',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStreakDialog(BuildContext context, StreakData data) {
    final now = DateTime.now();
    final alive = data.isAlive(now);
    final recent = data.recentDays(now, count: 14);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.local_fire_department,
              color: alive ? _flameColor : Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(alive ? 'Streak ${data.currentFor(now)} hari' : 'Api padam'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alive
                  ? 'Kamu sudah menulis ${data.currentFor(now)} hari berturut-turut. '
                        'Simpan catatan hari ini supaya api tidak padam.'
                  : 'Tidak ada catatan tersimpan sehari penuh, jadi api padam. '
                        'Tulis dan simpan catatan hari ini untuk menyalakannya lagi.',
            ),
            const SizedBox(height: 16),
            Text(
              '14 hari terakhir',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final day in recent)
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: day
                          ? _flameColor
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rekor terpanjang: ${data.best} hari'),
            const Divider(height: 24),
            ValueListenableBuilder<Duration?>(
              valueListenable: FocusTimer.remaining,
              builder: (context, remaining, _) {
                if (remaining != null) {
                  return Text(
                    'Sesi fokus berjalan: ${FocusTimer.format(remaining)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  );
                }
                return Row(
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () {
                        FocusTimer.start(minutes: 25);
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.timer_outlined, size: 18),
                      label: const Text('Fokus 25 mnt'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: () {
                        FocusTimer.start(minutes: 50);
                        Navigator.of(context).pop();
                      },
                      child: const Text('50 mnt'),
                    ),
                  ],
                );
              },
            ),
            ValueListenableBuilder<int>(
              valueListenable: FocusTimer.sessionsToday,
              builder: (context, count, _) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('Sesi fokus selesai hari ini: $count'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
