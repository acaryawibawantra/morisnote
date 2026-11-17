import 'dart:convert';

import 'package:digital_ink_recognition_mlkit/digital_ink_recognition_mlkit.dart'
    as mlkit;
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:saber/components/canvas/_stroke.dart';
import 'package:saber/data/file_manager/file_manager.dart';

/// Morisnote: turns handwritten strokes into searchable text with Google's
/// on-device Digital Ink Recognition (ML Kit).
///
/// The recognized text is stored in a `.ocr` sidecar next to the note, so the
/// home search can find a note by what is written in it, not just its name.
class HandwritingOcr {
  HandwritingOcr._();

  static final _log = Logger('HandwritingOcr');

  /// BCP-47 language codes offered in the UI.
  static const languages = <String, String>{
    'en': 'Inggris',
    'id': 'Indonesia',
  };

  /// Runs recognition on [strokes] (page coordinates) and returns the text.
  ///
  /// The model is downloaded on first use (needs internet once), then works
  /// fully offline.
  static Future<String> recognizeStrokes(
    List<Stroke> strokes, {
    String languageCode = 'en',
  }) async {
    if (strokes.isEmpty) return '';

    final recognizer = mlkit.DigitalInkRecognizer(languageCode: languageCode);
    try {
      final ready = await recognizer.ensureModel();
      if (!ready) {
        throw StateError('Model "$languageCode" belum bisa diunduh. '
            'Sambungkan internet lalu coba lagi.');
      }

      final ink = mlkit.Ink()
        ..strokes = [
          for (final stroke in strokes)
            mlkit.Stroke()
              ..points = _pointsOf(stroke),
        ];

      final candidates = await recognizer.recognize(
        ink,
        context: mlkit.DigitalInkRecognitionContext(
          writingArea: mlkit.WritingArea(width: 1200, height: 1700),
        ),
      );
      if (candidates.isEmpty) return '';
      return candidates.first.text.trim();
    } finally {
      try {
        await recognizer.close();
      } catch (e) {
        _log.fine('Closing recognizer failed: $e');
      }
    }
  }

  /// ML Kit wants timestamps; Saber only keeps geometry, so points get a
  /// synthetic 8 ms spacing (enough for the model's ordering).
  static List<mlkit.StrokePoint> _pointsOf(Stroke stroke) {
    final polygon = stroke.lowQualityPolygon;
    return [
      for (var i = 0; i < polygon.length; i++)
        mlkit.StrokePoint(x: polygon[i].dx, y: polygon[i].dy, t: i * 8),
    ];
  }

  static String _sidecarPath(String notePath) => '$notePath.ocr';

  static Future<void> saveText(String notePath, String text) async {
    await FileManager.writeFile(
      _sidecarPath(notePath),
      utf8.encode(text),
      awaitWrite: true,
    );
  }

  static Future<String?> readText(String notePath) async {
    try {
      final bytes = await FileManager.readFile(_sidecarPath(notePath));
      if (bytes == null) return null;
      return utf8.decode(bytes, allowMalformed: true);
    } catch (e) {
      if (kDebugMode) _log.fine('No OCR text for $notePath: $e');
      return null;
    }
  }
}
