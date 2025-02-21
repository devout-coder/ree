import 'dart:typed_data';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/material.dart';
import 'package:flutter_html_reborn/flutter_html_reborn.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class HtmlPaginator {
  static Future<List<Widget>> paginateHtml({
    required String htmlContent,
    required BuildContext context,
    required double pageHeight,
    required double pageWidth,
    required double paddingHorizontal,
    required double paddingVertical,
    required Map<String, EpubByteContentFile>? images,
  }) async {
    final List<Widget> pages = [];
    final GlobalKey measurementKey = GlobalKey();

    Map<String, Style> htmlStyles = {};
    final htmlExtensions = [
      if (images != null)
        TagExtension(
          tagsToExtend: {"img"},
          builder: (extensionContext) {
            final url =
                extensionContext.attributes['src']!.replaceAll('../', '');
            return images[url]?.Content != null
                ? material.Image(
                    image: MemoryImage(
                      Uint8List.fromList(images[url]!.Content!),
                    ),
                  )
                : const SizedBox();
          },
        )
    ];

    // Create an overlay entry to measure the content
    late final OverlayEntry measurementEntry;
    measurementEntry = OverlayEntry(
      builder: (context) => Opacity(
        opacity: 0.0,
        child: Material(
          clipBehavior: Clip.antiAliasWithSaveLayer,
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Container(
              constraints: BoxConstraints(maxWidth: pageWidth),
              child: Html(
                key: measurementKey,
                data: htmlContent,
                style: htmlStyles,
                extensions: htmlExtensions,
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(measurementEntry);

    // Wait for images and rendering
    await Future.delayed(const Duration(milliseconds: 600));

    // Get the total height using more precise measurement
    final RenderBox? renderBox =
        measurementKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      measurementEntry.remove();
      return [];
    }

    // Add a small buffer to the total height to prevent clipping
    final double totalHeight = renderBox.size.height;
    double remainingHeight = totalHeight;
    double currentOffset = 0.0;

    while (remainingHeight > 0) {
      final double currentPageHeight =
          remainingHeight > pageHeight ? pageHeight : remainingHeight;

      pages.add(
        SizedBox(
          height: pageHeight,
          width: pageWidth,
          child: Padding(
            padding: EdgeInsets.symmetric(
              // horizontal: paddingHorizontal, vertical: paddingVertical,
              horizontal: 0,
              vertical: 0,
            ),
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: SizedBox(
                height: pageHeight,
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: currentPageHeight,
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.topLeft,
                          maxHeight: totalHeight,
                          child: Transform.translate(
                            offset: Offset(0, -currentOffset),
                            child: Html(
                              data: htmlContent,
                              style: htmlStyles,
                              extensions: htmlExtensions,
                            ),
                          ),
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

      remainingHeight -= pageHeight;
      currentOffset += pageHeight;
    }

    // Remove the measurement widget
    measurementEntry.remove();

    return pages;
  }
}
