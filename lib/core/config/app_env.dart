import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

import 'env_loader.dart';

/// Configuração da app a partir do `.env` (asset) + overrides opcionais `--dart-define`.
///
/// - `APP_ENV=local` → API/media locais (defaults `localhost:3020`), salvo override no `.env`.
/// - `APP_ENV=production` → usa `API_BASE_URL` e `MEDIA_BASE_URL` do `.env`.
class AppEnv {
  AppEnv._();

  static const _localApiDefault = 'http://localhost:3020';
  static const _localMediaDefault = 'http://localhost:3020/media';
  static const _prodApiDefault = 'https://luditeca.com/api';
  static const _prodMediaDefault = 'https://luditeca.com/media';

  static const _appEnvDefine = String.fromEnvironment('APP_ENV');
  static const _dataSourceDefine = String.fromEnvironment('DATA_SOURCE');
  static const _apiDefine = String.fromEnvironment('API_BASE_URL');
  static const _mediaDefine = String.fromEnvironment('MEDIA_BASE_URL');
  static const _androidHostDefine = String.fromEnvironment('ANDROID_DEV_HOST');

  static late final String appEnv;
  static late final String dataSource;
  static late final String androidDevHost;
  static late final String _apiBaseUrlRaw;
  static late final String _mediaBaseUrlRaw;

  static bool get isLocal => _isLocalEnv(appEnv);

  static Future<void> load() async {
    await EnvLoader.load();

    appEnv = _firstNonEmpty([
      _appEnvDefine,
      EnvLoader.get('APP_ENV'),
      'production',
    ]);

    dataSource = _firstNonEmpty([
      _dataSourceDefine,
      EnvLoader.get('DATA_SOURCE'),
      'vps_api',
    ]);

    androidDevHost = _firstNonEmpty([
      _androidHostDefine,
      EnvLoader.get('ANDROID_DEV_HOST'),
      '127.0.0.1',
    ]);

    if (isLocal) {
      _apiBaseUrlRaw = _firstNonEmpty([
        _apiDefine,
        EnvLoader.get('API_BASE_URL'),
        _localApiDefault,
      ]);
      _mediaBaseUrlRaw = _firstNonEmpty([
        _mediaDefine,
        EnvLoader.get('MEDIA_BASE_URL'),
        _localMediaDefault,
      ]);
    } else {
      _apiBaseUrlRaw = _firstNonEmpty([
        _apiDefine,
        EnvLoader.get('API_BASE_URL'),
        _prodApiDefault,
      ]);
      _mediaBaseUrlRaw = _firstNonEmpty([
        _mediaDefine,
        EnvLoader.get('MEDIA_BASE_URL'),
        _prodMediaDefault,
      ]);
    }

    debugPrint(
      'AppEnv: env=$appEnv; dataSource=$dataSource; '
      'api=$apiBaseUrl; media=$mediaBaseUrl',
    );
  }

  static String get apiBaseUrl => _hostLoopbackForDevice(_apiBaseUrlRaw);

  static String get mediaBaseUrl => _hostLoopbackForDevice(_mediaBaseUrlRaw);

  static String _firstNonEmpty(List<String?> candidates) {
    for (final c in candidates) {
      final v = c?.trim();
      if (v != null && v.isNotEmpty) return v;
    }
    return '';
  }

  static bool _isLocalEnv(String env) {
    switch (env.toLowerCase()) {
      case 'local':
      case 'dev':
      case 'development':
        return true;
      default:
        return false;
    }
  }

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
