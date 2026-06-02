import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../data/profile_avatars.dart';

/// Carrega avatar Dicebear (PNG; SVG como fallback) — `Image.network` não renderiza SVG.
class ProfileAvatarImage extends StatelessWidget {
  const ProfileAvatarImage({
    super.key,
    required this.avatar,
    this.fit = BoxFit.cover,
  });

  final ProfileAvatarOption avatar;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Color(avatar.backgroundColor),
      child: CachedNetworkImage(
        imageUrl: avatar.pngUrl,
        fit: fit,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) => Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(avatar.backgroundColor).withAlpha(200),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => SvgPicture.network(
          avatar.svgUrl,
          fit: fit,
          placeholderBuilder: (_) => _letterFallback(),
        ),
      ),
    );
  }

  Widget _letterFallback() {
    return Center(
      child: Text(
        avatar.label[0],
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(avatar.backgroundColor).withAlpha(220),
        ),
      ),
    );
  }
}
