import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../controllers/interactive_book_reader_controller.dart';
import '../models/story_page.dart';
import '../utils/book_pages_loader.dart';
import '../utils/reading_progress_helper.dart';
import '../services/reading_xp_service.dart';
import '../services/book_offline_cache.dart';
import '../services/book_offline_session.dart';
import '../widgets/offline_book_image.dart';

/// Leitor interactivo estilo «Escolha sua aventura» (paridade com
/// `InteractiveStoryReader.jsx` do Play).
class InteractiveBookReaderPage extends StatefulWidget {
  final BookModel book;
  final int initialSceneIndex;
  final bool skipInitialLoad;

  const InteractiveBookReaderPage({
    super.key,
    required this.book,
    this.initialSceneIndex = 0,
    this.skipInitialLoad = false,
  });

  @override
  State<InteractiveBookReaderPage> createState() =>
      _InteractiveBookReaderPageState();
}

class _InteractiveBookReaderPageState extends State<InteractiveBookReaderPage> {
  static const _bg = Color(0xFF0E0E1E);

  InteractiveBookReaderController? _controller;
  late final AuthController _authController;
  late final LuditecaApiService _apiService;

  BookModel? _book;
  bool _loading = true;
  String? _loadError;
  bool _completionRegistered = false;
  bool _sceneRestored = false;
  int? _animatingChoice;
  Worker? _xpSceneWorker;
  bool _sceneAnimating = false;

  /// 1 = avançar, -1 = voltar, 0 = neutro.
  int _transitionDirection = 0;
  bool _completionCheckScheduled = false;

  static const double _contentMaxWidth = 720;
  static const Duration _sceneAnimDuration = Duration(milliseconds: 720);
  static const Duration _choiceAnimDuration = Duration(milliseconds: 420);

  bool _isCompactLayout(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.height < 700 || size.width < 400;
  }

  double _bodyFontSize(BuildContext context) =>
      _isCompactLayout(context) ? 15.0 : 17.0;

  bool get _choicesLocked => _animatingChoice != null || _sceneAnimating;

  @override
  void initState() {
    super.initState();
    _authController = Get.find<AuthController>();
    _apiService = LuditecaApiService();
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

  @override
  void dispose() {
    _xpSceneWorker?.dispose();
    unawaited(ReadingXpService.instance.endSession());
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    final id = _activeBook.id;
    if (Get.isRegistered<InteractiveBookReaderController>(
      tag: 'interactive-$id',
    )) {
      Get.delete<InteractiveBookReaderController>(tag: 'interactive-$id');
    }
    if (BookOfflineSession.activeBookId == widget.book.id) {
      BookOfflineSession.clear();
    }
    super.dispose();
  }

  BookModel get _activeBook => _book ?? widget.book;

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

      final story = extractStoryPages(loaded.pages);
      if (story.isEmpty) {
        setState(() {
          _loading = false;
          _loadError =
              'Este livro interativo ainda não tem cenas publicadas. '
              'Adicione páginas com escolhas no CMS e publique o livro.';
        });
        return;
      }

      final tag = 'interactive-${loaded.id}';
      if (Get.isRegistered<InteractiveBookReaderController>(tag: tag)) {
        Get.delete<InteractiveBookReaderController>(tag: tag);
      }

      _book = loaded;
      _controller = Get.put(
        InteractiveBookReaderController(
          bookId: loaded.id.toString(),
          story: story,
        ),
        tag: tag,
      );

      while (mounted && (_controller?.isLoading ?? true)) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      setState(() => _loading = false);
      _bindReadingXp(loaded.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Erro ao carregar: $e';
      });
    }
  }

  void _bindReadingXp(int bookId) {
    final controller = _controller;
    if (controller == null || !_authController.isAuthenticated) return;

    _xpSceneWorker?.dispose();
    ReadingXpService.instance.beginSession(bookId);

    void awardScene() {
      final idx = controller.currentSceneIndex;
      if (idx == null) return;
      unawaited(ReadingXpService.instance.onPageRead(bookId, idx));
    }

    _xpSceneWorker = ever(controller.runStateRx, (_) => awardScene());
    awardScene();
  }

  void _maybeRestoreScene(InteractiveBookReaderController controller) {
    if (_sceneRestored || controller.isLoading) return;
    _sceneRestored = true;
    final idx = widget.initialSceneIndex;
    if (idx <= 0 || idx >= controller.story.length) return;
    controller.jumpToPage(controller.story[idx].id);
  }

  void _refreshUi() {
    if (mounted) setState(() {});
  }

  int _currentSceneIndex(InteractiveBookReaderController controller) {
    final page = controller.currentPage;
    if (page == null) return 0;
    final idx = controller.story.indexWhere((p) => p.id == page.id);
    return idx < 0 ? 0 : idx;
  }

  Future<void> _persistProgress() async {
    final controller = _controller;
    if (controller == null || controller.isAtEnding) return;
    await ReadingProgressHelper.save(
      _activeBook.id,
      _currentSceneIndex(controller),
      0,
    );
  }

  Future<void> _registerCompletionIfNeeded() async {
    if (_completionRegistered) return;
    if (_controller?.isAtEnding != true) return;
    if (!_authController.isAuthenticated) return;
    _completionRegistered = true;
    try {
      final userId = _authController.currentUser!['id'].toString();
      await ReadingProgressHelper.clear(_activeBook.id);
      final gamification =
          await _apiService.incrementBooksRead(userId, bookId: _activeBook.id);
      if (Get.isRegistered<ProfileController>()) {
        Get.find<ProfileController>().applyGamificationResult(gamification);
      }
    } catch (e) {
      debugPrint('Erro ao registar conclusão (interactive): $e');
    }
  }

  Future<void> _handleBack() async {
    await _persistProgress();
    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  String _sceneSubtitle(StoryPage page, InteractiveBookReaderController c) {
    if (page.isStart) return '🚀 Início';
    if (page.isEnding) return '🏁 Final';
    final idx = c.story.indexWhere((p) => p.id == page.id);
    return 'Cena ${idx + 1} de ${c.story.length}';
  }

  String _sceneBadge(StoryPage page) {
    if (page.isStart) return '🚀 Início';
    if (page.isEnding) return '🏁 Final';
    final title = page.sceneTitle?.trim();
    if (title != null && title.isNotEmpty) return '✏️ $title';
    return 'Cena ${page.id}';
  }

  Future<void> _pickChoice(Choice choice, int index) async {
    final controller = _controller;
    if (controller == null || _animatingChoice != null) return;

    setState(() => _animatingChoice = index);
    await Future.delayed(_choiceAnimDuration);
    if (!mounted) return;

    _transitionDirection = 1;
    controller.pickChoice(choice);
    setState(() {
      _animatingChoice = null;
      _sceneAnimating = true;
    });
    unawaited(_persistProgress());
    await Future.delayed(_sceneAnimDuration);
    if (mounted) setState(() => _sceneAnimating = false);
  }

  void _goBackOneScene(InteractiveBookReaderController controller) {
    if ((controller.state?.history.length ?? 0) < 2 || _sceneAnimating) return;
    _transitionDirection = -1;
    _completionCheckScheduled = false;
    controller.goToPreviousPage();
    setState(() => _sceneAnimating = true);
    _refreshUi();
    unawaited(Future<void>.delayed(_sceneAnimDuration).then((_) {
      if (mounted) setState(() => _sceneAnimating = false);
    }));
  }

  void _jumpToScene(
    InteractiveBookReaderController controller,
    StoryPage target,
    int targetStoryIndex,
  ) {
    final current = controller.currentPage;
    final currentIdx = current == null
        ? 0
        : controller.story.indexWhere((p) => p.id == current.id);
    _transitionDirection = targetStoryIndex >= currentIdx ? 1 : -1;
    if (target.isEnding) {
      _completionCheckScheduled = false;
    }
    controller.jumpToPage(target.id);
    _refreshUi();
  }

  void _showStoryMap(InteractiveBookReaderController controller) {
    final visited = controller.state?.visitedPageIds ?? const [];
    final currentId = controller.state?.currentPageId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      '🗺️ Mapa da História',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.story.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final pg = controller.story[i];
                      final isCurrent = pg.id == currentId;
                      final isVisited = visited.contains(pg.id);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppLayoutTokens.primary.withAlpha(40)
                              : isVisited
                                  ? Colors.white.withAlpha(20)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? AppLayoutTokens.primary
                                : isVisited
                                    ? AppLayoutTokens.primary.withAlpha(80)
                                    : Colors.white.withAlpha(30),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              pg.isStart
                                  ? '🚀'
                                  : pg.isEnding
                                      ? '🏁'
                                      : isCurrent
                                          ? '📍'
                                          : isVisited
                                              ? '✅'
                                              : '🔒',
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                getPageLabel(pg, i),
                                style: TextStyle(
                                  color: isCurrent
                                      ? AppLayoutTokens.primary
                                      : Colors.white.withAlpha(
                                          isVisited ? 230 : 120,
                                        ),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSceneSelector(InteractiveBookReaderController controller) {
    final currentId = controller.state?.currentPageId;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      '🎬 Escolher Cena',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: controller.story.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final pg = controller.story[i];
                      final isCurrent = pg.id == currentId;
                      return Material(
                        color: isCurrent
                            ? AppLayoutTokens.primary
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            _jumpToScene(controller, pg, i);
                            Navigator.pop(ctx);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  pg.isStart
                                      ? '🚀'
                                      : pg.isEnding
                                          ? '🏁'
                                          : '▪️',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    getPageLabel(pg, i),
                                    style: TextStyle(
                                      color: Colors.white.withAlpha(
                                        isCurrent ? 255 : 220,
                                      ),
                                      fontWeight: FontWeight.w700,
                                    ),
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
          ),
        );
      },
    );
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
        backgroundColor: _bg,
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
                ? _buildErrorState(_loadError!)
                : _buildReader(),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amberAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadError != null ? _loadContent : _handleBack,
              child: Text(_loadError != null ? 'Tentar novamente' : 'Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReader() {
    final controller = _controller;
    if (controller == null) {
      return _buildErrorState('Aventura indisponível.');
    }

    if (controller.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    _maybeRestoreScene(controller);

    final page = controller.currentPage;
    if (page == null) {
      return _buildErrorState(
        'Não foi possível localizar a página actual. '
        'Toque em Recomeçar ou volte e abra o livro de novo.',
      );
    }

    if (page.isEnding && !_completionCheckScheduled) {
      _completionCheckScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _registerCompletionIfNeeded();
      });
    }

    final topInset = MediaQuery.paddingOf(context).top;

    return ColoredBox(
      color: _bg,
      child: Column(
        children: [
          _buildTopBar(controller, page, topInset),
          Expanded(
            child: _buildSceneBody(controller, page),
          ),
        ],
      ),
    );
  }

  Widget _pageTurnTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
      reverseCurve: Curves.easeInOutCubic,
    );
    final horizontal = _transitionDirection >= 0 ? 1.0 : -1.0;
    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(horizontal, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.72, end: 1).animate(
          CurvedAnimation(
            parent: animation,
            curve: const Interval(0.15, 1, curve: Curves.easeOut),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildSceneBody(
    InteractiveBookReaderController controller,
    StoryPage page,
  ) {
    final canSwipeBack = (controller.state?.history.length ?? 0) > 1 && !page.isEnding;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
        child: AnimatedSwitcher(
          duration: _sceneAnimDuration,
          switchInCurve: Curves.easeInOutCubic,
          switchOutCurve: Curves.easeInOutCubic,
          transitionBuilder: _pageTurnTransition,
          layoutBuilder: (current, previous) => Stack(
            fit: StackFit.expand,
            clipBehavior: Clip.hardEdge,
            children: [
              ...previous,
              if (current != null) current,
            ],
          ),
          child: KeyedSubtree(
            key: ValueKey('scene-${page.id}'),
            child: Column(
              children: [
                Expanded(
                  flex: 45,
                  child: GestureDetector(
                    onHorizontalDragEnd: canSwipeBack
                        ? (details) {
                            if ((details.primaryVelocity ?? 0) > 280) {
                              _goBackOneScene(controller);
                            }
                          }
                        : null,
                    child: _buildSceneImage(page),
                  ),
                ),
                Expanded(
                  flex: 55,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    child: _buildSceneScrollContent(controller, page),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSceneScrollContent(
    InteractiveBookReaderController controller,
    StoryPage page,
  ) {
    final choices = controller.availableChoices;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSceneTextBlock(page),
        if (page.isEnding)
          _buildEndingBlock(page, controller)
        else if (choices.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            '🤔 O que você quer fazer?',
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontSize: _isCompactLayout(context) ? 14 : 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...choices.asMap().entries.map((entry) {
            return _buildChoiceButton(entry.value, entry.key);
          }),
        ] else
          _buildNoChoices(controller),
      ],
    );
  }

  Widget _buildSceneTextBlock(StoryPage page) {
    final fontSize = _bodyFontSize(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: page.isStart
                  ? AppLayoutTokens.primary
                  : page.isEnding
                      ? const Color(0xFF48BB78)
                      : AppLayoutTokens.primary.withAlpha(180),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              _sceneBadge(page),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (page.text != null && page.text!.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isCompactLayout(context) ? 12 : 16,
              vertical: _isCompactLayout(context) ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(31),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withAlpha(40)),
            ),
            child: Text(
              page.text!,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopBar(
    InteractiveBookReaderController controller,
    StoryPage page,
    double topInset,
  ) {
    final canGoBack =
        (controller.state?.history.length ?? 0) > 1 && !page.isEnding;

    return Container(
      padding: EdgeInsets.fromLTRB(8, topInset + 8, 8, 10),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
      ),
      child: Row(
        children: [
          _topIconButton(Icons.arrow_back, _handleBack),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _activeBook.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _sceneSubtitle(page, controller),
                  style: TextStyle(
                    color: Colors.white.withAlpha(128),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _topIconButton(Icons.movie_outlined, () => _showSceneSelector(controller)),
          _topIconButton(Icons.map_outlined, () => _showStoryMap(controller)),
          if (canGoBack)
            _topIconButton(
              Icons.rotate_left,
              () => _goBackOneScene(controller),
            ),
        ],
      ),
    );
  }

  Widget _topIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withAlpha(26),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildSceneImage(StoryPage page) {
    if (page.imageUrl != null && page.imageUrl!.isNotEmpty) {
      return OfflineBookImage(
        key: ValueKey(page.imageUrl),
        url: page.imageUrl!,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder(key: ValueKey('ph-${page.id}'));
  }

  Widget _imagePlaceholder({Key? key}) {
    return Container(
      key: key,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppLayoutTokens.primary.withAlpha(51),
            _bg,
          ],
        ),
      ),
      child: const Text('📖', style: TextStyle(fontSize: 56)),
    );
  }

  Widget _buildChoiceButton(Choice choice, int index) {
    final isChosen = _animatingChoice == index;
    final letter = String.fromCharCode(65 + index);

    final compact = _isCompactLayout(context);
    final labelSize = compact ? 15.0 : 17.0;

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 8 : 10),
      child: Material(
        color: isChosen
            ? AppLayoutTokens.primary
            : Colors.white.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _choicesLocked ? null : () => _pickChoice(choice, index),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 11 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isChosen
                    ? AppLayoutTokens.primary
                    : Colors.white.withAlpha(77),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(isChosen ? 90 : 64),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    letter,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    choice.label.isEmpty ? 'Continuar' : choice.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: labelSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isChosen)
                  const Icon(Icons.check, color: Colors.white, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoChoices(InteractiveBookReaderController controller) {
    final canGoBack = (controller.state?.history.length ?? 0) > 1;
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(100),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Esta cena não tem escolhas configuradas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(179),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        if (canGoBack) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => _goBackOneScene(controller),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withAlpha(64)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('← Voltar e escolher outra opção'),
          ),
        ],
      ],
    );
  }

  Widget _buildEndingBlock(
    StoryPage page,
    InteractiveBookReaderController controller,
  ) {
    final canTryAnother = (controller.state?.history.length ?? 0) > 1;

    final compact = _isCompactLayout(context);
    final titleSize = compact ? 18.0 : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          '🎉',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: compact ? 36 : 48),
        ),
        const SizedBox(height: 6),
        Text(
          endingLabel(page.endingType),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: titleSize,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Você encontrou um dos finais possíveis.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withAlpha(153),
            fontSize: compact ? 13 : 15,
          ),
        ),
        SizedBox(height: compact ? 14 : 20),
        _buildEndingActionButton(
          label: 'Recomeçar do início',
          icon: Icons.replay_rounded,
          variant: _EndingActionVariant.primary,
          onTap: () async {
            _transitionDirection = 0;
            await controller.restart();
            _completionRegistered = false;
            _completionCheckScheduled = false;
            _refreshUi();
          },
        ),
        if (canTryAnother) ...[
          const SizedBox(height: 12),
          _buildEndingActionButton(
            label: 'Tentar outro caminho',
            icon: Icons.arrow_back_rounded,
            variant: _EndingActionVariant.secondary,
            onTap: () => _goBackOneScene(controller),
          ),
        ],
        const SizedBox(height: 12),
        _buildEndingActionButton(
          label: 'Sair do livro',
          icon: Icons.home_outlined,
          variant: _EndingActionVariant.tertiary,
          onTap: _handleBack,
        ),
      ],
    );
  }

  Widget _buildEndingActionButton({
    required String label,
    required IconData icon,
    required _EndingActionVariant variant,
    required VoidCallback onTap,
  }) {
    final isPrimary = variant == _EndingActionVariant.primary;
    final isSecondary = variant == _EndingActionVariant.secondary;

    final background = isPrimary
        ? AppLayoutTokens.primary
        : isSecondary
            ? Colors.white.withAlpha(31)
            : Colors.white.withAlpha(20);

    final borderColor = isPrimary
        ? AppLayoutTokens.primary
        : isSecondary
            ? Colors.white.withAlpha(64)
            : Colors.transparent;

    final textColor = isPrimary
        ? Colors.white
        : isSecondary
            ? Colors.white
            : Colors.white.withAlpha(179);

    return Material(
      color: background,
      elevation: 0,
      shadowColor: isPrimary ? AppLayoutTokens.primary.withAlpha(102) : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 2),
            boxShadow: isPrimary
                ? [
                    BoxShadow(
                      color: AppLayoutTokens.primary.withAlpha(102),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : isSecondary
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(51),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _isCompactLayout(context) ? 46 : 52,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: _isCompactLayout(context) ? 11 : 14,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: textColor, size: 20),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: _isCompactLayout(context) ? 15 : 17,
                        fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _EndingActionVariant { primary, secondary, tertiary }
