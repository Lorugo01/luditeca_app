/// Faixa etária derivada da idade (paridade com perfis infantis do Play, 1–12 anos).
class ProfileAgeBand {
  const ProfileAgeBand({
    required this.label,
    required this.range,
    required this.emoji,
  });

  final String label;
  final String range;
  final String emoji;

  static ProfileAgeBand forAge(int age) {
    final years = age.clamp(1, 99);
    if (years <= 5) {
      return const ProfileAgeBand(
        emoji: '🧸',
        label: 'Infantil',
        range: '3–5 anos',
      );
    }
    if (years <= 8) {
      return const ProfileAgeBand(
        emoji: '🌱',
        label: 'Iniciante',
        range: '6–8 anos',
      );
    }
    if (years <= 12) {
      return const ProfileAgeBand(
        emoji: '🚀',
        label: 'Intermediário',
        range: '9–12 anos',
      );
    }
    return const ProfileAgeBand(
      emoji: '📚',
      label: 'Avançado',
      range: '13+ anos',
    );
  }

  String get display => '$emoji $label · $range';
}
