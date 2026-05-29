/// Níveis por XP total (paridade com progressão do Play).
///
/// Limiares cumulativos: nível 1 → 0 XP, 2 → 100, 3 → 200, 4 → 400;
/// a partir do nível 5 o limiar duplica (800, 1600, …).
class ProfileXpLevel {
  const ProfileXpLevel._();

  static const List<int> _fixedThresholds = [0, 100, 200, 400];

  /// XP total mínimo para estar no [level] (nível 1 = 0).
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    if (level <= _fixedThresholds.length) {
      return _fixedThresholds[level - 1];
    }
    var threshold = 400;
    for (var l = 5; l <= level; l++) {
      threshold *= 2;
    }
    return threshold;
  }

  /// Nível actual a partir do XP total acumulado.
  static int levelFromTotalXp(int totalXp) {
    if (totalXp < 0) return 1;
    var level = 1;
    while (totalXpForLevel(level + 1) <= totalXp) {
      level++;
      if (level >= 99) break;
    }
    return level;
  }

  /// Progresso no nível actual (0.0 – 1.0) até ao próximo nível.
  static double progressInCurrentLevel(int totalXp) {
    final level = levelFromTotalXp(totalXp);
    final currentFloor = totalXpForLevel(level);
    final nextFloor = totalXpForLevel(level + 1);
    if (nextFloor <= currentFloor) return 1;
    return ((totalXp - currentFloor) / (nextFloor - currentFloor)).clamp(0.0, 1.0);
  }

  /// XP que falta para o próximo nível.
  static int xpUntilNextLevel(int totalXp) {
    final level = levelFromTotalXp(totalXp);
    final next = totalXpForLevel(level + 1);
    return (next - totalXp).clamp(0, 1 << 30);
  }

  static String emojiForLevel(int level) {
    if (level >= 7) return '🌟';
    if (level >= 5) return '📚';
    if (level >= 3) return '🚀';
    return '🌱';
  }

  static String titleForLevel(int level) {
    if (level >= 7) return 'Super Leitor';
    if (level >= 5) return 'Leitor Avançado';
    if (level >= 3) return 'Explorador';
    if (level >= 2) return 'Leitor Curioso';
    return 'Leitor Iniciante';
  }

  static ProfileLevelSnapshot snapshot(int totalXp) {
    final level = levelFromTotalXp(totalXp);
    return ProfileLevelSnapshot(
      level: level,
      totalXp: totalXp,
      xpFloor: totalXpForLevel(level),
      xpNextLevel: totalXpForLevel(level + 1),
      progress: progressInCurrentLevel(totalXp),
      xpRemaining: xpUntilNextLevel(totalXp),
      emoji: emojiForLevel(level),
      title: titleForLevel(level),
    );
  }
}

class ProfileLevelSnapshot {
  const ProfileLevelSnapshot({
    required this.level,
    required this.totalXp,
    required this.xpFloor,
    required this.xpNextLevel,
    required this.progress,
    required this.xpRemaining,
    required this.emoji,
    required this.title,
  });

  final int level;
  final int totalXp;
  final int xpFloor;
  final int xpNextLevel;
  final double progress;
  final int xpRemaining;
  final String emoji;
  final String title;
}
