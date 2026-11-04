import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/streak.dart';

/// Morisnote: a small Pomodoro-style focus timer for study sessions.
///
/// It lives outside the widget tree so a session keeps running while the user
/// writes, switches notes or leaves the home screen.
class FocusTimer {
  FocusTimer._();

  static const defaultMinutes = 25;

  /// Time left, or null when no session is running.
  static final ValueNotifier<Duration?> remaining = ValueNotifier(null);

  /// Completed sessions today.
  static final ValueNotifier<int> sessionsToday = ValueNotifier(
    _loadSessionsToday(),
  );

  static Timer? _ticker;
  static DateTime? _endsAt;
  static int _minutes = defaultMinutes;

  static bool get isRunning => remaining.value != null;

  static void start({int minutes = defaultMinutes}) {
    stop(notify: false);
    _minutes = minutes;
    _endsAt = DateTime.now().add(Duration(minutes: minutes));
    remaining.value = Duration(minutes: minutes);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  static void stop({bool notify = true}) {
    _ticker?.cancel();
    _ticker = null;
    _endsAt = null;
    if (notify || remaining.value != null) remaining.value = null;
  }

  static Duration get sessionLength => Duration(minutes: _minutes);

  static void _tick() {
    final endsAt = _endsAt;
    if (endsAt == null) return;

    final left = endsAt.difference(DateTime.now());
    if (left.isNegative || left == Duration.zero) {
      remaining.value = null;
      _ticker?.cancel();
      _ticker = null;
      _endsAt = null;
      _recordSession();
      return;
    }
    remaining.value = left;
  }

  static String _today() => streakDayKey(DateTime.now());

  static int _loadSessionsToday() {
    final raw = stows.focusSessions.value;
    final parts = raw.split('|');
    if (parts.length != 2 || parts[0] != _today()) return 0;
    return int.tryParse(parts[1]) ?? 0;
  }

  static void _recordSession() {
    final count = sessionsToday.value + 1;
    sessionsToday.value = count;
    stows.focusSessions.value = '${_today()}|$count';
  }

  /// Formats a duration as `mm:ss` for the timer chips.
  static String format(Duration? duration) {
    if (duration == null) return '';
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
