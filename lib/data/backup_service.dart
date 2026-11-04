import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:saber/data/file_manager/file_manager.dart';
import 'package:saber/data/prefs.dart';
import 'package:saber/data/streak.dart';

/// Morisnote: keeps a rolling copy of every note so a bad edit (or a lost
/// tablet) never takes a day of study with it.
///
/// Notes are copied once per day per note into
/// `Documents/MorisnoteBackup/<yyyy-MM-dd>/`, and folders older than
/// [keepDays] are pruned.
class BackupService {
  BackupService._();

  static final _log = Logger('BackupService');

  static const keepDays = 7;
  static const _folderName = 'MorisnoteBackup';

  static Directory get _root =>
      Directory('${FileManager.documentsDirectory}/$_folderName');

  /// Copies [sourceFilePath] (the freshly written `.sbn2`) into today's backup
  /// folder. Cheap for repeat saves: the file is only copied once per day.
  static Future<void> backupNote({
    required String notePath,
    required String sourceFilePath,
  }) async {
    if (!stows.autoBackup.value) return;

    try {
      final day = Directory('${_root.path}/${streakDayKey(DateTime.now())}');
      await day.create(recursive: true);

      final fileName = notePath.split('/').last;
      final destination = File('${day.path}/$fileName.sbn2');
      if (await destination.exists()) return;

      final source = File(sourceFilePath);
      if (!await source.exists()) return;
      await source.copy(destination.path);

      await _pruneBackups();
    } catch (e, s) {
      // A failed backup must never break saving the note itself.
      _log.warning('Failed to back up $notePath', e, s);
    }
  }

  static Future<void> _pruneBackups() async {
    if (!await _root.exists()) return;

    final folders = <Directory>[];
    await for (final entity in _root.list()) {
      if (entity is Directory) folders.add(entity);
    }
    if (folders.length <= keepDays) return;

    folders.sort((a, b) => a.path.compareTo(b.path));
    for (final folder in folders.take(folders.length - keepDays)) {
      try {
        await folder.delete(recursive: true);
      } catch (e, s) {
        _log.warning('Failed to prune ${folder.path}', e, s);
      }
    }
  }

  /// Number of notes available in the newest backup folder.
  static Future<int> newestBackupCount() async {
    try {
      if (!await _root.exists()) return 0;
      final folders = <Directory>[];
      await for (final entity in _root.list()) {
        if (entity is Directory) folders.add(entity);
      }
      if (folders.isEmpty) return 0;
      folders.sort((a, b) => a.path.compareTo(b.path));
      return folders.last.listSync().whereType<File>().length;
    } catch (e) {
      if (kDebugMode) _log.fine('Could not count backups: $e');
      return 0;
    }
  }
}
