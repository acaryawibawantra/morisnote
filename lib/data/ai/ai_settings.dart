import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Morisnote: settings for the AI chat tab.
///
/// The endpoint is any OpenAI-compatible server (defaults to a self-hosted
/// 9router). The API key lives in the platform keystore and is never logged.
class AiSettings {
  AiSettings._();

  static const _storage = FlutterSecureStorage();
  static const defaultBaseUrl = 'https://9router.dewadigital.app/v1';
  static const defaultModel = 'main';

  static const _kBaseUrl = 'aiBaseUrl';
  static const _kModel = 'aiModel';
  static const _kApiKey = 'aiApiKey';

  static final baseUrl = ValueNotifier<String>(defaultBaseUrl);
  static final model = ValueNotifier<String>(defaultModel);

  static String? _apiKey;
  static String? get apiKey => _apiKey;
  static bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  static Future<void> load() async {
    try {
      baseUrl.value = await _storage.read(key: _kBaseUrl) ?? defaultBaseUrl;
      model.value = await _storage.read(key: _kModel) ?? defaultModel;
      _apiKey = await _storage.read(key: _kApiKey);
    } catch (e) {
      if (kDebugMode) debugPrint('AiSettings: could not load settings: $e');
    }
  }

  static Future<void> save({
    required String baseUrl,
    required String model,
    required String apiKey,
  }) async {
    final url = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final name = model.trim();
    final key = apiKey.trim();

    await _storage.write(key: _kBaseUrl, value: url);
    await _storage.write(key: _kModel, value: name);
    if (key.isEmpty) {
      await _storage.delete(key: _kApiKey);
      _apiKey = null;
    } else {
      await _storage.write(key: _kApiKey, value: key);
      _apiKey = key;
    }

    AiSettings.baseUrl.value = url.isEmpty ? defaultBaseUrl : url;
    AiSettings.model.value = name.isEmpty ? defaultModel : name;
  }
}
