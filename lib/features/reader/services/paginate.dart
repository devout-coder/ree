import 'dart:typed_data';

import 'package:dart_ui_isolate/dart_ui_isolate.dart';
import 'package:ree/features/reader/screens/reader.dart';
import 'package:ree/features/reader/utils/styles.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/src/widgets/image.dart' as img_lib;

Future<List<TextSpan>> doExpensiveWorkInBackground(
    String chapterHtmlContent) async {
  return await flutterCompute(convertChapterToTextSpans, chapterHtmlContent);
}

@pragma('vm:entry-point')
Future<List<TextSpan>> convertChapterToTextSpans(
  String bookData,
) async {
  // Parse HTML content
  final BookData deserialized = BookData.fromJsonString(bookData);
  String chapterHtmlContent = deserialized.chapterHtmlContent;
  double width = deserialized.width;
  double height = deserialized.height;
  Size pageSize = Size(
    width,
    height,
  );
  final document = html_parser.parse(chapterHtmlContent);
  final body = document.body;
  TextStyle baseStyle = const TextStyle(
    color: Colors.black,
    fontSize: 14,
  );
  realPagePainter.text = TextSpan(
    text: '', // Will be updated in the loop
    style: baseStyle, // Add appropriate text style
  );
  fakePagePainter.text = TextSpan(
    text: '', // Will be updated in the loop
    style: baseStyle, // Add appropriate text style
  );
  List<TextSpan> textSpans = await parseNodes([], [], body, baseStyle, pageSize,
      fakePagePainter, realPagePainter, images);
  TextSpan previousText = realPagePainter.text as TextSpan;
  textSpans.add(previousText);
  return textSpans;
}

Future<List<TextSpan>> parseNodes(
  List<TextSpan> chapterText,
  List<String> tags,
  dom.Element? node,
  TextStyle parentStyle,
  Size pageSize,
  TextPainter fakePagePainter,
  TextPainter realPagePainter,
  Map<String, EpubByteContentFile>? images,
) async {
  if (node == null) {
    return chapterText;
  }
  TextStyle nodeStyle = parentStyle.merge(tagStyles[node.localName]);
  tags.add(node.localName ?? "");
  if (tags.contains("img")) {
    String src = node.attributes["src"] ?? "";
    EpubByteContentFile? image = images?[src];
    List<int>? imageBytes = image?.Content;
    if (image != null && imageBytes != null) {
      TextSpan fakePreviousText = fakePagePainter.text as TextSpan;
      TextSpan realPreviousText = realPagePainter.text as TextSpan;
      Uint8List imageList = Uint8List.fromList(imageBytes);
      final image = await decodeImageFromList(imageList);

      WidgetSpan imageWidget = WidgetSpan(
        child: img_lib.Image.memory(
          width: image.width.toDouble(),
          height: image.height.toDouble(),
          imageList,
          // fit: BoxFit.contain,
        ),
      );
      TextPainter tempPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          children: [
            fakePreviousText,
          ],
        ),
      );
      tempPainter.layout(maxWidth: pageSize.width);
      if (tempPainter.height + image.height > pageSize.height) {
        chapterText.add(realPreviousText);
        realPagePainter.text = TextSpan(
          children: [
            imageWidget,
          ],
        );
        fakePagePainter.text = TextSpan(
          children: [
            TextSpan(
              text: "\n",
              style: TextStyle(fontSize: image.height.toDouble()),
            ),
          ],
        );
      } else {
        fakePagePainter.text = TextSpan(
          children: [
            fakePreviousText,
            const TextSpan(
              text: "\n",
            ), // imageWidget,
            TextSpan(
              text: "\n",
              style: TextStyle(fontSize: image.height.toDouble()),
            ),
          ],
        );
        realPagePainter.text = TextSpan(
          children: [
            realPreviousText,
            imageWidget,
          ],
        );
      }
    }
  } else if (node.children.isEmpty && node.text.isNotEmpty) {
    // if (node.children.isEmpty) {
    //base condition
    TextSpan fakePreviousText = fakePagePainter.text as TextSpan;
    TextSpan realPreviousText = realPagePainter.text as TextSpan;
    String newText =
        tags.contains("p") ? "\n    ${node.text}" : "\n${node.text}";
    TextPainter tempPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          fakePreviousText,
          TextSpan(
            text: newText,
            style: nodeStyle,
          ),
        ],
      ),
    );
    tempPainter.layout(maxWidth: pageSize.width);

    while (tempPainter.height > pageSize.height) {
      List<String> splitText =
          bsOnTextSpan(fakePreviousText, newText, nodeStyle, pageSize);
      chapterText.add(
        TextSpan(
          children: [
            realPreviousText,
            TextSpan(
              text: splitText[0],
              style: nodeStyle,
            ),
          ],
        ),
      );

      tempPainter.text = TextSpan(
        text: splitText[1],
        style: nodeStyle,
      );
      tempPainter.layout(maxWidth: pageSize.width);
      fakePreviousText = const TextSpan(text: "");
      realPreviousText = const TextSpan(text: "");
      newText = splitText[1];
    }
    realPagePainter.text = TextSpan(
      children: [
        realPreviousText,
        TextSpan(
          text: newText,
          style: nodeStyle,
        ),
      ],
    );
    fakePagePainter.text = tempPainter.text;
    // return chapterText;
  } else {
    for (var child in node.children) {
      chapterText = await parseNodes(
        chapterText,
        tags,
        child,
        nodeStyle,
        pageSize,
        fakePagePainter,
        realPagePainter,
        images,
      );
    }
  }

  tags.removeLast();
  return chapterText;
}

List<String> bsOnTextSpan(
    TextSpan prevTextSpan, String newText, TextStyle textStyle, Size pageSize) {
  int start = 0;
  int end = newText.length;
  int mid;
  int ans = 0;

  // Binary search to find split point
  while (start <= end) {
    mid = (start + end) ~/ 2;
    TextPainter tempPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        children: [
          prevTextSpan,
          TextSpan(
            text: newText.substring(0, mid),
            style: textStyle,
          ),
        ],
      ),
    );
    tempPainter.layout(maxWidth: pageSize.width);

    if (tempPainter.height > pageSize.height) {
      end = mid - 1;
    } else {
      ans = mid;
      start = mid + 1;
    }
  }

  int spaceIndex = newText.lastIndexOf(' ', ans);
  if (spaceIndex > 0) {
    ans = spaceIndex;
  }

  return [
    newText.substring(0, ans),
    newText.substring(ans + 1),
  ];
}
