import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../widgets/book_card.dart';
import '../../reader/utils/reading_progress_helper.dart';
import '../controllers/home_controller.dart';

/// Faixa «Continue de onde parou» (mantém funcionalidade anterior).
class HomeContinueSection extends StatelessWidget {
  const HomeContinueSection({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoadingProgress) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (controller.booksInProgress.isEmpty) {
        return const SizedBox.shrink();
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Continue de onde parou',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: controller.booksInProgress.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final book = controller.booksInProgress[index];
                return BookCard(
                  book: book,
                  width: 110,
                  showDescription: false,
                  onTap: () {
                    openBookForReading(
                      book,
                      position: ReadingPosition(
                        page: _asInt(book['saved_page']),
                        step: _asInt(book['saved_step']),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      );
    });
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
