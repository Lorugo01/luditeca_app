import 'package:get/get.dart';
import '../models/book_element.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../services/reading_xp_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';

class ReaderController extends GetxController {
  final LuditecaApiService _apiService = LuditecaApiService();

  String? _loadedBookId;

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

      final response = await _apiService.getBookById(bookId);
      if (response != null && response['pages'] != null) {
        final pagesData = _normalizePages(response['pages']);
        if (pagesData.isEmpty) {
          _error.value = 'Livro sem páginas válidas para leitura';
          return;
        }
        _book.value = Book.fromJson(pagesData);

        // Usar valores iniciais se fornecidos
        _currentPageIndex.value =
            initialPage != null && initialPage < pagesData.length
                ? initialPage
                : 0;

        _currentStep.value = initialStep ?? 0;

        _loadedBookId = bookId;
        final id = int.tryParse(bookId);
        if (id != null) {
          ReadingXpService.instance.beginSession(id);
          await ReadingXpService.instance.onPageRead(id, _currentPageIndex.value);
        }
      } else {
        _error.value = 'Livro não encontrado ou formato inválido';
      }
    } catch (e) {
      _error.value = 'Erro ao carregar o livro: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  void _awardCurrentPageXp() {
    final id = int.tryParse(_loadedBookId ?? '');
    if (id == null) return;
    unawaited(
      ReadingXpService.instance.onPageRead(id, _currentPageIndex.value),
    );
  }

  List<Map<String, dynamic>> _normalizePages(dynamic rawPages) {
    final fromV2 = _normalizePagesFromV2(rawPages);
    if (fromV2.isNotEmpty) {
      return fromV2;
    }

    if (rawPages is List) {
      return rawPages
          .whereType<Map>()
          .map((page) => Map<String, dynamic>.from(page))
          .toList();
    }

    if (rawPages is String) {
      try {
        final decoded = jsonDecode(rawPages);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((page) => Map<String, dynamic>.from(page))
              .toList();
        }
      } catch (_) {
        return [];
      }
    }

    return [];
  }

  List<Map<String, dynamic>> _normalizePagesFromV2(dynamic rawPages) {
    Map<String, dynamic>? root;

    if (rawPages is Map<String, dynamic>) {
      root = rawPages;
    } else if (rawPages is String) {
      try {
        final decoded = jsonDecode(rawPages);
        if (decoded is Map<String, dynamic>) {
          root = decoded;
        }
      } catch (_) {
        return [];
      }
    }

    if (root == null || root['version'] != 2 || root['pages'] is! List) {
      return [];
    }

    final pages = (root['pages'] as List).whereType<Map>().map((p) {
      final page = Map<String, dynamic>.from(p);
      final meta = page['meta'] is Map
          ? Map<String, dynamic>.from(page['meta'] as Map)
          : <String, dynamic>{};
      final transition = meta['transition'] is Map
          ? Map<String, dynamic>.from(meta['transition'] as Map)
          : <String, dynamic>{'type': 'none', 'durationMs': 500};

      final background = _extractBackgroundFromV2(page['background']);
      final nodes = page['nodes'] is List
          ? (page['nodes'] as List).whereType<Map>().toList()
          : <Map>[];
      final elements = nodes
          .map((n) => _mapV2NodeToLegacyElement(Map<String, dynamic>.from(n)))
          .toList()
        ..sort(
          (a, b) => ((a['zIndex'] as int?) ?? 0).compareTo((b['zIndex'] as int?) ?? 0),
        );

      return <String, dynamic>{
        'id': '${page['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        'background': background,
        'elements': elements,
        'transition': transition,
      };
    }).toList();

    return pages;
  }

  String _extractBackgroundFromV2(dynamic rawBackground) {
    if (rawBackground is String) return rawBackground;
    if (rawBackground is Map) {
      final bg = Map<String, dynamic>.from(rawBackground);
      final url = bg['url']?.toString() ?? '';
      return url;
    }
    return '';
  }

  Map<String, dynamic> _mapV2NodeToLegacyElement(Map<String, dynamic> node) {
    final transform = node['transform'] is Map
        ? Map<String, dynamic>.from(node['transform'] as Map)
        : <String, dynamic>{};
    final props = node['props'] is Map
        ? Map<String, dynamic>.from(node['props'] as Map)
        : <String, dynamic>{};
    final shape = props['shapeProperties'] is Map
        ? Map<String, dynamic>.from(props['shapeProperties'] as Map)
        : <String, dynamic>{};

    // --- richSpans → contentSpans ---
    // O editor V2 guarda trechos com negrito/itálico como `richSpans`
    // (array de {start,end,bold,italic,underline} sobre `props.content`).
    // O app usa `contentSpans` (array de {text,...}). Convertemos aqui.
    final rawContent = (props['content'] as String?) ?? '';
    List<Map<String, dynamic>>? mappedSpans;
    if (props['richSpans'] is List) {
      mappedSpans = _convertRichSpans(
        rawContent,
        (props['richSpans'] as List)
            .whereType<Map>()
            .map((s) => Map<String, dynamic>.from(s))
            .toList(),
        baseFontFamily: props['fontFamily'] as String?,
        baseFontSize: (props['fontSize'] as num?)?.toDouble(),
        baseFontWeight: props['fontWeight'] as String?,
        baseFontStyle: props['fontStyle'] as String?,
        baseColor: props['color'] as String?,
      );
    } else if (props['contentSpans'] is List) {
      mappedSpans = (props['contentSpans'] as List)
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    }

    return <String, dynamic>{
      'id': '${node['id'] ?? DateTime.now().microsecondsSinceEpoch}',
      'type': '${node['type'] ?? 'shape'}',
      'content': rawContent,
      'position': <String, dynamic>{
        'x': (transform['x'] as num?)?.toDouble() ?? 0,
        'y': (transform['y'] as num?)?.toDouble() ?? 0,
      },
      'size': <String, dynamic>{
        'width': (transform['width'] as num?)?.toDouble() ?? 120,
        'height': (transform['height'] as num?)?.toDouble() ?? 80,
      },
      'rotation': (transform['rotation'] as num?)?.toDouble() ?? 0,
      'zIndex': (node['zIndex'] as num?)?.toInt() ?? 0,
      'step': (node['step'] as num?)?.toInt() ?? 0,
      'animation': node['animation'],
      'fontSize': (props['fontSize'] as num?)?.toDouble(),
      'fontFamily': props['fontFamily'],
      'fontWeight': props['fontWeight'],
      'fontStyle': props['fontStyle'],
      'textAlign': props['textAlign'],
      'color': props['color'],
      'textDecoration': props['textDecoration'],
      'lineHeight': (props['lineHeight'] as num?)?.toDouble(),
      'letterSpacing': (props['letterSpacing'] as num?)?.toDouble(),
      'opacity': (props['opacity'] as num?)?.toDouble(),
      'strokeColor': props['strokeColor'],
      'strokeWidth': (props['strokeWidth'] as num?)?.toDouble(),
      'shadowColor': props['shadowColor'],
      'shadowBlur': (props['shadowBlur'] as num?)?.toDouble(),
      'shadowOpacity': (props['shadowOpacity'] as num?)?.toDouble(),
      'shadowOffsetX': (props['shadowOffsetX'] as num?)?.toDouble(),
      'shadowOffsetY': (props['shadowOffsetY'] as num?)?.toDouble(),
      'textStyle': props['textStyle'],
      'imageStyle': props['imageStyle'],
      'mediaKind': props['mediaKind'],
      'audio': props['audio'],
      if (props['audioStorage'] is Map) 'audioStorage': props['audioStorage'],
      if (props['audioBadgeXPct'] != null) 'audioBadgeXPct': (props['audioBadgeXPct'] as num?)?.toDouble(),
      if (props['audioBadgeYPct'] != null) 'audioBadgeYPct': (props['audioBadgeYPct'] as num?)?.toDouble(),
      if (props['audioBadgePlacement'] != null) 'audioBadgePlacement': props['audioBadgePlacement'],
      if (props['audioBadgeCanvasX'] != null) 'audioBadgeCanvasX': (props['audioBadgeCanvasX'] as num?)?.toDouble(),
      if (props['audioBadgeCanvasY'] != null) 'audioBadgeCanvasY': (props['audioBadgeCanvasY'] as num?)?.toDouble(),
      'shapeProperties': <String, dynamic>{
        ...shape,
        'fill': shape['fill'] ?? '#fcfdff',
        'borderColor': shape['borderColor'] ?? '#0d0d0d',
        'borderWidth': (shape['borderWidth'] as num?)?.toDouble() ?? 2,
      },
      if (mappedSpans != null && mappedSpans.isNotEmpty)
        'contentSpans': mappedSpans,
    };
  }

  /// Converte `richSpans` do editor V2 (índices sobre a string original) para
  /// o formato `contentSpans` do app (lista de trechos com estilo completo).
  List<Map<String, dynamic>> _convertRichSpans(
    String text,
    List<Map<String, dynamic>> spans, {
    String? baseFontFamily,
    double? baseFontSize,
    String? baseFontWeight,
    String? baseFontStyle,
    String? baseColor,
  }) {
    if (text.isEmpty) return [];

    // Marca por caractere
    final bold = List<bool>.filled(text.length, baseFontWeight == 'bold');
    final italic = List<bool>.filled(text.length, baseFontStyle == 'italic');
    final underline = List<bool>.filled(text.length, false);

    for (final span in spans) {
      final start = (span['start'] as num?)?.toInt() ?? 0;
      final end = (span['end'] as num?)?.toInt() ?? 0;
      final clampedStart = start.clamp(0, text.length);
      final clampedEnd = end.clamp(0, text.length);
      for (var i = clampedStart; i < clampedEnd; i++) {
        if (span['bold'] == true) bold[i] = true;
        if (span['italic'] == true) italic[i] = true;
        if (span['underline'] == true) underline[i] = true;
      }
    }

    // Agrupa caracteres com mesmo estilo
    final result = <Map<String, dynamic>>[];
    var buffer = StringBuffer();
    var prevBold = bold[0];
    var prevItalic = italic[0];

    for (var i = 0; i < text.length; i++) {
      final ch = text[i];
      if (ch == '\n') {
        if (buffer.isNotEmpty) {
          result.add({
            'text': buffer.toString(),
            'fontWeight': prevBold ? 'bold' : 'normal',
            'fontStyle': prevItalic ? 'italic' : 'normal',
            if (baseColor != null) 'color': baseColor,
            if (baseFontFamily != null) 'fontFamily': baseFontFamily,
            if (baseFontSize != null) 'fontSize': baseFontSize,
          });
          buffer.clear();
        }
        result.add({'text': '\n'});
        if (i + 1 < text.length) {
          prevBold = bold[i + 1];
          prevItalic = italic[i + 1];
        }
        continue;
      }
      final sameBold = bold[i] == prevBold;
      final sameItalic = italic[i] == prevItalic;
      if (!sameBold || !sameItalic) {
        if (buffer.isNotEmpty) {
          result.add({
            'text': buffer.toString(),
            'fontWeight': prevBold ? 'bold' : 'normal',
            'fontStyle': prevItalic ? 'italic' : 'normal',
            if (baseColor != null) 'color': baseColor,
            if (baseFontFamily != null) 'fontFamily': baseFontFamily,
            if (baseFontSize != null) 'fontSize': baseFontSize,
          });
          buffer.clear();
        }
        prevBold = bold[i];
        prevItalic = italic[i];
      }
      buffer.write(ch);
    }
    if (buffer.isNotEmpty) {
      result.add({
        'text': buffer.toString(),
        'fontWeight': prevBold ? 'bold' : 'normal',
        'fontStyle': prevItalic ? 'italic' : 'normal',
        if (baseColor != null) 'color': baseColor,
        if (baseFontFamily != null) 'fontFamily': baseFontFamily,
        if (baseFontSize != null) 'fontSize': baseFontSize,
      });
    }
    return result;
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
      _awardCurrentPageXp();
    }
  }

  void previousPage() {
    if (_currentPageIndex.value > 0) {
      _currentPageIndex.value--;
      _currentStep.value = 0;
      _awardCurrentPageXp();
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
