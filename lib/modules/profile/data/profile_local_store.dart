import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Dados do perfil do aluno guardados **localmente** (SharedPreferences).
/// Paridade com `localProfiles.js` do Play — idade, XP, avatar, etc.
class ProfileLocalData {
  const ProfileLocalData({
    this.displayName,
    this.age = 10,
    this.avatarId = 'girl1',
    this.xpTotal = 0,
    this.xpBalance = 0,
    this.badges = const [],
  });

  final String? displayName;
  final int age;
  final String avatarId;
  final int xpTotal;
  final int xpBalance;
  final List<String> badges;

  ProfileLocalData copyWith({
    String? displayName,
    int? age,
    String? avatarId,
    int? xpTotal,
    int? xpBalance,
    List<String>? badges,
  }) {
    return ProfileLocalData(
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      avatarId: avatarId ?? this.avatarId,
      xpTotal: xpTotal ?? this.xpTotal,
      xpBalance: xpBalance ?? this.xpBalance,
      badges: badges ?? this.badges,
    );
  }

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'display_name': displayName,
        'age': age,
        'avatar_id': avatarId,
        'xp_total': xpTotal,
        'xp_balance': xpBalance,
        'badges': badges,
      };

  factory ProfileLocalData.fromJson(Map<String, dynamic> json) {
    return ProfileLocalData(
      displayName: json['display_name']?.toString(),
      age: _asInt(json['age'], 10).clamp(1, 99),
      avatarId: json['avatar_id']?.toString() ?? 'girl1',
      xpTotal: _asInt(json['xp_total'], 0),
      xpBalance: _asInt(json['xp_balance'], 0),
      badges: (json['badges'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  static int _asInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? fallback;
  }
}

/// Persistência local por utilizador autenticado.
abstract final class ProfileLocalStore {
  static String _key(String userId) => 'luditeca_local_profile_$userId';

  static Future<ProfileLocalData> load(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(userId));
    if (raw == null || raw.isEmpty) {
      return const ProfileLocalData();
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return ProfileLocalData.fromJson(map);
    } catch (_) {
      return const ProfileLocalData();
    }
  }

  static Future<void> save(String userId, ProfileLocalData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(userId), jsonEncode(data.toJson()));
    // Chave legada (idade) — mantida para compatibilidade.
    await prefs.setInt('profile_age_$userId', data.age.clamp(1, 99));
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(userId));
    await prefs.remove('profile_age_$userId');
  }
}
