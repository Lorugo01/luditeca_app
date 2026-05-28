class Book {
  final List<BookPage> pages;

  Book({required this.pages});

  factory Book.fromJson(List<dynamic> json) {
    return Book(
      pages:
          json
              .map(
                (pageJson) =>
                    BookPage.fromJson(pageJson as Map<String, dynamic>),
              )
              .toList(),
    );
  }
}

/// Trecho de texto com estilo (import PPTX / rich text).
class TextContentSpan {
  final String text;
  final String? fontWeight;
  final String? fontStyle;
  final String? color;
  final double? fontSize;

  TextContentSpan({
    required this.text,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.fontSize,
  });

  factory TextContentSpan.fromJson(Map<String, dynamic> json) {
    return TextContentSpan(
      text: json['text'] as String? ?? '',
      fontWeight: json['fontWeight'] as String?,
      fontStyle: json['fontStyle'] as String?,
      color: json['color'] as String?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
    );
  }
}

class BookElement {
  final String id;
  final String type;
  final String? shapeType;
  final String? fill;
  final String? borderColor;
  final double? borderWidth;
  final double? borderRadius;
  final double? rotation;
  final bool? flipX;
  final String? pointPosition;
  final Position position;
  final ElementSize size;
  final int step;
  final int zIndex;
  final String? content;
  final String? fontFamily;
  final double? fontSize;
  final String? fontWeight;
  final String? fontStyle;
  final String? color;
  final String? textAlign;
  final String? textDecoration;
  final double? lineHeight;
  final double? letterSpacing;
  final double? opacity;
  final String? strokeColor;
  final double? strokeWidth;
  final String? shadowColor;
  final double? shadowBlur;
  final double? shadowOpacity;
  final double? shadowOffsetX;
  final double? shadowOffsetY;
  final String? audio;
  final Map<String, dynamic>? audioStorage;
  final String? animation;
  final String? textStyle;
  final Position? audioButtonPosition;
  // Posição livre do badge (percentuais 0-100 dentro da caixa do elemento).
  final double? audioBadgeXPct;
  final double? audioBadgeYPct;
  // Canto de fallback quando não há posição percentual (nw | ne | sw | se).
  final String? audioBadgePlacement;
  // Canto sup. esq. do botão em coordenadas da página (ex.: 1280×720), como no editor V2.
  final double? audioBadgeCanvasX;
  final double? audioBadgeCanvasY;
  // Para imagens: 'gif' ativa comportamento de GIF animado.
  final String? mediaKind;
  final TextData? text;
  final ShapeProperties? shapeProperties;
  final List<TextContentSpan>? contentSpans;

  BookElement({
    required this.id,
    required this.type,
    this.shapeType,
    this.fill,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.rotation,
    this.flipX,
    this.pointPosition,
    required this.position,
    required this.size,
    required this.step,
    required this.zIndex,
    this.content,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.textAlign,
    this.textDecoration,
    this.lineHeight,
    this.letterSpacing,
    this.opacity,
    this.strokeColor,
    this.strokeWidth,
    this.shadowColor,
    this.shadowBlur,
    this.shadowOpacity,
    this.shadowOffsetX,
    this.shadowOffsetY,
    this.audio,
    this.audioStorage,
    this.animation,
    this.textStyle,
    this.audioButtonPosition,
    this.audioBadgeXPct,
    this.audioBadgeYPct,
    this.audioBadgePlacement,
    this.audioBadgeCanvasX,
    this.audioBadgeCanvasY,
    this.mediaKind,
    this.text,
    this.shapeProperties,
    this.contentSpans,
  });

  factory BookElement.fromJson(Map<String, dynamic> json) {
    return BookElement(
      id: json['id'],
      type: json['type'],
      shapeType: json['shapeProperties']?['type'],
      fill: json['shapeProperties']?['fill'],
      borderColor: json['shapeProperties']?['borderColor'],
      borderWidth: json['shapeProperties']?['borderWidth']?.toDouble(),
      borderRadius: json['borderRadius']?.toDouble(),
      rotation: json['shapeProperties']?['rotation']?.toDouble(),
      flipX: json['shapeProperties']?['flipX'],
      pointPosition: json['pointPosition'],
      position: Position.fromJson(json['position']),
      size: ElementSize.fromJson(json['size']),
      step: json['step'],
      zIndex: json['zIndex'],
      content: json['content'] ?? json['text']?['content'],
      fontFamily: json['fontFamily'] ?? json['text']?['fontFamily'],
      fontSize: (json['fontSize'] ?? json['text']?['fontSize'])?.toDouble(),
      fontWeight: json['fontWeight'] ?? json['text']?['fontWeight'],
      fontStyle: json['fontStyle'] ?? json['text']?['fontStyle'],
      color: json['color'],
      textAlign: json['textAlign'] ?? json['text']?['textAlign'],
      textDecoration: json['textDecoration'],
      lineHeight: (json['lineHeight'] as num?)?.toDouble(),
      letterSpacing: (json['letterSpacing'] as num?)?.toDouble(),
      opacity: (json['opacity'] as num?)?.toDouble(),
      strokeColor: json['strokeColor'],
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
      shadowColor: json['shadowColor'],
      shadowBlur: (json['shadowBlur'] as num?)?.toDouble(),
      shadowOpacity: (json['shadowOpacity'] as num?)?.toDouble(),
      shadowOffsetX: (json['shadowOffsetX'] as num?)?.toDouble(),
      shadowOffsetY: (json['shadowOffsetY'] as num?)?.toDouble(),
      audio: json['audio'] ?? json['text']?['audio'],
      audioStorage:
          json['audioStorage'] is Map
              ? Map<String, dynamic>.from(json['audioStorage'] as Map)
              : null,
      animation: json['animation'],
      textStyle: json['textStyle'],
      audioButtonPosition:
          json['text']?['audioButtonPosition'] != null
              ? Position.fromJson(json['text']['audioButtonPosition'])
              : null,
      audioBadgeXPct: (json['audioBadgeXPct'] as num?)?.toDouble(),
      audioBadgeYPct: (json['audioBadgeYPct'] as num?)?.toDouble(),
      audioBadgePlacement: json['audioBadgePlacement'] as String?,
      audioBadgeCanvasX: (json['audioBadgeCanvasX'] as num?)?.toDouble(),
      audioBadgeCanvasY: (json['audioBadgeCanvasY'] as num?)?.toDouble(),
      mediaKind: json['mediaKind'] as String?,
      text: json['text'] != null ? TextData.fromJson(json['text']) : null,
      shapeProperties:
          json['shapeProperties'] != null
              ? ShapeProperties.fromJson(json['shapeProperties'])
              : null,
      contentSpans:
          json['contentSpans'] != null
              ? (json['contentSpans'] as List)
                  .map(
                    (e) => TextContentSpan.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
              : null,
    );
  }
}

class Position {
  final double x;
  final double y;

  Position({required this.x, required this.y});

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(x: json['x'].toDouble(), y: json['y'].toDouble());
  }
}

class ElementSize {
  final double width;
  final double height;

  ElementSize({required this.width, required this.height});

  factory ElementSize.fromJson(Map<String, dynamic> json) {
    return ElementSize(
      width: json['width'].toDouble(),
      height: json['height'].toDouble(),
    );
  }
}

class ImageStyle {
  final String objectFit;
  final double borderRadius;

  ImageStyle({required this.objectFit, required this.borderRadius});

  factory ImageStyle.fromJson(Map<String, dynamic> json) {
    return ImageStyle(
      objectFit: json['objectFit'] ?? 'cover',
      borderRadius: (json['borderRadius'] ?? 0).toDouble(),
    );
  }
}

class TextStyleData {
  final String fontFamily;
  final double fontSize;
  final String color;
  final String fontStyle;
  final String textAlign;
  final String fontWeight;

  TextStyleData({
    required this.fontFamily,
    required this.fontSize,
    required this.color,
    required this.fontStyle,
    required this.textAlign,
    required this.fontWeight,
  });

  factory TextStyleData.fromJson(Map<String, dynamic> json) {
    return TextStyleData(
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: (json['fontSize'] ?? 16).toDouble(),
      color: json['color'] ?? '#000000',
      fontStyle: json['fontStyle'] ?? 'normal',
      textAlign: json['textAlign'] ?? 'left',
      fontWeight: json['fontWeight'] ?? 'normal',
    );
  }
}

class BookBackground {
  final String url;
  final double scale;
  final Position position;

  BookBackground({
    required this.url,
    required this.scale,
    required this.position,
  });

  factory BookBackground.fromJson(Map<String, dynamic> json) {
    return BookBackground(
      url: json['url'],
      scale: (json['scale'] ?? 1).toDouble(),
      position: Position.fromJson(json['position']),
    );
  }
}

/// Transição entre páginas (ex.: importada do PPTX — `transition` no JSON da página).
class BookPageTransition {
  final String type;
  final int durationMs;
  final String? direction;

  const BookPageTransition({
    this.type = 'none',
    this.durationMs = 500,
    this.direction,
  });

  factory BookPageTransition.fromJson(dynamic json) {
    if (json is! Map) {
      return const BookPageTransition();
    }
    final m = Map<String, dynamic>.from(json);
    final rawMs = (m['durationMs'] as num?)?.round() ?? 500;
    final clampedMs = rawMs < 200 ? 200 : (rawMs > 4000 ? 4000 : rawMs);
    return BookPageTransition(
      type: m['type'] as String? ?? 'none',
      durationMs: clampedMs,
      direction: m['direction'] as String?,
    );
  }
}

class BookPage {
  final String background;
  final List<BookElement> elements;
  final BookPageTransition pageTransition;

  BookPage({
    required this.background,
    required this.elements,
    BookPageTransition? pageTransition,
  }) : pageTransition = pageTransition ?? const BookPageTransition();

  factory BookPage.fromJson(Map<String, dynamic> json) {
    final backgroundData = json['background'];
    String backgroundUrl = '';

    if (backgroundData is String) {
      backgroundUrl = backgroundData;
    } else if (backgroundData is Map<String, dynamic>) {
      final url = backgroundData['url'];
      if (url is String) {
        backgroundUrl = url;
      }
    }

    return BookPage(
      background: backgroundUrl,
      elements:
          (json['elements'] as List)
              .map((element) => BookElement.fromJson(element))
              .toList(),
      pageTransition: BookPageTransition.fromJson(json['transition']),
    );
  }
}

class TextData {
  final String? content;
  final String? fontFamily;
  final double? fontSize;
  final String? fontWeight;
  final String? fontStyle;
  final String? color;
  final String? textAlign;
  final String? audio;
  final Position? audioButtonPosition;

  TextData({
    this.content,
    this.fontFamily,
    this.fontSize,
    this.fontWeight,
    this.fontStyle,
    this.color,
    this.textAlign,
    this.audio,
    this.audioButtonPosition,
  });

  factory TextData.fromJson(Map<String, dynamic> json) {
    return TextData(
      content: json['content'],
      fontFamily: json['fontFamily'],
      fontSize: json['fontSize']?.toDouble(),
      fontWeight: json['fontWeight'],
      fontStyle: json['fontStyle'],
      color: json['color'],
      textAlign: json['textAlign'],
      audio: json['audio'],
      audioButtonPosition:
          json['audioButtonPosition'] != null
              ? Position.fromJson(json['audioButtonPosition'])
              : null,
    );
  }
}

class ShapeProperties {
  final String fill;
  final String type;
  final bool flipX;
  final double rotation;
  final String borderColor;
  final double borderWidth;

  ShapeProperties({
    required this.fill,
    required this.type,
    required this.flipX,
    required this.rotation,
    required this.borderColor,
    required this.borderWidth,
  });

  factory ShapeProperties.fromJson(Map<String, dynamic> json) {
    return ShapeProperties(
      fill: json['fill'],
      type: json['type'],
      flipX: json['flipX'] ?? false,
      rotation: (json['rotation'] ?? 0).toDouble(),
      borderColor: json['borderColor'],
      borderWidth: (json['borderWidth'] ?? 2).toDouble(),
    );
  }
}
