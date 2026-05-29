import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

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

/// Leitor de livro animado (paridade com `InteractiveBookView.jsx` do Play).
class AnimatedBookReaderPage extends StatefulWidget {
  final BookModel book;
  final int initialSlotIndex;

  const AnimatedBookReaderPage({
    super.key,
    required this.book,
    this.initialSlotIndex = 0,
  });

  @override
  State<AnimatedBookReaderPage> createState() => _AnimatedBookReaderPageState();
}

class _AnimatedBookReaderPageState extends State<AnimatedBookReaderPage> {
  late final LuditecaApiService _apiService;
  late final AuthController _authController;
  PageController? _pageController;
  late final FlutterTts _tts;
  final AudioPlayer _soundtrackPlayer = AudioPlayer();

  BookModel? _book;
  List<AnimatedSlot> _slots = [];
  bool _loading = true;
  String? _loadError;

  int _currentIndex = 0;
  bool _soundtrackReady = false;
  bool _soundtrackPlaying = false;
  bool _completionRegistered = false;
  bool _immersiveMode = false;
  bool _isSpeaking = false;
  bool _imgLoaded = false;

  double _fontSize = 18;
  ReaderColorMode _colorMode = ReaderColorMode.normal;

  int? _selectedOption;
  bool _showQuizFeedback = false;
  bool _disposed = false;
  bool _ttsReady = false;

  bool get _ttsSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _apiService = LuditecaApiService();
    _authController = Get.find<AuthController>();
    _tts = FlutterTts();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadContent();
  }

  Future<void> _ensureTtsReady() async {
    if (_ttsReady || !_ttsSupported) return;
    try {
      await _tts.setLanguage('pt-BR');
      await _tts.setSpeechRate(0.45);
      await _tts.awaitSpeakCompletion(true);
      _tts.setCompletionHandler(() {
        if (!_disposed && mounted) setState(() => _isSpeaking = false);
      });
      _tts.setErrorHandler((msg) {
        debugPrint('TTS erro: $msg');
        if (!_disposed && mounted) {
          setState(() => _isSpeaking = false);
        }
      });
      _ttsReady = true;
    } catch (e) {
      debugPrint('TTS indisponível nesta plataforma: $e');
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final loaded = await loadBookForReading(widget.book);
      if (!mounted) return;

      if (loaded == null) {
        setState(() {
          _loading = false;
          _loadError = 'Não foi possível carregar o livro.';
        });
        return;
      }

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
      _pageController?.dispose();
      _pageController = PageController(initialPage: startIndex);

      if (!mounted) return;
      setState(() {
        _book = loaded;
        _slots = slots;
        _currentIndex = startIndex;
        _loading = false;
        _imgLoaded = false;
      });

      await _initSoundtrack(loaded);

      if (_authController.isAuthenticated) {
        ReadingXpService.instance.beginSession(loaded.id);
        await ReadingXpService.instance.onPageRead(loaded.id, startIndex);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Erro ao carregar: $e';
      });
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

  Future<void> _stopSpeaking() async {
    if (!_ttsReady) return;
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint('Erro ao parar TTS: $e');
    }
    if (!_disposed && mounted) setState(() => _isSpeaking = false);
  }

  Future<void> _toggleSpeak() async {
    if (!_ttsSupported) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Narração por voz não está disponível no Windows.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    if (_isSpeaking) {
      await _stopSpeaking();
      return;
    }
    if (_currentIndex < 0 || _currentIndex >= _slots.length) return;
    final slot = _slots[_currentIndex];
    String? text;
    if (slot.kind == AnimatedSlotKind.page) {
      text = slot.page?.text?.trim();
      if (text == null || text.isEmpty) {
        text = _activeBook.title;
      }
    } else {
      text = slot.quiz?.question;
    }
    if (text == null || text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Esta página não tem texto para narrar.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    try {
      await _ensureTtsReady();
      if (!_ttsReady) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Narração indisponível neste dispositivo.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      await _tts.stop();
      final ok = await _tts.speak(text);
      if (!mounted) return;
      if (ok == 1) {
        setState(() => _isSpeaking = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível iniciar a narração.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erro TTS: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro na narração: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
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
                  isSpeaking: _isSpeaking,
                  onFontSizeChanged: (v) {
                    setState(() => _fontSize = v);
                    setSheetState(() {});
                  },
                  onColorModeChanged: (m) {
                    setState(() => _colorMode = m);
                    setSheetState(() {});
                  },
                  onSpeakToggle: () {
                    Navigator.pop(sheetContext);
                    _toggleSpeak();
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
    await _stopSpeaking();
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
    if (_currentIndex == 0 || _pageController == null) return;
    _pageController!.previousPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _goNext() {
    if (_currentIndex >= _slots.length - 1) {
      _registerCompletionIfNeeded();
      return;
    }
    _pageController?.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    if (_disposed || !mounted) return;
    if (index < 0 || index >= _slots.length) return;

    unawaited(_stopSpeaking());
    setState(() {
      _currentIndex = index;
      _selectedOption = null;
      _showQuizFeedback = false;
      _imgLoaded = false;
    });
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
    if (_ttsReady) {
      _tts.stop();
    }
    _pageController?.dispose();
    _pageController = null;
    _soundtrackPlayer.dispose();
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
    if (_pageController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _slots.length,
      onPageChanged: _onPageChanged,
      itemBuilder: (context, index) {
        if (index < 0 || index >= _slots.length) {
          return const SizedBox.shrink();
        }
        final slot = _slots[index];
        if (slot.kind == AnimatedSlotKind.quiz) {
          if (slot.quiz == null) return const SizedBox.shrink();
          return _buildQuizView(slot.quiz!);
        }
        if (slot.page == null) return const SizedBox.shrink();
        return _buildPageView(slot.page!);
      },
    );
  }

  Widget _buildPageView(AnimatedPage page) {
    final hasImage = page.imageUrl != null && page.imageUrl!.isNotEmpty;
    final hasText = page.text != null && page.text!.trim().isNotEmpty;
    final imageOnly = hasImage && (!hasText || _immersiveMode);
    final theme = ReaderPageTheme.forMode(_colorMode);

    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: theme.pageBackdrop,
                child: hasImage
                    ? _applyColorFilter(
                        Image.network(
                          page.imageUrl!,
                          fit: imageOnly ? BoxFit.cover : BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) {
                              if (!_imgLoaded && !_disposed) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (!_disposed && mounted && !_imgLoaded) {
                                    setState(() => _imgLoaded = true);
                                  }
                                });
                              }
                              return child;
                            }
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white54,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white38,
                              size: 64,
                            ),
                          ),
                        ),
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
              ),
              if (!_immersiveMode) _buildTopOverlay(),
              if (!_immersiveMode)
                _buildSideNav(isLast: _currentIndex >= _slots.length - 1),
              if (_immersiveMode) _buildImmersiveControls(),
            ],
          ),
        ),
        if (hasText && !_immersiveMode) _buildTextPanel(page.text!, theme),
        if (!_immersiveMode) _buildPageDots(),
      ],
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

  Widget _buildTextPanel(String text, ReaderPageTheme theme) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.32,
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
          child: Text(
            text,
            style: TextStyle(
              fontSize: _fontSize,
              height: 1.65,
              color: theme.panelText,
              fontWeight: FontWeight.w500,
            ),
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: _handleBack,
                ),
                Expanded(
                  child: Text(
                    _activeBook.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
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
      ),
    );
  }
}
