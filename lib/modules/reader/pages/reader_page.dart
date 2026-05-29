import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import '../controllers/reader_controller.dart';
import '../models/book_element.dart';
import 'package:animate_do/animate_do.dart';
import '../widgets/image_element_widget.dart';
import '../widgets/shape_element_widget.dart';
import '../widgets/reader_rich_text.dart';
import '../widgets/reader_page_transition.dart';
import '../widgets/audio_button_widget.dart';
import '../widgets/audio_badge_layout.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../profile/controllers/profile_controller.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../services/reading_xp_service.dart';

// Dimensões do canvas (ex: 1280x720 para 16:9)
const double canvasWidth = 1280;
const double canvasHeight = 720;

class ReaderPage extends StatefulWidget {
  final String bookId;
  final int? initialPage;
  final int? initialStep;
  final ReaderController controller = Get.put(ReaderController());

  ReaderPage({
    super.key,
    required this.bookId,
    this.initialPage,
    this.initialStep,
  }) {
    controller.loadBook(
      bookId,
      initialPage: initialPage,
      initialStep: initialStep,
    );
  }

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  late double scale;
  late double offsetX;
  late double offsetY;
  final Map<String, AudioPlayer> _audioPlayers = {};
  final LuditecaApiService _apiService = LuditecaApiService();
  final AuthController _authController = Get.find<AuthController>();

  bool _autoPlay = false;
  bool _hasShownCompletionMessage = false;

  @override
  void initState() {
    super.initState();

    // Forçar orientação horizontal
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Ativar modo imersivo (full screen + esconder notificações)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Bloquear captura de tela
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Adicionar livro em progresso ao iniciar leitura
    _addBookToProgressIfNeeded();
  }

  Future<void> _cleanupAudioPlayers() async {
    // Parar todos os players
    for (var player in _audioPlayers.values) {
      try {
        await player.stop();
        await player.dispose();
      } catch (e) {
        debugPrint('Erro ao limpar player de áudio: $e');
      }
    }
    _audioPlayers.clear();
  }

  @override
  void dispose() {
    unawaited(ReadingXpService.instance.endSession());
    // Limpar players de áudio
    _cleanupAudioPlayers();

    // Restaurar orientação e barras visíveis ao sair
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _toggleAutoPlay() {
    setState(() {
      _autoPlay = !_autoPlay;
    });
    if (_autoPlay) {
      _autoAdvanceSteps();
    } else {
      _cleanupAudioPlayers();
    }
  }

  Future<void> _autoAdvanceSteps() async {
    while (_autoPlay) {
      try {
        final currentStep = widget.controller.currentStep;
        final currentPage = widget.controller.currentPage;
        if (currentPage == null) break;

        final maxStep = currentPage.elements.fold<int>(
          0,
          (max, element) => element.step > max ? element.step : max,
        );

        // Pega os elementos do step atual
        final elementsThisStep =
            currentPage.elements.where((e) => e.step == currentStep).toList();

        // Se houver elemento com áudio, tocar e aguardar terminar
        bool playedAudio = false;
        for (final element in elementsThisStep) {
          if (element.audio != null && element.audio!.isNotEmpty) {
            playedAudio = true;
            try {
              // Inicializa player se necessário
              if (!_audioPlayers.containsKey(element.id)) {
                final player = AudioPlayer();
                _audioPlayers[element.id] = player;
                await player.setUrl(element.audio!);
              }
              final player = _audioPlayers[element.id]!;
              await player.stop();
              await player.seek(Duration.zero);
              await player.play();
              await player.processingStateStream.firstWhere(
                (state) => state == ProcessingState.completed,
              );
            } catch (e) {
              debugPrint('Erro ao reproduzir áudio: $e');
            }
          }
        }

        // Se não tocou áudio, espera 1s
        if (!playedAudio) {
          await Future.delayed(const Duration(seconds: 1));
        }

        if (!_autoPlay) break;

        if (currentStep < maxStep) {
          widget.controller.nextStep();
          await _checkAndShowCompletionMessage();
        } else {
          // Se for a última página, para o autoplay
          if (widget.controller.currentPageIndex >=
              widget.controller.pages.length - 1) {
            setState(() => _autoPlay = false);
            await _cleanupAudioPlayers();
            break;
          } else {
            widget.controller.nextPage();
          }
        }

        // Verificar se chegou ao final do livro após avançar
        await _checkAndShowCompletionMessage();
      } catch (e) {
        debugPrint('Erro no autoplay: $e');
        setState(() => _autoPlay = false);
        await _cleanupAudioPlayers();
        break;
      }
    }
  }

  Widget _buildAnimatedElement(BookElement element, Widget child) {
    // Se o elemento já foi mostrado em uma etapa anterior, não aplica a animação
    if (element.step < widget.controller.currentStep) {
      return child;
    }

    final anim = _normalizeAnimationName(element.animation);
    switch (anim) {
      case 'fadein':
        return FadeIn(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'fadeinup':
        return FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'fadeindown':
        return FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'fadeinleft':
        return FadeInLeft(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'fadeinright':
        return FadeInRight(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'zoomin':
        return ZoomIn(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'bounce':
        return ElasticIn(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'pulse':
        return Pulse(duration: const Duration(milliseconds: 500), child: child);
      case 'rubberband':
        return RubberBand(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'slideinleft':
        return SlideInLeft(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'slideinright':
        return SlideInRight(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      case 'flash':
        return Flash(
          duration: const Duration(milliseconds: 500),
          child: child,
        );
      default:
        return child;
    }
  }

  String _normalizeAnimationName(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    var v = raw.trim().toLowerCase();
    if (v.startsWith('animate__')) {
      v = v.substring('animate__'.length);
    }
    return v.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  Widget _buildElement(BookElement element) {
    // Debug log
    debugPrint('Elemento: ${element.type}, Audio: ${element.audio}');

    Widget elementWidget;

    switch (element.type) {
      case 'image':
        elementWidget = ImageElementWidget(
          element: element,
          audioPlayers: _audioPlayers,
        );
        break;

      case 'shape':
        elementWidget = ShapeElementWidget(
          element: element,
          audioPlayers: _audioPlayers,
        );
        break;

      case 'text':
        // textStyle não-nulo e diferente de 'normal' ativa o balão branco.
        // Para elementos V2 sem textStyle definido, o fundo deve ser transparente.
        final hasBubble =
            element.textStyle != null && element.textStyle != 'normal';
        // Largura da caixa do nó (igual ao editor).
        final textBoxW = element.size.width * scale;
        elementWidget = ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: textBoxW,
            maxWidth: textBoxW,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasBubble ? Colors.white : Colors.transparent,
                    borderRadius:
                        element.textStyle == 'thought'
                            ? BorderRadius.circular(element.size.width / 2)
                            : BorderRadius.circular(8),
                    border:
                        hasBubble
                            ? Border.all(color: Colors.grey.shade300)
                            : null,
                    boxShadow:
                        hasBubble
                            ? [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : null,
                  ),
                  child: LayoutBuilder(
                    builder: (context, cons) {
                      final audio = element.audio?.trim();
                      final badgeOff = AudioBadgeLayout.outsideTopLeftFromElement(
                        element,
                        cons.maxWidth,
                        cons.maxHeight,
                      );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(4),
                            child: buildReaderAutoSizeText(
                              element,
                              maxLines: null,
                              minFontSize: 8,
                              overflow: TextOverflow.visible,
                            ),
                          ),

                          // Indicador de fala (seta)
                          if (element.textStyle == 'speech')
                            Positioned(
                              left: -8,
                              bottom: -8,
                              child: Transform.rotate(
                                angle: -0.785398, // -45 graus em radianos
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                      right: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Indicador de pensamento (bolhas)
                          if (element.textStyle == 'thought')
                            Positioned(
                              left: -12,
                              bottom: -12,
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (audio != null && audio.isNotEmpty)
                            Positioned(
                              left: badgeOff.dx,
                              top: badgeOff.dy,
                              child: Opacity(
                                opacity:
                                    (element.opacity ?? 1).clamp(0.0, 1.0),
                                child: AudioButtonWidget(
                                  audioUrl: audio,
                                  audioPlayers: _audioPlayers,
                                  elementId: element.id,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
        break;

      default:
        elementWidget = const SizedBox.shrink();
    }

    // Aplica rotação ao elemento quando definida
    final rotation = element.rotation;
    if (rotation != null && rotation != 0) {
      elementWidget = Transform.rotate(
        angle: rotation * (3.14159265358979 / 180.0),
        child: elementWidget,
      );
    }

    return _buildAnimatedElement(element, elementWidget);
  }

  /// Canvas da página (fundo + elementos) em coordenadas relativas ao retângulo 1280×720 escalado.
  Widget _buildPageCanvasStack(
    BookPage page,
    List<BookElement> visibleElements,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child:
              page.background.isEmpty
                  ? ColoredBox(color: Colors.grey.shade300)
                  : Image.network(
                    page.background,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return ColoredBox(color: Colors.grey.shade300);
                    },
                  ),
        ),
        ...visibleElements.map((element) {
          return Positioned(
            left: element.position.x * scale,
            top: element.position.y * scale,
            width: element.size.width * scale,
            height: element.size.height * scale,
            child: _buildElement(element),
          );
        }),
      ],
    );
  }

  Future<void> _checkAndShowCompletionMessage() async {
    if (_hasShownCompletionMessage) return;

    final currentPageIndex = widget.controller.currentPageIndex;
    final currentStep = widget.controller.currentStep;
    final totalPages = widget.controller.pages.length;
    final currentPage = widget.controller.currentPage;

    if (currentPage != null) {
      final maxStep = currentPage.elements.fold<int>(
        0,
        (max, element) => element.step > max ? element.step : max,
      );
      final isLastPage = currentPageIndex >= totalPages - 1;
      final isLastStep = currentStep >= maxStep;

      if (isLastPage && isLastStep && _authController.isAuthenticated) {
        _hasShownCompletionMessage = true;
        final userId = _authController.currentUser!['id'].toString();

        // Remover livro em progresso e incrementar livros lidos
        await _apiService.removeBookFromProgress(userId, widget.bookId);
        final gamification = await _apiService.incrementBooksRead(
          userId,
          bookId: int.parse(widget.bookId),
        );
        if (Get.isRegistered<ProfileController>()) {
          Get.find<ProfileController>().applyGamificationResult(gamification);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Parabéns! Você concluiu a leitura deste livro!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleBack() async {
    await _cleanupAudioPlayers();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    if (_authController.isAuthenticated) {
      final userId = _authController.currentUser!['id'].toString();
      final currentPageIndex = widget.controller.currentPageIndex;
      final currentStep = widget.controller.currentStep;
      final totalPages = widget.controller.pages.length;
      final currentPage = widget.controller.currentPage;
      if (currentPage != null) {
        final maxStep = currentPage.elements.fold<int>(
          0,
          (max, element) => element.step > max ? element.step : max,
        );
        final isLastPage = currentPageIndex >= totalPages - 1;
        final isLastStep = currentStep >= maxStep;

        if (isLastPage && isLastStep) {
          // Remover apenas a atualização de progresso, pois já foi tratado no método _checkAndShowCompletionMessage
          // Não mostrar mensagem ou aguardar delay aqui
        } else {
          await _apiService.updateReadingProgress(
            userId,
            widget.bookId,
            currentPageIndex,
            currentStep,
          );
        }
      }
    }

    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Get.back();
    }
  }

  Future<void> _addBookToProgressIfNeeded() async {
    if (_authController.isAuthenticated) {
      final userId = _authController.currentUser!['id'].toString();
      final currentPageIndex = widget.controller.currentPageIndex;
      final currentStep = widget.controller.currentStep;
      await _apiService.updateReadingProgress(
        userId,
        widget.bookId,
        currentPageIndex,
        currentStep,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: Scaffold(
        body: Obx(() {
          if (widget.controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (widget.controller.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.controller.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => widget.controller.loadBook(widget.bookId),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (widget.controller.currentPage == null) {
            return const Center(child: Text('Nenhuma página disponível'));
          }

          final Size screenSize = MediaQuery.of(context).size;

          // Escala proporcional única
          scale = screenSize.width / canvasWidth;
          if ((canvasHeight * scale) > screenSize.height) {
            scale = screenSize.height / canvasHeight;
          }

          final contentWidth = canvasWidth * scale;
          final contentHeight = canvasHeight * scale;

          offsetX = (screenSize.width - contentWidth) / 2;
          offsetY = (screenSize.height - contentHeight) / 2;

          final currentPage = widget.controller.currentPage!;
          final pageIndex = widget.controller.currentPageIndex;
          final pt = currentPage.pageTransition;
          final switchMs =
              pt.type.toLowerCase() == 'none'
                  ? 1
                  : pt.durationMs.clamp(200, 4000);

          return Container(
            color: Colors.black, // Back bars pretas
            child: Stack(
              children: [
                Positioned(
                  left: offsetX,
                  top: offsetY,
                  width: contentWidth,
                  height: contentHeight,
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: switchMs),
                    switchInCurve: Curves.easeInOutCubic,
                    switchOutCurve: Curves.easeInOutCubic,
                    transitionBuilder: (child, animation) {
                      return buildReaderPageTransition(
                        transition: pt,
                        animation: animation,
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: ValueKey<int>(pageIndex),
                      child: _buildPageCanvasStack(
                        currentPage,
                        widget.controller.getVisibleElements(),
                      ),
                    ),
                  ),
                ),

                // Controles de navegação
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botão voltar
                      IconButton(
                        onPressed: () {
                          widget.controller.previousStep();
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),

                      // Botão de autoplay
                      IconButton(
                        onPressed: _toggleAutoPlay,
                        icon: Icon(
                          _autoPlay ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                        ),
                      ),

                      // Botão avançar
                      IconButton(
                        onPressed: () {
                          widget.controller.nextStep();
                          _checkAndShowCompletionMessage();
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Barra superior fixa
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Colors.black.withAlpha(120),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Botão voltar
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: _handleBack,
                          ),
                          // Espaço entre o botão e os pontos
                          const SizedBox(width: 8),
                          // Pontos das etapas
                          Expanded(child: Center(child: _buildStepDots())),
                          // Espaço à direita para balancear
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepDots() {
    final currentPage = widget.controller.currentPage;
    if (currentPage == null) return const SizedBox();
    // Descobre o número de etapas distintas na página
    final steps =
        currentPage.elements.map((e) => e.step).toSet().toList()..sort();
    final currentStep = widget.controller.currentStep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(steps.length, (index) {
        final isActive = steps[index] == currentStep;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 14 : 10,
          height: isActive ? 14 : 10,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withAlpha(100),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        );
      }),
    );
  }
}
