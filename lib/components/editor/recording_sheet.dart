import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logging/logging.dart';
import 'package:record/record.dart';
import 'package:saber/data/editor/note_recording.dart';
import 'package:saber/data/file_manager/file_manager.dart';

/// Morisnote: record a voice note for the current page and play recordings back.
///
/// Recorded audio is stored as a sidecar file next to the note
/// (`<note>.a0`, `<note>.a1`, ...) so it travels with the note when it is
/// renamed, moved or deleted.
class RecordingSheet extends StatefulWidget {
  const RecordingSheet({
    super.key,
    required this.notePath,
    required this.recordings,
    required this.onChanged,
    required this.onRecordingStarted,
  });

  final String notePath;

  /// The recordings of the current page. Modified in place.
  final List<NoteRecording> recordings;

  /// Called after a recording was added or deleted, so the note can be saved.
  final VoidCallback onChanged;

  /// Called with the recording start time in ms since epoch while recording,
  /// and with null when recording stops. Used to time-stamp new strokes.
  final void Function(int? startEpochMs) onRecordingStarted;

  @override
  State<RecordingSheet> createState() => _RecordingSheetState();
}

class _RecordingSheetState extends State<RecordingSheet> {
  static final _log = Logger('RecordingSheet');

  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  bool _isRecording = false;
  DateTime? _startedAt;
  String? _recordingFile;
  Duration _elapsed = Duration.zero;
  Timer? _elapsedTimer;

  String? _playingFile;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (!state.playing && state.processingState == ProcessingState.completed) {
        setState(() => _playingFile = null);
      }
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  String _pathForFile(String file) =>
      FileManager.getFile('${widget.notePath}.$file').path;

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        _showMessage('Izin mikrofon ditolak. Aktifkan di pengaturan Android.');
        return;
      }

      await _player.stop();
      final file = NoteRecording.nextFileSuffix(
        widget.notePath,
        widget.recordings,
      );
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _pathForFile(file),
      );

      final startedAt = DateTime.now();
      setState(() {
        _isRecording = true;
        _startedAt = startedAt;
        _recordingFile = file;
        _elapsed = Duration.zero;
        _playingFile = null;
      });
      widget.onRecordingStarted(startedAt.millisecondsSinceEpoch);

      _elapsedTimer?.cancel();
      _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _startedAt == null) return;
        setState(() => _elapsed = DateTime.now().difference(_startedAt!));
      });
    } catch (e, s) {
      _log.severe('Failed to start recording', e, s);
      _showMessage('Gagal mulai merekam: $e');
    }
  }

  Future<void> _stopRecording() async {
    final startedAt = _startedAt;
    final file = _recordingFile;
    _elapsedTimer?.cancel();

    try {
      final path = await _recorder.stop();
      final durationMs = startedAt == null
          ? 0
          : DateTime.now().difference(startedAt).inMilliseconds;

      if (file != null && startedAt != null && durationMs > 500) {
        widget.recordings.add(
          NoteRecording(
            file: file,
            startEpochMs: startedAt.millisecondsSinceEpoch,
            durationMs: durationMs,
          ),
        );
        widget.recordings.sort((a, b) => a.startEpochMs.compareTo(b.startEpochMs));
        widget.onChanged();
      } else {
        _log.info('Discarded too-short recording at $path');
      }
    } catch (e, s) {
      _log.severe('Failed to stop recording', e, s);
      _showMessage('Gagal menyimpan rekaman: $e');
    } finally {
      widget.onRecordingStarted(null);
      if (mounted) {
        setState(() {
          _isRecording = false;
          _startedAt = null;
          _recordingFile = null;
          _elapsed = Duration.zero;
        });
      }
    }
  }

  Future<void> _togglePlay(NoteRecording recording) async {
    try {
      if (_playingFile == recording.file) {
        await _player.stop();
        setState(() => _playingFile = null);
        return;
      }

      await _player.stop();
      await _player.setFilePath(_pathForFile(recording.file));
      setState(() => _playingFile = recording.file);
      unawaited(_player.play());
    } catch (e, s) {
      _log.severe('Failed to play recording', e, s);
      _showMessage('Gagal memutar rekaman: $e');
    }
  }

  Future<void> _delete(NoteRecording recording) async {
    if (_playingFile == recording.file) {
      await _player.stop();
      setState(() => _playingFile = null);
    }
    widget.recordings.remove(recording);
    final file = FileManager.getFile('${widget.notePath}.${recording.file}');
    try {
      if (file.existsSync()) await file.delete();
    } catch (e, s) {
      _log.warning('Failed to delete recording file', e, s);
    }
    widget.onChanged();
    if (mounted) setState(() {});
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 380,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isRecording)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.fiber_manual_record, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Merekam ${_formatDuration(_elapsed)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          FilledButton.icon(
            onPressed: _isRecording ? _stopRecording : _startRecording,
            icon: Icon(_isRecording ? Icons.stop : Icons.mic),
            label: Text(_isRecording ? 'Stop' : 'Rekam halaman ini'),
          ),
          if (widget.recordings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Belum ada rekaman di halaman ini.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.recordings.length,
                itemBuilder: (context, index) {
                  final recording = widget.recordings[index];
                  final isPlaying = _playingFile == recording.file;
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: IconButton(
                      icon: Icon(isPlaying ? Icons.stop_circle : Icons.play_circle),
                      tooltip: isPlaying ? 'Stop' : 'Putar',
                      onPressed: () => _togglePlay(recording),
                    ),
                    title: Text(_formatDuration(recording.duration)),
                    subtitle: Text('Rekaman ${index + 1}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Hapus',
                      onPressed: () => _delete(recording),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
