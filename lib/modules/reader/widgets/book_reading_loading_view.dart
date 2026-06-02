import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';

import 'offline_book_image.dart';

/// Ecrã de preparação do livro (metadados + download de imagens).
class BookReadingLoadingView extends StatelessWidget {
  const BookReadingLoadingView({
    super.key,
    required this.title,
    required this.phaseLabel,
    required this.progress,
    this.coverUrl,
  });

  final String title;
  final String phaseLabel;
  final double progress;
  final String? coverUrl;

  @override
  Widget build(BuildContext context) {
    final pct = (progress.clamp(0.0, 1.0) * 100).round();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0E1E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 500),
                child: _CoverThumb(url: coverUrl),
              ),
              const SizedBox(height: 28),
              FadeIn(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeInUp(
                delay: const Duration(milliseconds: 350),
                child: const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFF4DA3FF),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeIn(
                delay: const Duration(milliseconds: 450),
                child: Text(
                  phaseLabel,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(200),
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FadeIn(
                delay: const Duration(milliseconds: 500),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress.clamp(0.0, 1.0) : null,
                    minHeight: 6,
                    backgroundColor: Colors.white.withAlpha(40),
                    color: const Color(0xFF4DA3FF),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress > 0 ? '$pct%' : '',
                style: TextStyle(
                  color: Colors.white.withAlpha(160),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  const _CoverThumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.trim().isNotEmpty;
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(120),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        color: const Color(0xFF1A1A2E),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasUrl
          ? OfflineBookImage(
              url: url!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _PlaceholderIcon(),
            )
          : const _PlaceholderIcon(),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  const _PlaceholderIcon();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF4DA3FF)),
    );
  }
}
