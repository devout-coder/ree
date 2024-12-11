import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/image.dart' as img_lib;

class SerializedSpan {
  final String type; // 'text' or 'widget'
  final String? text;
  final TextStyle? style;
  final List<SerializedSpan>? children;
  final SerializedWidget? widget;

  SerializedSpan({
    required this.type,
    this.text,
    this.style,
    this.children,
    this.widget,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'text': text,
      'style': style != null
          ? {
              'color': style?.color?.value,
              'fontSize': style?.fontSize,
              'height': style?.height,
              'fontStyle': style?.fontStyle?.index,
              'fontWeight': style?.fontWeight?.index,
              'fontFamily': style?.fontFamily,
              'decoration': style?.decoration?.toString(),
              'textBaseline': style?.textBaseline?.index,
            }
          : null,
      'children': children?.map((child) => child.toJson()).toList(),
      'widget': widget?.toJson(),
    };
  }

  factory SerializedSpan.fromJson(Map<String, dynamic> json) {
    return SerializedSpan(
      type: json['type'],
      text: json['text'],
      style: json['style'] != null
          ? TextStyle(
              color: json['style']['color'] != null
                  ? Color(json['style']['color'])
                  : null,
              fontSize: json['style']['fontSize'],
              height: json['style']['height'],
              fontStyle: json['style']['fontStyle'] != null
                  ? FontStyle.values[json['style']['fontStyle']]
                  : null,
              fontWeight: json['style']['fontWeight'] != null
                  ? FontWeight.values[json['style']['fontWeight']]
                  : null,
              fontFamily: json['style']['fontFamily'],
              decoration: json['style']['decoration'] != null
                  ? _parseTextDecoration(json['style']['decoration'])
                  : null,
              textBaseline: json['style']['textBaseline'] != null
                  ? TextBaseline.values[json['style']['textBaseline']]
                  : null,
            )
          : null,
      children: json['children'] != null
          ? List<SerializedSpan>.from(
              json['children'].map((x) => SerializedSpan.fromJson(x)))
          : null,
      widget: json['widget'] != null
          ? SerializedWidget.fromJson(json['widget'])
          : null,
    );
  }

  TextSpan toTextSpan() {
    if (type == 'text') {
      return TextSpan(
        text: text,
        style: style,
        children:
            children?.map((child) => child.toTextSpan()).toList() ?? const [],
      );
    } else {
      return TextSpan(
        children: [
          if (widget != null) widget!.toWidgetSpan(),
          ...?children?.map((child) => child.toTextSpan()),
        ],
      );
    }
  }

  static SerializedSpan fromTextSpan(TextSpan span) {
    if (span.text != null) {
      return SerializedSpan(
        type: 'text',
        text: span.text,
        style: span.style,
        children: span.children
            ?.map((child) => fromInlineSpan(child))
            .whereType<SerializedSpan>()
            .toList(),
      );
    } else {
      return SerializedSpan(
        type: 'text',
        children: span.children
            ?.map((child) => fromInlineSpan(child))
            .whereType<SerializedSpan>()
            .toList(),
      );
    }
  }

  static SerializedSpan? fromInlineSpan(InlineSpan span) {
    if (span is TextSpan) {
      return fromTextSpan(span);
    } else if (span is WidgetSpan) {
      if (span.child is img_lib.Image) {
        final imageWidget = span.child as img_lib.Image;
        if (imageWidget.image is MemoryImage) {
          final memoryImage = imageWidget.image as MemoryImage;
          return SerializedSpan(
            type: 'widget',
            widget: SerializedWidget(
              type: 'image',
              imageData: base64Encode(memoryImage.bytes),
              width: imageWidget.width,
              height: imageWidget.height,
            ),
          );
        }
      }
    }
    return null;
  }

  static TextDecoration _parseTextDecoration(String value) {
    switch (value) {
      case 'TextDecoration.underline': return TextDecoration.underline;
      case 'TextDecoration.overline': return TextDecoration.overline;
      case 'TextDecoration.lineThrough': return TextDecoration.lineThrough;
      default: return TextDecoration.none;
    }
  }
}

class SerializedWidget {
  final String type;
  final String? imageData;
  final double? width;
  final double? height;

  SerializedWidget({
    required this.type,
    this.imageData,
    this.width,
    this.height,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'imageData': imageData,
      'width': width,
      'height': height,
    };
  }

  factory SerializedWidget.fromJson(Map<String, dynamic> json) {
    return SerializedWidget(
      type: json['type'],
      imageData: json['imageData'],
      width: json['width'],
      height: json['height'],
    );
  }

  WidgetSpan toWidgetSpan() {
    if (type == 'image' && imageData != null) {
      final imageBytes = base64Decode(imageData!);
      return WidgetSpan(
        child: img_lib.Image.memory(
          width: width,
          height: height,
          Uint8List.fromList(imageBytes),
        ),
      );
    }
    throw UnimplementedError('Unknown widget type: $type');
  }
} 