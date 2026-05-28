/// Opção de layout (paridade com `Settings.jsx` do Play).
class LayoutOption {
  const LayoutOption({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;

  String get pickerLabel => '$emoji $title';
}

const List<LayoutOption> kMenuLayoutOptions = [
  LayoutOption(
    id: 'grid',
    emoji: '⊞',
    title: 'Grade 2×2',
    description: 'Cards em grade compacta',
  ),
  LayoutOption(
    id: 'grid-large',
    emoji: '⬛',
    title: 'Grade Expandida',
    description: 'Cards grandes com ícone lateral',
  ),
  LayoutOption(
    id: 'list',
    emoji: '☰',
    title: 'Lista',
    description: 'Itens em lista compacta',
  ),
  LayoutOption(
    id: 'slide',
    emoji: '→',
    title: 'Deslizante',
    description: 'Rolagem horizontal',
  ),
];

const List<LayoutOption> kActivitiesLayoutOptions = [
  LayoutOption(
    id: 'grid',
    emoji: '⊞',
    title: 'Grade 2×2',
    description: 'Cards em grade compacta',
  ),
  LayoutOption(
    id: 'grid-large',
    emoji: '⬛',
    title: 'Grade Expandida',
    description: 'Cards grandes com ícone lateral',
  ),
  LayoutOption(
    id: 'list',
    emoji: '☰',
    title: 'Lista',
    description: 'Itens em lista compacta',
  ),
];

const List<LayoutOption> kLibraryLayoutOptions = [
  LayoutOption(
    id: 'shelf',
    emoji: '📚',
    title: 'Prateleira 3D',
    description: 'Livros em prateleira de madeira',
  ),
  LayoutOption(
    id: 'covers',
    emoji: '🖼️',
    title: 'Capas Expandidas',
    description: 'Capas grandes em grid 2 colunas',
  ),
  LayoutOption(
    id: 'grid',
    emoji: '⊞',
    title: 'Grade de Capas',
    description: 'Grid compacto 3 colunas',
  ),
  LayoutOption(
    id: 'list',
    emoji: '☰',
    title: 'Lista Detalhada',
    description: 'Lista com título e descrição',
  ),
];

LayoutOption? findLayoutOption(List<LayoutOption> options, String id) {
  for (final o in options) {
    if (o.id == id) return o;
  }
  return options.isNotEmpty ? options.first : null;
}
