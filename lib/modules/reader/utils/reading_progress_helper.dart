import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../pages/animated_book_reader_page.dart';
import '../pages/digital_book_reader_page.dart';
import '../pages/interactive_book_reader_page.dart';
import '../pages/reader_page.dart';
import '../pages/reader_webview_page.dart';
import 'book_pages_loader.dart';
import '../../home/controllers/home_controller.dart';

/// Posição guardada no perfil (`progress[bookId] = { page, step }`).
class ReadingPosition {
  final int page;
  final int step;

  const ReadingPosition({this.page = 0, this.step = 0});

  bool get hasProgress => page > 0 || step > 0;
}

class ReadingProgressHelper {
  ReadingProgressHelper._();

  static LuditecaApiService get _api => LuditecaApiService();

  static AuthController? get _auth {
    if (!Get.isRegistered<AuthController>()) return null;
    return Get.find<AuthController>();
  }

  static Future<ReadingPosition?> getPosition(int bookId) async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return null;

    try {
      final userId = auth.currentUser!['id'].toString();
      final profile = await _api.getUserProfile(userId);
      if (profile == null) return null;

      final progress = profile['progress'];
      if (progress is! Map) return null;

      final raw = progress[bookId.toString()] ?? progress[bookId];
      if (raw is! Map) return null;

      final page = _asInt(raw['page']);
      final step = _asInt(raw['step']);
      if (page == 0 && step == 0) return null;
      return ReadingPosition(page: page, step: step);
    } catch (e) {
      debugPrint('Erro ao ler progresso: $e');
      return null;
    }
  }

  static Future<void> save(int bookId, int page, int step) async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    if (page <= 0 && step <= 0) return;

    try {
      final userId = auth.currentUser!['id'].toString();
      await _api.updateReadingProgress(
        userId,
        bookId.toString(),
        page,
        step,
      );
    } catch (e) {
      debugPrint('Erro ao guardar progresso: $e');
    }
  }

  static Future<void> clear(int bookId) async {
    final auth = _auth;
    if (auth == null || !auth.isAuthenticated) return;
    try {
      final userId = auth.currentUser!['id'].toString();
      await _api.removeBookFromProgress(userId, bookId.toString());
    } catch (e) {
      debugPrint('Erro ao limpar progresso: $e');
    }
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}

/// Abre o leitor correcto com progresso restaurado.
Future<void> openBookForReading(
  Map<String, dynamic> book, {
  ReadingPosition? position,
}) async {
  final model = BookModel.fromJson(book);
  final saved = position ??
      await ReadingProgressHelper.getPosition(model.id) ??
      const ReadingPosition();
  final savedPage = saved.page;
  final savedStep = saved.step;

  const transition = Transition.fadeIn;
  const duration = Duration(milliseconds: 500);
  const curve = Curves.easeInOut;

  Future<void> go(Widget page) async {
    await Get.to(
      () => page,
      transition: transition,
      duration: duration,
      curve: curve,
    );
    // Actualiza a home só se ainda estiver visível (evita trabalho em background).
    if (Get.isRegistered<HomeController>() &&
        Get.currentRoute == '/home') {
      Get.find<HomeController>().refreshData();
    }
  }

  switch (model.kind) {
    case BookKind.animated:
      final loaded = await loadBookForReading(model);
      if (loaded == null) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar o livro.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      await go(AnimatedBookReaderPage(
        book: loaded,
        initialSlotIndex: savedPage,
      ));
      return;

    case BookKind.interactive:
      final loaded = await loadBookForReading(model);
      if (loaded == null) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar as cenas.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      await go(InteractiveBookReaderPage(
        book: loaded,
        initialSceneIndex: savedPage,
      ));
      return;

    case BookKind.digital:
      final loaded = await loadBookForReading(model);
      if (loaded == null) {
        Get.snackbar(
          'Erro',
          'Não foi possível carregar o livro digital.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
        return;
      }
      await go(DigitalBookReaderPage(
        book: loaded,
        initialPdfPage: savedPage > 0 ? savedPage : 1,
      ));
      return;

    case BookKind.legacy:
      break;
  }

  final slidebookUrl = model.slidebookLink;
  if (slidebookUrl != null &&
      slidebookUrl.isNotEmpty &&
      !model.hasNativePages) {
    await go(ReaderWebViewPage(slidebookUrl: slidebookUrl));
    return;
  }

  await go(ReaderPage(
    bookId: model.id.toString(),
    initialPage: savedPage,
    initialStep: savedStep,
  ));
}
