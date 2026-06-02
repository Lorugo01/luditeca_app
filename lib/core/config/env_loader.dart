import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Carrega o ficheiro `.env` (asset declarado em `pubspec.yaml`).
///
/// Usa o pacote `flutter_dotenv` (parser testado: aspas, escapes, comentários)
/// em vez de um parser manual. Mantém a mesma API (`load`/`get`) para o resto da app.
class EnvLoader {
  EnvLoader._();

  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // Sem `.env` (ou inválido) a app recorre aos defaults definidos em código.
      debugPrint('EnvLoader: .env ausente ou inválido ($e); a usar defaults.');
    }
  }

  /// Devolve o valor da chave (ou `null` se ausente/vazia).
  static String? get(String key) {
    if (!dotenv.isInitialized) return null;
    final value = dotenv.maybeGet(key)?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
