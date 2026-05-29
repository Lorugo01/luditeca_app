/// Conquistas padrão (ids alinhados com o backend).
class ProfileAchievementDef {
  const ProfileAchievementDef({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
    required this.threshold,
    required this.xpReward,
    this.comingSoon = false,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final AchievementCategory category;
  final int threshold;
  final int xpReward;
  final bool comingSoon;
}

enum AchievementCategory {
  reading('Leitura'),
  books('Livros'),
  level('Nível'),
  time('Tempo'),
  favorites('Favoritos'),
  xp('XP'),
  activities('Atividades');

  const AchievementCategory(this.label);
  final String label;
}

/// Estado de uma conquista vindo da API ou calculado localmente.
class AchievementProgress {
  const AchievementProgress({
    required this.def,
    required this.current,
    required this.unlocked,
  });

  final ProfileAchievementDef def;
  final int current;
  final bool unlocked;

  double get progressFraction {
    if (def.comingSoon) return 0;
    if (def.threshold <= 0) return unlocked ? 1 : 0;
    return (current / def.threshold).clamp(0.0, 1.0);
  }

  String get progressLabel {
    if (def.comingSoon) return 'Em breve';
    if (unlocked) return 'Concluída';
    return '$current / ${def.threshold}';
  }

  factory AchievementProgress.fromApi(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? '';
    final def = findAchievementById(id) ??
        ProfileAchievementDef(
          id: id,
          emoji: json['emoji']?.toString() ?? '🏆',
          title: json['title']?.toString() ?? id,
          description: json['description']?.toString() ?? '',
          category: _categoryFromMetric(json['metric']?.toString()),
          threshold: _asInt(json['threshold']),
          xpReward: _asInt(json['xp_reward']),
          comingSoon: json['coming_soon'] == true,
        );

    return AchievementProgress(
      def: def,
      current: _asInt(json['current']),
      unlocked: json['unlocked'] == true,
    );
  }

  static AchievementCategory _categoryFromMetric(String? metric) {
    switch (metric) {
      case 'pages_read':
        return AchievementCategory.reading;
      case 'books_read':
        return AchievementCategory.books;
      case 'level':
        return AchievementCategory.level;
      case 'reading_hours':
        return AchievementCategory.time;
      case 'favorites':
        return AchievementCategory.favorites;
      case 'xp_total':
        return AchievementCategory.xp;
      case 'activities_done':
        return AchievementCategory.activities;
      default:
        return AchievementCategory.reading;
    }
  }

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

const List<ProfileAchievementDef> kProfileAchievements = [
  ProfileAchievementDef(
    id: 'pages_1',
    emoji: '📄',
    title: 'Primeira página',
    description: 'Leia 1 página',
    category: AchievementCategory.reading,
    threshold: 1,
    xpReward: 25,
  ),
  ProfileAchievementDef(
    id: 'pages_10',
    emoji: '📖',
    title: 'Leitor curioso',
    description: 'Leia 10 páginas',
    category: AchievementCategory.reading,
    threshold: 10,
    xpReward: 50,
  ),
  ProfileAchievementDef(
    id: 'pages_25',
    emoji: '📚',
    title: 'Maratonista',
    description: 'Leia 25 páginas',
    category: AchievementCategory.reading,
    threshold: 25,
    xpReward: 75,
  ),
  ProfileAchievementDef(
    id: 'pages_50',
    emoji: '🦉',
    title: 'Coruja literária',
    description: 'Leia 50 páginas',
    category: AchievementCategory.reading,
    threshold: 50,
    xpReward: 100,
  ),
  ProfileAchievementDef(
    id: 'pages_100',
    emoji: '🏅',
    title: 'Centurião',
    description: 'Leia 100 páginas',
    category: AchievementCategory.reading,
    threshold: 100,
    xpReward: 200,
  ),
  ProfileAchievementDef(
    id: 'pages_250',
    emoji: '⭐',
    title: 'Mestre das páginas',
    description: 'Leia 250 páginas',
    category: AchievementCategory.reading,
    threshold: 250,
    xpReward: 400,
  ),
  ProfileAchievementDef(
    id: 'pages_500',
    emoji: '👑',
    title: 'Lenda das páginas',
    description: 'Leia 500 páginas',
    category: AchievementCategory.reading,
    threshold: 500,
    xpReward: 800,
  ),
  ProfileAchievementDef(
    id: 'books_1',
    emoji: '🎉',
    title: 'Primeiro livro',
    description: 'Termine 1 livro',
    category: AchievementCategory.books,
    threshold: 1,
    xpReward: 100,
  ),
  ProfileAchievementDef(
    id: 'books_3',
    emoji: '🌟',
    title: 'Colecionador',
    description: 'Termine 3 livros',
    category: AchievementCategory.books,
    threshold: 3,
    xpReward: 150,
  ),
  ProfileAchievementDef(
    id: 'books_5',
    emoji: '🚀',
    title: 'Explorador',
    description: 'Termine 5 livros',
    category: AchievementCategory.books,
    threshold: 5,
    xpReward: 250,
  ),
  ProfileAchievementDef(
    id: 'books_10',
    emoji: '🏆',
    title: 'Bibliófilo',
    description: 'Termine 10 livros',
    category: AchievementCategory.books,
    threshold: 10,
    xpReward: 400,
  ),
  ProfileAchievementDef(
    id: 'books_25',
    emoji: '💎',
    title: 'Guardião da história',
    description: 'Termine 25 livros',
    category: AchievementCategory.books,
    threshold: 25,
    xpReward: 750,
  ),
  ProfileAchievementDef(
    id: 'books_50',
    emoji: '🌈',
    title: 'Lenda Luditeca',
    description: 'Termine 50 livros',
    category: AchievementCategory.books,
    threshold: 50,
    xpReward: 1200,
  ),
  ProfileAchievementDef(
    id: 'level_2',
    emoji: '🌱',
    title: 'Subindo de nível',
    description: 'Alcance o nível 2',
    category: AchievementCategory.level,
    threshold: 2,
    xpReward: 50,
  ),
  ProfileAchievementDef(
    id: 'level_3',
    emoji: '🚀',
    title: 'Explorador',
    description: 'Alcance o nível 3',
    category: AchievementCategory.level,
    threshold: 3,
    xpReward: 100,
  ),
  ProfileAchievementDef(
    id: 'level_5',
    emoji: '📚',
    title: 'Leitor dedicado',
    description: 'Alcance o nível 5',
    category: AchievementCategory.level,
    threshold: 5,
    xpReward: 200,
  ),
  ProfileAchievementDef(
    id: 'level_7',
    emoji: '🌟',
    title: 'Super leitor',
    description: 'Alcance o nível 7',
    category: AchievementCategory.level,
    threshold: 7,
    xpReward: 350,
  ),
  ProfileAchievementDef(
    id: 'level_10',
    emoji: '👑',
    title: 'Lenda viva',
    description: 'Alcance o nível 10',
    category: AchievementCategory.level,
    threshold: 10,
    xpReward: 500,
  ),
  ProfileAchievementDef(
    id: 'hours_1',
    emoji: '⏱️',
    title: 'Hora de leitura',
    description: 'Acumule 1 hora de leitura',
    category: AchievementCategory.time,
    threshold: 1,
    xpReward: 60,
  ),
  ProfileAchievementDef(
    id: 'hours_5',
    emoji: '⌛',
    title: 'Maratona',
    description: 'Acumule 5 horas de leitura',
    category: AchievementCategory.time,
    threshold: 5,
    xpReward: 200,
  ),
  ProfileAchievementDef(
    id: 'hours_10',
    emoji: '🕰️',
    title: 'Viajante do tempo',
    description: 'Acumule 10 horas de leitura',
    category: AchievementCategory.time,
    threshold: 10,
    xpReward: 400,
  ),
  ProfileAchievementDef(
    id: 'hours_24',
    emoji: '🌙',
    title: 'Noite de histórias',
    description: 'Acumule 24 horas de leitura',
    category: AchievementCategory.time,
    threshold: 24,
    xpReward: 800,
  ),
  ProfileAchievementDef(
    id: 'fav_1',
    emoji: '❤️',
    title: 'Primeiro favorito',
    description: 'Guarde 1 livro nos favoritos',
    category: AchievementCategory.favorites,
    threshold: 1,
    xpReward: 30,
  ),
  ProfileAchievementDef(
    id: 'fav_5',
    emoji: '💝',
    title: 'Lista especial',
    description: 'Guarde 5 livros nos favoritos',
    category: AchievementCategory.favorites,
    threshold: 5,
    xpReward: 100,
  ),
  ProfileAchievementDef(
    id: 'fav_10',
    emoji: '💖',
    title: 'Coração literário',
    description: 'Guarde 10 livros nos favoritos',
    category: AchievementCategory.favorites,
    threshold: 10,
    xpReward: 200,
  ),
  ProfileAchievementDef(
    id: 'xp_500',
    emoji: '✨',
    title: 'Brilho inicial',
    description: 'Acumule 500 XP',
    category: AchievementCategory.xp,
    threshold: 500,
    xpReward: 50,
  ),
  ProfileAchievementDef(
    id: 'xp_2000',
    emoji: '🔥',
    title: 'Em chamas',
    description: 'Acumule 2000 XP',
    category: AchievementCategory.xp,
    threshold: 2000,
    xpReward: 150,
  ),
  ProfileAchievementDef(
    id: 'xp_5000',
    emoji: '💫',
    title: 'Estrela Luditeca',
    description: 'Acumule 5000 XP',
    category: AchievementCategory.xp,
    threshold: 5000,
    xpReward: 300,
  ),
  ProfileAchievementDef(
    id: 'activity_1',
    emoji: '🎮',
    title: 'Primeira atividade',
    description: 'Complete 1 atividade',
    category: AchievementCategory.activities,
    threshold: 1,
    xpReward: 100,
    comingSoon: true,
  ),
  ProfileAchievementDef(
    id: 'activity_5',
    emoji: '🎯',
    title: 'Aventureiro',
    description: 'Complete 5 atividades',
    category: AchievementCategory.activities,
    threshold: 5,
    xpReward: 250,
    comingSoon: true,
  ),
  ProfileAchievementDef(
    id: 'puzzle_1',
    emoji: '🧩',
    title: 'Mestre dos puzzles',
    description: 'Complete 1 puzzle',
    category: AchievementCategory.activities,
    threshold: 1,
    xpReward: 80,
    comingSoon: true,
  ),
];

ProfileAchievementDef? findAchievementById(String id) {
  for (final a in kProfileAchievements) {
    if (a.id == id) return a;
  }
  return null;
}
