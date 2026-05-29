import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/preferences/layout_option.dart';

/// Bottom sheet para escolher layout (menu, atividades ou biblioteca).
Future<void> showSettingsLayoutPicker({
  required String title,
  required List<LayoutOption> options,
  required String selectedId,
  required ValueChanged<String> onSelected,
}) {
  return Get.bottomSheet<void>(
    _SettingsLayoutPickerSheet(
      title: title,
      options: options,
      selectedId: selectedId,
      onSelected: onSelected,
    ),
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
  );
}

class _SettingsLayoutPickerSheet extends StatelessWidget {
  const _SettingsLayoutPickerSheet({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final String title;
  final List<LayoutOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 16),
      decoration: BoxDecoration(
        color: AppLayoutTokens.scaffoldBackground,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = option.id == selectedId;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      onSelected(option.id);
                      Get.back();
                    },
                    child: Ink(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppLayoutTokens.primary.withAlpha(36)
                            : AppLayoutTokens.cardBackground.withAlpha(128),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selected
                              ? AppLayoutTokens.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              option.emoji,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: AppLayoutTokens.textPrimary,
                                  ),
                                ),
                                Text(
                                  option.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppLayoutTokens.textPrimary.withAlpha(153),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: AppLayoutTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
