import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:saber/data/ai/ai_settings.dart';

/// Morisnote: minimal streaming client for any OpenAI-compatible endpoint.
class AiClient {
  AiClient._();

  /// Sends [messages] (`{role, content}`) and yields the answer as it streams.
  static Stream<String> streamChat(List<Map<String, String>> messages) async* {
    final key = AiSettings.apiKey;
    if (key == null || key.isEmpty) {
      throw StateError('API key belum diisi. Tap ikon pengaturan di tab AI.');
    }

    final uri = Uri.parse('${AiSettings.baseUrl.value}/chat/completions');
    final request = http.Request('POST', uri)
      ..headers.addAll({
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
        'Authorization': 'Bearer $key',
      })
      ..body = jsonEncode({
        'model': AiSettings.model.value,
        'messages': messages,
        'stream': true,
      });

    final client = http.Client();
    try {
      final response = await client.send(request);
      if (response.statusCode != 200) {
        final body = await response.stream.bytesToString();
        final snippet = body.length > 300 ? body.substring(0, 300) : body;
        throw StateError('HTTP ${response.statusCode}: $snippet');
      }

      var buffer = '';
      await for (final chunk in response.stream.transform(utf8.decoder)) {
        buffer += chunk;
        while (true) {
          final newline = buffer.indexOf('\n');
          if (newline < 0) break;
          final line = buffer.substring(0, newline).trim();
          buffer = buffer.substring(newline + 1);

          if (line.isEmpty || line.startsWith(':')) continue;
          if (!line.startsWith('data:')) continue;

          final data = line.substring(5).trim();
          if (data == '[DONE]') return;

          final delta = _deltaOf(data);
          if (delta != null && delta.isNotEmpty) yield delta;
        }
      }
    } finally {
      client.close();
    }
  }

  static String? _deltaOf(String data) {
    try {
      final json = jsonDecode(data);
      if (json is! Map) return null;
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) return null;
      final first = choices.first;
      if (first is! Map) return null;
      final delta = first['delta'];
      if (delta is Map && delta['content'] is String) {
        return delta['content'] as String;
      }
      final message = first['message'];
      if (message is Map && message['content'] is String) {
        return message['content'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
