/// Avatares predefinidos (paridade com `ProfilePicturePicker.jsx` do Play).
class ProfileAvatarOption {
  const ProfileAvatarOption({
    required this.id,
    required this.seed,
    required this.backgroundHex,
    required this.label,
  });

  final String id;
  final String seed;
  final String backgroundHex;
  final String label;

  int get backgroundColor => int.parse('FF$backgroundHex', radix: 16);

  /// PNG para Flutter (`Image.network`); SVG só como fallback.
  String get pngUrl =>
      'https://api.dicebear.com/7.x/fun-emoji/png?seed=$seed&size=128&backgroundColor=$backgroundHex';

  String get svgUrl =>
      'https://api.dicebear.com/7.x/fun-emoji/svg?seed=$seed&backgroundColor=$backgroundHex';

  @Deprecated('Use pngUrl')
  String get url => svgUrl;
}

/// Os 16 rostos do Play (`PROFILE_PICTURES`).
const List<ProfileAvatarOption> kProfileAvatars = [
  ProfileAvatarOption(id: 'girl1', seed: 'Lily', backgroundHex: 'ffdfbf', label: 'Lily'),
  ProfileAvatarOption(id: 'boy1', seed: 'Lucas', backgroundHex: 'b6e3f4', label: 'Lucas'),
  ProfileAvatarOption(id: 'girl2', seed: 'Sofia', backgroundHex: 'ffd6e0', label: 'Sofia'),
  ProfileAvatarOption(id: 'boy2', seed: 'Miguel', backgroundHex: 'c0aede', label: 'Miguel'),
  ProfileAvatarOption(id: 'girl3', seed: 'Luna', backgroundHex: 'd1f4e0', label: 'Luna'),
  ProfileAvatarOption(id: 'boy3', seed: 'Pedro', backgroundHex: 'ffecd2', label: 'Pedro'),
  ProfileAvatarOption(id: 'girl4', seed: 'Alice', backgroundHex: 'f9c6ff', label: 'Alice'),
  ProfileAvatarOption(id: 'boy4', seed: 'Davi', backgroundHex: 'c2f0fc', label: 'Davi'),
  ProfileAvatarOption(id: 'girl5', seed: 'Isabela', backgroundHex: 'ffe4ba', label: 'Isabela'),
  ProfileAvatarOption(id: 'boy5', seed: 'Mateus', backgroundHex: 'bbf7d0', label: 'Mateus'),
  ProfileAvatarOption(id: 'girl6', seed: 'Valentina', backgroundHex: 'fce7f3', label: 'Valentina'),
  ProfileAvatarOption(id: 'boy6', seed: 'Rafael', backgroundHex: 'dbeafe', label: 'Rafael'),
  ProfileAvatarOption(id: 'girl7', seed: 'Manuela', backgroundHex: 'fef9c3', label: 'Manuela'),
  ProfileAvatarOption(id: 'boy7', seed: 'Gabriel', backgroundHex: 'f0fdf4', label: 'Gabriel'),
  ProfileAvatarOption(id: 'girl8', seed: 'Heloisa', backgroundHex: 'ede9fe', label: 'Heloísa'),
  ProfileAvatarOption(id: 'boy8', seed: 'Bernardo', backgroundHex: 'fee2e2', label: 'Bernardo'),
];

ProfileAvatarOption? findProfileAvatar(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final a in kProfileAvatars) {
    if (a.id == id) return a;
  }
  return null;
}

/// Resolve o id do avatar a partir da URL guardada em `icone`.
String? profileAvatarIdFromUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  for (final a in kProfileAvatars) {
    if (url.contains(a.seed)) return a.id;
  }
  return null;
}
