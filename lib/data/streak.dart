import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:saber/data/prefs.dart';

/// A day of study, stored as `yyyy-MM-dd` in the device's local timezone.
String streakDayKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

/// Morisnote: the "streak api" — one flame per day the user writes something.
///
/// A day counts when the user saves a note. Missing a whole day puts the fire
/// out: [current] drops back to zero the next time the app looks at the date.
@immutable
class StreakData {
  const StreakData({
    this.current = 0,
    this.best = 0,
    this.lastDay,
    this.days = const <String>[],
  });

  /// Consecutive days including today (or yesterday, before today's session).
  final int current;

  /// Longest streak ever reached.
  final int best;

  /// Last day the user wrote something, or null if they never have.
  final String? lastDay;

  /// Most recent study days, newest last. Capped to keep the pref small.
  final List<String> days;

  static const _maxDays = 60;

  /// True when the fire is still burning: the last writing day is today or
  /// yesterday. If it is older, the streak is dead and shows as zero.
  bool isAlive(DateTime now) {
    final last = lastDay;
    if (last == null) return false;
    final today = streakDayKey(now);
    final yesterday = streakDayKey(now.subtract(const Duration(days: 1)));
    return last == today || last == yesterday;
  }

  /// The streak to display: zero once a full day has been missed.
  int currentFor(DateTime now) => isAlive(now) ? current : 0;

  /// Whether today already counts (so the flame cannot be farmed).
  bool includesToday(DateTime now) => lastDay == streakDayKey(now);

  /// Days in the last [count] days, oldest first, for the little heat strip.
  List<bool> recentDays(DateTime now, {int count = 7}) {
    final set = days.toSet();
    return [
      for (int i = count - 1; i >= 0; i--)
        set.contains(streakDayKey(now.subtract(Duration(days: i)))),
    ];
  }

  StreakData recordToday(DateTime now) {
    final today = streakDayKey(now);
    if (lastDay == today) return this;

    final yesterday = streakDayKey(now.subtract(const Duration(days: 1)));
    final newCurrent = lastDay == yesterday ? current + 1 : 1;

    final updatedDays = [...days, today];
    final trimmed = updatedDays.length > _maxDays
        ? updatedDays.sublist(updatedDays.length - _maxDays)
        : updatedDays;

    return StreakData(
      current: newCurrent,
      best: newCurrent > best ? newCurrent : best,
      lastDay: today,
      days: trimmed,
    );
  }

  Map<String, dynamic> toJson() => {
    'c': current,
    'b': best,
    'l': lastDay,
    'd': days,
  };

  static StreakData fromJson(Map<String, dynamic> json) => StreakData(
    current: (json['c'] as num?)?.toInt() ?? 0,
    best: (json['b'] as num?)?.toInt() ?? 0,
    lastDay: json['l'] as String?,
    days: [
      for (final day in (json['d'] as List?) ?? const [])
        if (day is String) day,
    ],
  );

  String encode() => jsonEncode(toJson());

  static StreakData decode(String raw) {
    if (raw.isEmpty) return const StreakData();
    try {
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) return fromJson(json);
    } catch (_) {
      // A corrupt streak should never block the editor: start fresh.
    }
    return const StreakData();
  }

  @override
  bool operator ==(Object other) =>
      other is StreakData &&
      other.current == current &&
      other.best == best &&
      other.lastDay == lastDay &&
      listEquals(other.days, days);

  @override
  int get hashCode => Object.hash(current, best, lastDay, Object.hashAll(days));
}

/// Morisnote: reads and writes the streak, and notifies the home screen.
class StreakTracker {
  StreakTracker._();

  static final ValueNotifier<StreakData> streak = ValueNotifier(
    _load(),
  );

  static StreakData _load() => StreakData.decode(stows.streakJson.value);

  static void reload() {
    streak.value = _load();
  }

  /// Called whenever a note is saved, so any real writing keeps the fire lit.
  static void recordActivity() {
    final now = DateTime.now();
    final updated = streak.value.recordToday(now);
    if (updated == streak.value) return;

    streak.value = updated;
    stows.streakJson.value = updated.encode();
  }
}
