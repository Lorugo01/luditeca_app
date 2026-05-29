import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../widgets/app_shell_layout.dart';
import '../controllers/profile_controller.dart';
import '../data/profile_achievements.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  late final ProfileController controller;
  AchievementCategory? _filter;

  @override
  void initState() {
    super.initState();
    controller = Get.find<ProfileController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShellLayout(
      body: Container(
        color: AppLayoutTokens.scaffoldBackground,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onBack: () => Get.back()),
              _CategoryChips(
                selected: _filter,
                onSelected: (c) => setState(() => _filter = c),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.achievementsLoading.value &&
                      controller.achievements.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = controller.achievements.where((a) {
                    if (_filter == null) return true;
                    return a.def.category == _filter;
                  }).toList();

                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhuma conquista nesta categoria.',
                        style: TextStyle(
                          color: AppLayoutTokens.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.loadAchievements,
                    color: AppLayoutTokens.primary,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _AchievementTile(item: items[index]);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppLayoutTokens.cardBackground,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, color: AppLayoutTokens.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Obx(() {
              final c = Get.find<ProfileController>();
              final unlocked =
                  c.achievements.where((a) => a.unlocked && !a.def.comingSoon).length;
              final total = c.achievements
                  .where((a) => !a.def.comingSoon)
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🏆 Conquistas',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppLayoutTokens.primary,
                    ),
                  ),
                  Text(
                    '$unlocked de $total desbloqueadas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppLayoutTokens.textPrimary,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({required this.selected, required this.onSelected});

  final AchievementCategory? selected;
  final ValueChanged<AchievementCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _chip('Todas', selected == null, () => onSelected(null)),
          for (final cat in AchievementCategory.values)
            _chip(cat.label, selected == cat, () => onSelected(cat)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: active,
        onSelected: (_) => onTap(),
        selectedColor: AppLayoutTokens.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          color: active ? Colors.white : AppLayoutTokens.textPrimary,
        ),
        backgroundColor: AppLayoutTokens.cardBackground,
        side: BorderSide(color: AppLayoutTokens.subtleBorder),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.item});

  final AchievementProgress item;

  @override
  Widget build(BuildContext context) {
    final def = item.def;
    final locked = def.comingSoon;
    final done = item.unlocked && !locked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppLayoutTokens.elevatedSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: done
              ? AppLayoutTokens.primary.withAlpha(100)
              : AppLayoutTokens.subtleBorder,
          width: done ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(def.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        def.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppLayoutTokens.textPrimary,
                        ),
                      ),
                    ),
                    if (locked)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppLayoutTokens.accent.withAlpha(40),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Em breve',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppLayoutTokens.textPrimary,
                          ),
                        ),
                      )
                    else
                      Text(
                        '+${def.xpReward} XP',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppLayoutTokens.primary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  def.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppLayoutTokens.elevatedSurfaceMuted,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: item.progressFraction.clamp(0.04, 1.0),
                      minHeight: 8,
                      backgroundColor: AppLayoutTokens.primary.withAlpha(36),
                      color: done
                          ? AppLayoutTokens.accent
                          : AppLayoutTokens.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.progressLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppLayoutTokens.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 4),
              child: Icon(Icons.check_circle_rounded, color: AppLayoutTokens.primary),
            ),
        ],
      ),
    );
  }
}
