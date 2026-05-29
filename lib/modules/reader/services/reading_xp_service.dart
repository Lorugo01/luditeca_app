import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../profile/data/profile_xp_rewards.dart';

/// Atribui XP por páginas lidas (30/página) e tempo de leitura (30/hora).
class ReadingXpService {
  ReadingXpService._();
  static final ReadingXpService instance = ReadingXpService._();

  final LuditecaApiService _api = LuditecaApiService();
  final Set<String> _localPageKeys = {};

  int? _sessionBookId;
  DateTime? _sessionStartedAt;
  Timer? _syncTimer;
  int _pendingSeconds = 0;

  bool get _canAward {
    if (!Get.isRegistered<AuthController>()) return false;
    return Get.find<AuthController>().isAuthenticated && _api.isAuthenticated;
  }

  void beginSession(int bookId) {
    endSession(syncTime: false);
    _sessionBookId = bookId;
    _sessionStartedAt = DateTime.now();
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => unawaited(_flushReadingSeconds()),
    );
  }

  Future<void> endSession({bool syncTime = true}) async {
    _syncTimer?.cancel();
    _syncTimer = null;
    if (syncTime) {
      await _flushReadingSeconds();
    }
    _sessionBookId = null;
    _sessionStartedAt = null;
    _pendingSeconds = 0;
  }

  Future<void> onPageRead(int bookId, int pageIndex) async {
    if (!_canAward || pageIndex < 0) return;

    final key = '$bookId:$pageIndex';
    if (_localPageKeys.contains(key)) return;
    _localPageKeys.add(key);

    try {
      final result = await _api.awardReadingXp(
        pages: [
          {'book_id': bookId.toString(), 'page_index': pageIndex},
        ],
      );
      if (result == null) {
        _localPageKeys.remove(key);
        return;
      }
      _applyServerResult(result);
    } catch (e) {
      _localPageKeys.remove(key);
      debugPrint('Erro ao atribuir XP de página: $e');
    }
  }

  Future<void> _flushReadingSeconds() async {
    if (!_canAward || _sessionBookId == null) return;

    var seconds = _pendingSeconds;
    if (_sessionStartedAt != null) {
      seconds += DateTime.now().difference(_sessionStartedAt!).inSeconds;
      _sessionStartedAt = DateTime.now();
    }
    _pendingSeconds = 0;

    if (seconds < 30) return;

    try {
      final result = await _api.awardReadingXp(readingSeconds: seconds);
      if (result != null) {
        _applyServerResult(result);
      } else {
        _pendingSeconds += seconds;
      }
    } catch (e) {
      _pendingSeconds += seconds;
      debugPrint('Erro ao atribuir XP de tempo: $e');
    }
  }

  void _applyServerResult(Map<String, dynamic> result) {
    if (Get.isRegistered<ProfileController>()) {
      Get.find<ProfileController>().applyGamificationResult(result);
    }

    final granted = _asInt(result['xp_granted']);
    if (granted > 0) {
      debugPrint(
        'XP +$granted (${ProfileXpRewards.perPage}/página, '
        '${ProfileXpRewards.perHour}/hora)',
      );
    }
  }

  static int _asInt(dynamic value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }
}
