import 'dart:io';

/// A voice recording attached to one page of a note.
///
/// The audio itself lives in a sidecar file next to the note:
/// `<note path>.a<index>` (for example `My note.sbn.a0`).
/// Only the metadata is stored inside the note file, under the page key `a`,
/// so notes that contain recordings still open in upstream Saber (it ignores
/// the unknown key).
class NoteRecording {
  /// The sidecar suffix, e.g. `a0` for `<note>.a0`.
  final String file;

  /// Wall clock time (ms since epoch) when the recording started.
  final int startEpochMs;

  /// Length of the recording in milliseconds.
  final int durationMs;

  const NoteRecording({
    required this.file,
    required this.startEpochMs,
    required this.durationMs,
  });

  String pathFor(String notePath) => '$notePath.$file';

  Duration get duration => Duration(milliseconds: durationMs);

  Map<String, dynamic> toJson() => {
    'f': file,
    'st': startEpochMs,
    'd': durationMs,
  };

  static NoteRecording? fromJson(Map<String, dynamic> json) {
    final file = json['f'];
    if (file is! String || file.isEmpty) return null;
    return NoteRecording(
      file: file,
      startEpochMs: switch (json['st']) {
        final int value => value,
        _ => 0,
      },
      durationMs: switch (json['d']) {
        final int value => value,
        _ => 0,
      },
    );
  }

  static List<NoteRecording> listFromJson(List<dynamic>? json) => (json ?? [])
      .whereType<Map>()
      .map((map) => NoteRecording.fromJson(map.cast<String, dynamic>()))
      .whereType<NoteRecording>()
      .toList();

  /// Finds the next free `a<index>` suffix for a note.
  ///
  /// Morisnote: keeps sidecar names stable even after a recording is deleted.
  static String nextFileSuffix(String notePath, List<NoteRecording> existing) {
    final used = existing.map((r) => r.file).toSet();
    for (int index = 0; ; index++) {
      final candidate = 'a$index';
      if (!used.contains(candidate) &&
          !File('$notePath.$candidate').existsSync()) {
        return candidate;
      }
    }
  }
}
