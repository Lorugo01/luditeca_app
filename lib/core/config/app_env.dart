import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Variáveis em compile-time (`--dart-define`) com ajuste no Android.
///
/// Emulador (recomendado no Windows): `adb reverse tcp:3020 tcp:3020` e
/// [androidDevHost] = `127.0.0.1` (padrão).
///
/// Alternativas se `10.0.2.2` falhar: `--dart-define=ANDROID_DEV_HOST=10.0.2.2`
/// ou IP LAN do PC: `--dart-define=ANDROID_DEV_HOST=192.168.x.x`
class AppEnv {
  AppEnv._();

  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'local',
  );

  static const String dataSource = String.fromEnvironment(
    'DATA_SOURCE',
    defaultValue: 'vps_api',
  );

  static const String _apiBaseUrlRaw = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3020',
  );

  static const String _mediaBaseUrlRaw = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'http://localhost:3020/media',
  );

  /// Host usado no Android quando a URL contém localhost/127.0.0.1.
  /// Padrão `127.0.0.1` + `adb reverse` (mais estável no emulador Windows).
  static const String androidDevHost = String.fromEnvironment(
    'ANDROID_DEV_HOST',
    defaultValue: '127.0.0.1',
  );

  static String get apiBaseUrl => _hostLoopbackForDevice(_apiBaseUrlRaw);

  static String get mediaBaseUrl => _hostLoopbackForDevice(_mediaBaseUrlRaw);

  static String _hostLoopbackForDevice(String url) {
    if (kIsWeb || !_isAndroid) return url;
    if (!url.contains('localhost') && !url.contains('127.0.0.1')) {
      return url;
    }
    return url
        .replaceAll('127.0.0.1', androidDevHost)
        .replaceAll('localhost', androidDevHost);
  }

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}
