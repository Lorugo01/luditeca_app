import 'package:get/get.dart';
import '../models/book_element.dart';
import '../../../core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';

class ReaderController extends GetxController {
  final SupabaseService _supabaseService = SupabaseService();

  final _isLoading = true.obs;
  final _error = Rx<String?>(null);
  final _currentPageIndex = 0.obs;
  final _currentStep = 0.obs;
  final _book = Rx<Book?>(null);

  bool get isLoading => _isLoading.value;
  String? get error => _error.value;
  int get currentPageIndex => _currentPageIndex.value;
  int get currentStep => _currentStep.value;
  List<BookPage> get pages => _book.value?.pages ?? [];
  BookPage? get currentPage =>
      _currentPageIndex.value < pages.length
          ? pages[_currentPageIndex.value]
          : null;

  Future<void> loadBook(
    String bookId, {
    int? initialPage,
    int? initialStep,
  }) async {
    try {
      _isLoading.value = true;
      _error.value = null;

      final response = await _supabaseService.getBookById(bookId);
      if (response != null && response['pages'] != null) {
        final pagesData = List<Map<String, dynamic>>.from(response['pages']);
        _book.value = Book.fromJson(pagesData);

        // Usar valores iniciais se fornecidos
        _currentPageIndex.value =
            initialPage != null && initialPage < pagesData.length
                ? initialPage
                : 0;

        _currentStep.value = initialStep ?? 0;
      } else {
        _error.value = 'Livro não encontrado ou formato inválido';
      }
    } catch (e) {
      _error.value = 'Erro ao carregar o livro: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  void nextStep() {
    if (currentPage != null) {
      final maxStep = currentPage!.elements.fold<int>(
        0,
        (max, element) => element.step > max ? element.step : max,
      );

      if (_currentStep.value < maxStep) {
        _currentStep.value++;
      } else {
        nextPage();
      }
    }
  }

  void previousStep() {
    if (_currentStep.value > 0) {
      _currentStep.value--;
    } else {
      previousPage();
    }
  }

  void nextPage() {
    if (_currentPageIndex.value < (pages.length - 1)) {
      _currentPageIndex.value++;
      _currentStep.value = 0;
    }
  }

  void previousPage() {
    if (_currentPageIndex.value > 0) {
      _currentPageIndex.value--;
      _currentStep.value = 0;
    }
  }

  List<BookElement> getVisibleElements() {
    if (currentPage == null) return [];

    // Debug log
    debugPrint('Elementos na página: ${currentPage!.elements.length}');
    debugPrint('Step atual: $_currentStep');

    final visibleElements =
        currentPage!.elements
            .where((element) => element.step <= _currentStep.value)
            .toList()
          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // Debug log dos elementos visíveis
    for (var element in visibleElements) {
      debugPrint(
        'Elemento visível: ${element.type}, Step: ${element.step}, Audio: ${element.audio}',
      );
    }

    return visibleElements;
  }

  @override
  void onClose() {
    _book.value = null;
    super.onClose();
  }
}
