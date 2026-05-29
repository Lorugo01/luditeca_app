import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../data/profile_avatars.dart';
import 'profile_avatar_image.dart';

/// Avatar circular do perfil (foto URL ou avatar predefinido).
class ProfileAvatarWidget extends StatelessWidget {
  const ProfileAvatarWidget({
    super.key,
    required this.imageUrl,
    this.avatarId,
    this.radius = 60,
  });

  final String imageUrl;
  final String? avatarId;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolvedId = avatarId ?? profileAvatarIdFromUrl(imageUrl);
    final preset = findProfileAvatar(resolvedId);
    final isDicebearPreset =
        preset != null && imageUrl.contains(preset.seed) && imageUrl.contains('dicebear');
    final useNetworkPhoto = imageUrl.isNotEmpty && !isDicebearPreset;

    return CircleAvatar(
      radius: radius,
      backgroundColor: preset != null
          ? Color(preset.backgroundColor)
          : AppLayoutTokens.cardBackground,
      child: ClipOval(
        child: SizedBox(
          width: radius * 2,
          height: radius * 2,
          child: useNetworkPhoto
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallback(preset),
                )
              : preset != null
                  ? ProfileAvatarImage(avatar: preset)
                  : _fallback(preset),
        ),
      ),
    );
  }

  Widget _fallback(ProfileAvatarOption? preset) {
    return ColoredBox(
      color: preset != null
          ? Color(preset.backgroundColor)
          : AppLayoutTokens.cardBackground,
      child: Icon(
        Icons.person,
        size: radius,
        color: AppLayoutTokens.textPrimary.withAlpha(120),
      ),
    );
  }
}
