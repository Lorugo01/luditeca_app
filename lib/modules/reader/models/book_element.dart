import 'dart:ui';

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
  final String? audio;
  final String? animation;
  final String? textStyle;
  final Position? audioButtonPosition;
  final TextData? text;
  final ShapeProperties? shapeProperties;

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
    this.audio,
    this.animation,
    this.textStyle,
    this.audioButtonPosition,
    this.text,
    this.shapeProperties,
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
      audio: json['audio'] ?? json['text']?['audio'],
      animation: json['animation'],
      textStyle: json['textStyle'],
      audioButtonPosition:
          json['text']?['audioButtonPosition'] != null
              ? Position.fromJson(json['text']['audioButtonPosition'])
              : null,
      text: json['text'] != null ? TextData.fromJson(json['text']) : null,
      shapeProperties:
          json['shapeProperties'] != null
              ? ShapeProperties.fromJson(json['shapeProperties'])
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

class BookPage {
  final String background;
  final List<BookElement> elements;

  BookPage({required this.background, required this.elements});

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      background: json['background']['url'] as String,
      elements:
          (json['elements'] as List)
              .map((element) => BookElement.fromJson(element))
              .toList(),
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
