import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/story_page.dart';

/// Máquina de estado do leitor interactivo (aventura ramificada).
///
/// Espelha `interactiveAdventure.js` do projecto Next.js — mesma chave de
/// armazenamento (`luditeca-adventure-<bookId>`) e schema JSON, para que o
/// estado seja interoperável com a versão web.
class InteractiveBookReaderController extends GetxController {
  InteractiveBookReaderController({
    required this.bookId,
    required this.story,
  });

  final String bookId;
  final List<StoryPage> story;

  late final Map<int, StoryPage> _index = buildPageIndex(story);
  final Rx<RunState?> _state = Rx<RunState?>(null);
  final RxBool _isLoading = true.obs;
  final RxString _toast = ''.obs;

  RunState? get state => _state.value;
  Rx<RunState?> get runStateRx => _state;
  bool get isLoading => _isLoading.value;

  int? get currentSceneIndex {
    final page = currentPage;
    if (page == null) return null;
    final idx = story.indexWhere((p) => p.id == page.id);
    return idx < 0 ? null : idx;
  }
  String get toast => _toast.value;
  Map<int, StoryPage> get pageIndex => _index;

  StoryPage? get currentPage {
    final id = state?.currentPageId;
    if (id == null) return null;
    return _index[id];
  }

  List<Choice> get availableChoices {
    final page = currentPage;
    final s = state;
    if (page == null || s == null) return const [];
    return getAvailableChoices(page, s, _index);
  }

  bool get isAtEnding => currentPage?.isEnding == true;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    _isLoading.value = true;
    try {
      final loaded = await _loadFromDisk();
      if (loaded != null) {
        _state.value = loaded;
      } else {
        _state.value = createInitialRunState(bookId, story);
        await _persist(_state.value!);
      }
    } catch (e) {
      debugPrint('Erro ao iniciar aventura: $e');
      _state.value = createInitialRunState(bookId, story);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<RunState?> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(adventureStorageKey(bookId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final saved = RunState.fromJson(Map<String, dynamic>.from(decoded));
      if (saved.currentPageId == null ||
          !_index.containsKey(saved.currentPageId)) {
        return null;
      }
      return saved;
    } catch (e) {
      debugPrint('Erro a ler run state: $e');
      return null;
    }
  }

  Future<void> _persist(RunState newState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        adventureStorageKey(bookId),
        jsonEncode(newState.toJson()),
      );
    } catch (e) {
      debugPrint('Erro a guardar run state: $e');
    }
  }

  void pickChoice(Choice choice) {
    final target = choice.targetPageId;
    final s = state;
    if (target == null || s == null) return;
    var next = s;
    if (choice.effects != null) {
      next = applyEffects(next, choice.effects);
    }
    next = navigateToPage(next, target, story);
    _state.value = next;
    _persist(next);
  }

  void goToPreviousPage() {
    final s = state;
    if (s == null || s.history.length < 2) return;
    final next = goBack(s);
    _state.value = next;
    _persist(next);
  }

  Future<void> restart() async {
    final next = createInitialRunState(bookId, story);
    _state.value = next;
    await _persist(next);
    _toast.value = 'Aventura recomeçada.';
  }

  Future<void> saveNow() async {
    final s = state;
    if (s == null) return;
    await _persist(s);
    _toast.value = 'Progresso guardado.';
  }

  Future<void> reload() async {
    final loaded = await _loadFromDisk();
    if (loaded != null) {
      _state.value = loaded;
      _toast.value = 'Estado anterior carregado.';
    } else {
      _toast.value = 'Não há estado guardado para este livro.';
    }
  }

  void jumpToPage(int targetPageId) {
    final s = state;
    if (s == null || !_index.containsKey(targetPageId)) return;
    final next = navigateToPage(s, targetPageId, story);
    _state.value = next;
    _persist(next);
  }

  void consumeToast() => _toast.value = '';
}
