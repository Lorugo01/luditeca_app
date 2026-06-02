import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'app_env.dart';

/// Em debug no Android, testa hosts até a API responder (evita depender só de adb reverse).
class DevApiResolver {
  DevApiResolver._();

  static String? _apiBase;
  static String? _mediaBase;

  static String get apiBaseUrl => _apiBase ?? AppEnv.apiBaseUrl;
  static String get mediaBaseUrl => _mediaBase ?? AppEnv.mediaBaseUrl;

  static Future<void> resolveIfNeeded() async {
    if (!kDebugMode || kIsWeb) return;
    try {
      if (!Platform.isAndroid) return;
    } catch (_) {
      return;
    }

    final raw = AppEnv.apiBaseUrl;
    if (!raw.contains('127.0.0.1') &&
        !raw.contains('localhost') &&
        !raw.contains('10.0.2.2')) {
      return;
    }

    final port = _extractPort(raw, fallback: 3020);
    final hosts = <String>{AppEnv.androidDevHost, '10.0.2.2'};

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 2),
        receiveTimeout: const Duration(seconds: 2),
        validateStatus: (_) => true,
      ),
    );

    for (final host in hosts) {
      final health = 'http://$host:$port/health';
      try {
        final res = await dio.get<dynamic>(health);
        if (res.statusCode == 200) {
          _apiBase = 'http://$host:$port';
          _mediaBase = 'http://$host:$port/media';
          debugPrint('DevApiResolver: API em $_apiBase');
          return;
        }
      } catch (_) {}
    }

    debugPrint(
      'DevApiResolver: API inacessível. Com emulador: .\\scripts\\adb-reverse-all.ps1 '
      'ou use launch "Tablet / IP LAN".',
    );
  }

  static int _extractPort(String url, {required int fallback}) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasPort) return uri.port;
    return fallback;
  }
}
