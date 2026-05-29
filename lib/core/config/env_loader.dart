import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Carrega o ficheiro `.env` incluído em `pubspec.yaml` (assets).
class EnvLoader {
  EnvLoader._();

  static Map<String, String> _values = {};

  static Future<void> load() async {
    try {
      final raw = await rootBundle.loadString('.env');
      _values = _parse(raw);
    } catch (e) {
      debugPrint('EnvLoader: .env ausente ou inválido ($e); defaults do código.');
      _values = {};
    }
  }

  static String? get(String key) => _values[key];

  static Map<String, String> _parse(String raw) {
    final out = <String, String>{};
    for (final line in raw.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq <= 0) continue;
      final key = trimmed.substring(0, eq).trim();
      var value = trimmed.substring(eq + 1).trim();
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.substring(1, value.length - 1);
      }
      out[key] = value;
    }
    return out;
  }
}
