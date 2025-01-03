import 'package:flutter/material.dart';
import 'package:flutter_html_reborn/flutter_html_reborn.dart';

class HtmlPaginator {
  static Future<List<Widget>> paginateHtml({
    required String htmlContent,
    required BuildContext context,
    required double pageHeight,
    required double pageWidth,
  }) async {
    final List<Widget> pages = [];
    final GlobalKey measurementKey = GlobalKey();

    // Create an overlay entry to measure the content
    final OverlayEntry measurementEntry = OverlayEntry(
      builder: (context) => Opacity(
        opacity: 0.0,
        child: SingleChildScrollView(
          child: Html(
            key: measurementKey,
            data: htmlContent,
            style: {
              "body": Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
            },
          ),
        ),
      ),
    );

    // Add the measurement widget to the overlay
    Overlay.of(context).insert(measurementEntry);

    // Wait for the layout to complete
    await Future.delayed(const Duration(milliseconds: 100));

    // Get the total height
    final RenderBox? renderBox =
        measurementKey.currentContext?.findRenderObject() as RenderBox?;

    if (renderBox == null) {
      measurementEntry.remove();
      return [];
    }

    final double totalHeight = renderBox.size.height;
    final int pageCount = (totalHeight / pageHeight).ceil();

    // Create pages based on scroll offset
    for (int i = 0; i < pageCount; i++) {
      final bool isLastPage = i == pageCount - 1;
      final double remainingHeight = totalHeight - (i * pageHeight);
      final double currentPageHeight =
          isLastPage ? remainingHeight : pageHeight;

      pages.add(
        SizedBox(
          height: pageHeight,
          width: pageWidth,
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
                          offset: Offset(0, -i * pageHeight),
                          child: Html(
                            data: htmlContent,
                            style: {
                              "body": Style(
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                              ),
                            },
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
      );
    }

    // Remove the measurement widget
    measurementEntry.remove();

    return pages;
  }
}
