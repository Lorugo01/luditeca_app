import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:page_flip/page_flip.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../models/animated_slot.dart';
import '../models/book_quiz.dart';
import '../utils/book_pages_loader.dart';
import '../utils/reading_progress_helper.dart';
import '../services/reading_xp_service.dart';
import '../widgets/animated_reader_accessibility.dart';
import '../widgets/offline_book_image.dart';
import '../services/book_offline_cache.dart';
import '../services/book_offline_session.dart';

/// Leitor de livro animado (paridade com `InteractiveBookView.jsx` do Play).
class AnimatedBookReaderPage extends StatefulWidget {
  final BookModel book;
  final int initialSlotIndex;
  /// Livro já carregado e imagens pré-baixadas em [BookReadingPreparePage].
  final bool skipInitialLoad;

  const AnimatedBookReaderPage({
    super.key,
    required this.book,
    this.initialSlotIndex = 0,
    this.skipInitialLoad = false,
  });

  @override
  State<AnimatedBookReaderPage> createState() => _AnimatedBookReaderPageState();
}

class _AnimatedBookReaderPageState extends State<AnimatedBookReaderPage> {
  late final LuditecaApiService _apiService;
  late final AuthController _authController;
  final PageFlipController _pageFlipController = PageFlipController();
  final AudioPlayer _soundtrackPlayer = AudioPlayer();
  final AudioPlayer _narrationPlayer = AudioPlayer();

  BookModel? _book;
  List<AnimatedSlot> _slots = [];
  bool _loading = true;
  String? _loadError;

  int _currentIndex = 0;
  bool _soundtrackReady = false;
  bool _soundtrackPlaying = false;
  bool _narrationReady = false;
  bool _narrationPlaying = false;
  int _narrationLoadGen = 0;
  bool _completionRegistered = false;
  bool _immersiveMode = false;

  double _fontSize = 18;
  ReaderColorMode _colorMode = ReaderColorMode.normal;

  int? _selectedOption;
  bool _showQuizFeedback = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _apiService = LuditecaApiService();
    _authController = Get.find<AuthController>();
    _narrationPlayer.playerStateStream.listen((state) {
      if (_disposed || !mounted) return;
      final playing = state.playing;
      if (playing != _narrationPlaying) {
        setState(() => _narrationPlaying = playing);
      }
      if (state.processingState == ProcessingState.completed) {
        setState(() => _narrationPlaying = false);
      }
    });

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _restoreOfflineSession();
    _loadContent();
  }

  Future<void> _restoreOfflineSession() async {
    if (BookOfflineSession.activeBookId == widget.book.id) return;
    final map = await BookOfflineCache.instance.loadUrlMap(widget.book.id);
    if (map != null && map.isNotEmpty) {
      BookOfflineSession.activate(widget.book.id, map);
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final BookModel? loaded;
      if (widget.skipInitialLoad && widget.book.pages.isNotEmpty) {
        loaded = widget.book;
      } else {
        loaded = await loadBookForReading(widget.book);
      }
      if (!mounted) return;

      if (loaded == null) {
        setState(() {
          _loading = false;
          _loadError = 'Não foi possível carregar o livro.';
        });
        return;
      }

      await _applyLoadedBook(loaded);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Erro ao carregar: $e';
      });
    }
  }

  Future<void> _applyLoadedBook(BookModel loaded) async {
    final fallbackQuiz = parseBookQuizList(loaded.quiz);
    final slots = buildAnimatedSlots(loaded.pages, fallbackQuiz);

    if (slots.isEmpty) {
      setState(() {
        _book = loaded;
        _slots = const [];
        _loading = false;
      });
      return;
    }

    final maxIndex = slots.length - 1;
    final startIndex = widget.initialSlotIndex.clamp(0, maxIndex);

    if (!mounted) return;
    setState(() {
      _book = loaded;
      _slots = slots;
      _currentIndex = startIndex;
      _loading = false;
    });

    await _initSoundtrack(loaded);
    unawaited(_prepareNarrationForIndex(startIndex));

    if (_authController.isAuthenticated) {
      ReadingXpService.instance.beginSession(loaded.id);
      await ReadingXpService.instance.onPageRead(loaded.id, startIndex);
    }
  }

  Future<void> _initSoundtrack(BookModel book) async {
    final url = book.soundtrackUrl;
    if (url == null || url.isEmpty) return;
    try {
      await _soundtrackPlayer.setUrl(url);
      await _soundtrackPlayer.setLoopMode(LoopMode.all);
      if (mounted) setState(() => _soundtrackReady = true);
    } catch (e) {
      debugPrint('Erro ao carregar trilha sonora: $e');
    }
  }

  BookModel get _activeBook => _book ?? widget.book;

  Future<void> _toggleSoundtrack() async {
    if (!_soundtrackReady) return;
    try {
      if (_soundtrackPlayer.playing) {
        await _soundtrackPlayer.pause();
        setState(() => _soundtrackPlaying = false);
      } else {
        await _soundtrackPlayer.play();
        setState(() => _soundtrackPlaying = true);
      }
    } catch (e) {
      debugPrint('Erro ao alternar trilha: $e');
    }
  }

  Future<void> _persistProgress() async {
    if (_disposed || _completionRegistered || _slots.isEmpty) return;
    await ReadingProgressHelper.save(_activeBook.id, _currentIndex, 0);
  }

  Future<void> _registerCompletionIfNeeded() async {
    if (_completionRegistered) return;
    if (_currentIndex < _slots.length - 1) return;
    if (!_authController.isAuthenticated) return;
    _completionRegistered = true;
    try {
      final userId = _authController.currentUser!['id'].toString();
      await ReadingProgressHelper.clear(_activeBook.id);
      final gamification = await _apiService.incrementBooksRead(
        userId,
        bookId: _activeBook.id,
      );
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().applyGamificationResult(gamification);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Parabéns! Você concluiu a leitura deste livro!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Erro ao registar conclusão: $e');
    }
  }

  String? _narrationUrlForIndex(int index) {
    if (index < 0 || index >= _slots.length) return null;
    final slot = _slots[index];
    if (slot.kind != AnimatedSlotKind.page) return null;
    return slot.page?.narrationUrl;
  }

  Future<void> _stopNarration() async {
    try {
      await _narrationPlayer.stop();
    } catch (_) {}
    if (!_disposed && mounted) {
      setState(() {
        _narrationPlaying = false;
        _narrationReady = false;
      });
    }
  }

  Future<void> _prepareNarrationForIndex(int index) async {
    final gen = ++_narrationLoadGen;
    await _stopNarration();

    final raw = _narrationUrlForIndex(index);
    if (raw == null || raw.isEmpty) return;

    final url = BookOfflineSession.resolve(raw);
    try {
      await _narrationPlayer.setUrl(url);
      if (_disposed || !mounted || gen != _narrationLoadGen) return;
      setState(() => _narrationReady = true);
    } catch (e) {
      debugPrint('Narração: falha ao carregar áudio — $e');
      if (_disposed || !mounted || gen != _narrationLoadGen) return;
      setState(() => _narrationReady = false);
    }
  }

  Future<void> _toggleNarration() async {
    if (!_narrationReady) return;
    try {
      if (_narrationPlayer.playing) {
        await _narrationPlayer.pause();
      } else {
        await _narrationPlayer.play();
      }
    } catch (e) {
      debugPrint('Narração: erro ao reproduzir — $e');
    }
  }

  void _openSettingsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: AnimatedReaderAccessibilityPanel(
                  fontSize: _fontSize,
                  colorMode: _colorMode,
                  onFontSizeChanged: (v) {
                    setState(() => _fontSize = v);
                    setSheetState(() {});
                  },
                  onColorModeChanged: (m) {
                    setState(() => _colorMode = m);
                    setSheetState(() {});
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleBack() async {
    await _stopNarration();
    try {
      await _soundtrackPlayer.stop();
    } catch (_) {}
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await _persistProgress();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    _pageFlipController.previousPage();
  }

  void _goNext() {
    if (_currentIndex >= _slots.length - 1) {
      _registerCompletionIfNeeded();
      return;
    }
    _pageFlipController.nextPage();
  }

  void _onPageChanged(int index) {
    if (_disposed || !mounted) return;
    if (index < 0 || index >= _slots.length) return;

    setState(() {
      _currentIndex = index;
      _selectedOption = null;
      _showQuizFeedback = false;
      _narrationReady = false;
      _narrationPlaying = false;
    });
    unawaited(_prepareNarrationForIndex(index));
    if (index == _slots.length - 1) {
      _registerCompletionIfNeeded();
    }
    unawaited(_persistProgress());
    if (_authController.isAuthenticated) {
      unawaited(ReadingXpService.instance.onPageRead(_activeBook.id, index));
    }
  }

  Future<void> _handleQuizAnswer(int option, BookQuizQuestion quiz) async {
    if (_showQuizFeedback) return;
    setState(() {
      _selectedOption = option;
      _showQuizFeedback = true;
    });
  }

  Widget _applyColorFilter(Widget child) {
    if (_colorMode == ReaderColorMode.normal) return child;
    return ColorFiltered(
      colorFilter: colorFilterForMode(_colorMode),
      child: child,
    );
  }

  @override
  void dispose() {
    unawaited(ReadingXpService.instance.endSession());
    _disposed = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _soundtrackPlayer.dispose();
    _narrationPlayer.dispose();
    if (BookOfflineSession.activeBookId == widget.book.id) {
      BookOfflineSession.clear();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _loadError != null
                ? _buildErrorState()
                : _slots.isEmpty
                    ? _buildEmptyState()
                    : _buildReader(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loadContent,
              child: const Text('Tentar novamente'),
            ),
            TextButton(
              onPressed: _handleBack,
              child: const Text('Voltar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            const Text(
              'Este livro animado ainda não tem páginas publicadas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _handleBack,
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader() {
    if (_slots.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    final children = <Widget>[];
    for (var i = 0; i < _slots.length; i++) {
      final slot = _slots[i];
      if (slot.kind == AnimatedSlotKind.quiz) {
        children.add(
          slot.quiz != null
              ? _buildQuizView(slot.quiz!)
              : const SizedBox.shrink(),
        );
      } else if (slot.page != null) {
        children.add(_buildPageView(slot.page!, isActivePage: i == _currentIndex));
      } else {
        children.add(const SizedBox.shrink());
      }
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        PageFlipWidget(
          key: ValueKey('book-${_activeBook.id}-${_slots.length}'),
          controller: _pageFlipController,
          initialIndex: _currentIndex.clamp(0, _slots.length - 1),
          backgroundColor: Colors.black,
          duration: const Duration(milliseconds: 680),
          cutoffForward: 0.72,
          cutoffPrevious: 0.18,
          onFlipStart: () => unawaited(_stopNarration()),
          onPageFlipped: _onPageChanged,
          children: children,
        ),
        // Chrome fora do PageFlip: o pacote não reconstrói as páginas ao mudar índice.
        if (!_immersiveMode) ...[
          _buildTopOverlay(),
          _buildSideNav(isLast: _currentIndex >= _slots.length - 1),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: _buildPageDots(),
            ),
          ),
        ] else
          _buildImmersiveControls(),
      ],
    );
  }

  bool get _isPortrait =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  /// Em retrato evita [BoxFit.cover] (corta texto/arte horizontal).
  /// Em paisagem mantém capa fullscreen nas páginas só com imagem.
  BoxFit _pageImageFit({required bool imageOnly}) {
    if (_isPortrait) return BoxFit.contain;
    if (_immersiveMode) return BoxFit.cover;
    if (imageOnly) return BoxFit.cover;
    return BoxFit.contain;
  }

  Widget _buildPageView(AnimatedPage page, {required bool isActivePage}) {
    final hasImage = page.imageUrl != null && page.imageUrl!.isNotEmpty;
    final hasText = page.text != null && page.text!.trim().isNotEmpty;
    final hasNarration =
        page.narrationUrl != null && page.narrationUrl!.trim().isNotEmpty;
    final showTextPanel =
        !_immersiveMode && (hasText || (hasNarration && isActivePage));
    final imageOnly = hasImage && (!hasText || _immersiveMode);
    final theme = ReaderPageTheme.forMode(_colorMode);
    final fit = _pageImageFit(imageOnly: imageOnly);
    final imageStack = _buildPageImageStack(
      page: page,
      theme: theme,
      fit: fit,
      hasImage: hasImage,
    );

    // Retrato + imagem + texto: mais espaço útil para a ilustração.
    if (_isPortrait && showTextPanel && hasImage) {
      return Column(
        children: [
          Expanded(flex: 62, child: imageStack),
          Flexible(
            flex: 38,
            fit: FlexFit.loose,
            child: _buildTextPanel(
              text: page.text ?? '',
              theme: theme,
              portrait: true,
              showNarrationPlay: isActivePage && hasNarration,
              narrationEnabled: isActivePage && _narrationReady,
              narrationPlaying: isActivePage && _narrationPlaying,
            ),
          ),
          // Espaço para os indicadores globais (fora do PageFlip).
          const SizedBox(height: 28),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: imageStack),
        if (showTextPanel)
          _buildTextPanel(
            text: page.text ?? '',
            theme: theme,
            showNarrationPlay: isActivePage && hasNarration,
            narrationEnabled: isActivePage && _narrationReady,
            narrationPlaying: isActivePage && _narrationPlaying,
          ),
        if (!_immersiveMode) const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildPageImageStack({
    required AnimatedPage page,
    required ReaderPageTheme theme,
    required BoxFit fit,
    required bool hasImage,
  }) {
    return ColoredBox(
      color: theme.pageBackdrop,
      child: hasImage
          ? LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: _applyColorFilter(
                    OfflineBookImage(
                      url: page.imageUrl!,
                      fit: fit,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      alignment: Alignment.center,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white38,
                        size: 64,
                      ),
                    ),
                  ),
                );
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  page.text ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.panelText,
                    fontSize: _fontSize,
                    height: 1.6,
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildTopOverlay() {
    final top = MediaQuery.paddingOf(context).top;
    final progress = (_currentIndex + 1) / _slots.length;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(8, top + 8, 8, 12),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x9E000000), Colors.transparent],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _overlayIconButton(
                  icon: Icons.menu,
                  onPressed: _handleBack,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        _activeBook.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${_slots.length}',
                        style: TextStyle(
                          color: Colors.white.withAlpha(179),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_soundtrackReady)
                  _overlayIconButton(
                    icon: _soundtrackPlaying ? Icons.music_off : Icons.music_note,
                    onPressed: _toggleSoundtrack,
                  ),
                _overlayIconButton(
                  icon: Icons.settings,
                  color: const Color(0xFF9F7AEA),
                  onPressed: _openSettingsSheet,
                ),
                _overlayIconButton(
                  icon: Icons.fullscreen,
                  onPressed: () => setState(() => _immersiveMode = true),
                ),
                _overlayIconButton(
                  icon: Icons.close,
                  onPressed: _handleBack,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: Colors.white.withAlpha(56),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppLayoutTokens.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImmersiveControls() {
    final top = MediaQuery.paddingOf(context).top;
    return Positioned(
      top: top + 8,
      right: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _overlayIconButton(
            icon: Icons.settings,
            color: const Color(0xFF9F7AEA),
            onPressed: _openSettingsSheet,
          ),
          const SizedBox(width: 8),
          _overlayIconButton(
            icon: Icons.fullscreen_exit,
            onPressed: () => setState(() => _immersiveMode = false),
          ),
        ],
      ),
    );
  }

  Widget _overlayIconButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Material(
      color: color ?? Colors.white.withAlpha(46),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSideNav({required bool isLast}) {
    return Stack(
      children: [
        if (_currentIndex > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Align(
              alignment: Alignment.center,
              child: _navArrow(Icons.chevron_left, _goPrevious),
            ),
          ),
        Positioned(
          right: 8,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.center,
            child: _navArrow(
              isLast ? Icons.star : Icons.chevron_right,
              isLast ? () => _registerCompletionIfNeeded() : _goNext,
              highlight: isLast,
            ),
          ),
        ),
      ],
    );
  }

  Widget _navArrow(IconData icon, VoidCallback onTap, {bool highlight = false}) {
    return Material(
      color: highlight
          ? AppLayoutTokens.primary
          : Colors.white.withAlpha(56),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildTextPanel({
    required String text,
    required ReaderPageTheme theme,
    bool portrait = false,
    bool showNarrationPlay = false,
    bool narrationEnabled = false,
    bool narrationPlaying = false,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * (portrait ? 0.4 : 0.32),
      ),
      width: double.infinity,
      color: theme.pageBackdrop,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.panelBackground,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withAlpha(51)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: text.trim().isEmpty
                    ? Text(
                        'Toque em ▶ para ouvir a narração desta página.',
                        style: TextStyle(
                          fontSize: _fontSize * 0.9,
                          height: 1.5,
                          color: theme.panelText.withAlpha(160),
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    : Text(
                        text,
                        style: TextStyle(
                          fontSize: _fontSize,
                          height: 1.65,
                          color: theme.panelText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
              if (showNarrationPlay) ...[
                const SizedBox(width: 12),
                _buildNarrationPlayButton(
                  enabled: narrationEnabled,
                  playing: narrationPlaying,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Botão play/pause ao lado do texto — só activo quando o áudio da página carregou.
  Widget _buildNarrationPlayButton({
    required bool enabled,
    required bool playing,
  }) {
    final active = enabled && playing;
    return Material(
      color: enabled
          ? AppLayoutTokens.primary
          : AppLayoutTokens.primary.withAlpha(80),
      shape: const CircleBorder(),
      elevation: enabled ? 4 : 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? _toggleNarration : null,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            active ? Icons.pause : Icons.play_arrow,
            color: Colors.white.withAlpha(enabled ? 255 : 140),
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildPageDots() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_slots.length, (i) {
          final active = i == _currentIndex;
          return Container(
            width: active ? 18 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.white.withAlpha(102),
              borderRadius: BorderRadius.circular(99),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuizView(BookQuizQuestion quiz) {
    final top = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 56, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
              'QUIZ',
              style: TextStyle(
                color: Colors.amberAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              quiz.question,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: quiz.options.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final isSelected = _selectedOption == index;
                  final isCorrect = quiz.correctIndex == index;
                  Color background = Colors.white.withAlpha(26);
                  Color border = Colors.white.withAlpha(61);
                  if (_showQuizFeedback && isSelected) {
                    background = isCorrect
                        ? Colors.green.withAlpha(64)
                        : Colors.red.withAlpha(64);
                    border = isCorrect ? Colors.green : Colors.red;
                  }
                  return InkWell(
                    onTap: _showQuizFeedback
                        ? null
                        : () => _handleQuizAnswer(index, quiz),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: background,
                        border: Border.all(color: border),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        quiz.options[index],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_showQuizFeedback)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _selectedOption == quiz.correctIndex
                      ? 'Resposta correta!'
                      : 'Resposta incorreta.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedOption == quiz.correctIndex
                        ? Colors.greenAccent
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _currentIndex > 0 ? _goPrevious : null,
                  child: const Text('Anterior', style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: _goNext,
                  child: const Text('Seguinte', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
