import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../data/profile_avatars.dart';
import 'profile_avatar_image.dart';

/// Grelha de avatares (paridade com `ProfilePicturePicker` do Play).
class ProfileAvatarPicker extends StatelessWidget {
  const ProfileAvatarPicker({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.customUrlSelected = false,
  });

  final String selectedId;
  final bool customUrlSelected;
  final ValueChanged<ProfileAvatarOption> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: kProfileAvatars.length,
      itemBuilder: (context, index) {
        final avatar = kProfileAvatars[index];
        final selected = !customUrlSelected && avatar.id == selectedId;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => onSelected(avatar),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                color: Color(avatar.backgroundColor),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected ? AppLayoutTokens.primary : AppLayoutTokens.subtleBorder,
                  width: selected ? 3 : 1,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppLayoutTokens.primary.withAlpha(90),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: ProfileAvatarImage(avatar: avatar),
                  ),
                  if (selected)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppLayoutTokens.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
