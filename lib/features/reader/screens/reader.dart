import 'dart:typed_data';

import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/utils/styles.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/src/widgets/image.dart'
    as img_lib; // Use a prefix for the image package

class BookView extends StatefulWidget {
  final Uint8List? bookBytes;
  const BookView({super.key, this.bookBytes});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadEpubFile();
    });
  }

  void loadEpubFile() async {
    Uint8List epubBytes =
        widget.bookBytes ?? await loadEpubAsBytes('assets/innovators.epub');

    EpubBook epubBook = await EpubReader.readBook(epubBytes);
    if (!mounted) return;

    parseAllChapters(epubBook.Content, context);
  }

  Future<Uint8List> loadEpubAsBytes(String assetPath) async {
    // Load the EPUB file as a byte data
    ByteData byteData = await rootBundle.load(assetPath);

    // Convert ByteData to Uint8List
    Uint8List bytes = byteData.buffer.asUint8List();

    return bytes;
  }

  double paddingHorizontal = 16;
  double paddingVertical = 16;

  Map<String, EpubByteContentFile>? images;
  // EpubContent? content;
  List<TextSpan> paginatedHtml = [];

  TextPainter fakePagePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  TextPainter realPagePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  void parseAllChapters(EpubContent? epubContent, BuildContext context) async {
    images = epubContent?.Images;
    List<String> onlyChapterContent = epubContent?.Html?.values
            .toList()
            .map((e) => e.Content ?? "")
            .toList() ??
        [];
    // Get available page size (subtracting padding)
    final mediaQuery = MediaQuery.of(context);
    final safeWidth = mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
    final safeHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;
    final pageSize = Size(
      safeWidth - 2 * paddingHorizontal,
      safeHeight - 2 * paddingVertical,
    );

    List<TextSpan> finalPages = [];
    for (int i = 0; i < onlyChapterContent.length; i++) {
      finalPages.addAll(
          await convertChapterToTextSpans(onlyChapterContent[i], pageSize));
      debugPrint("converted chapter");
    }
    debugPrint("done with everything");
    setState(() {
      paginatedHtml = finalPages;
    });
  }

  Future<List<TextSpan>> convertChapterToTextSpans(
      String chapterHtmlContent, Size pageSize) async {
    // Parse HTML content
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
    List<TextSpan> textSpans =
        await parseNodes([], [], body, baseStyle, pageSize);
    TextSpan previousText = realPagePainter.text as TextSpan;
    textSpans.add(previousText);
    return textSpans;
  }

  Future<List<TextSpan>> parseNodes(
      List<TextSpan> chapterText,
      List<String> tags,
      dom.Element? node,
      TextStyle parentStyle,
      Size pageSize) async {
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
        chapterText =
            await parseNodes(chapterText, tags, child, nodeStyle, pageSize);
      }
    }

    tags.removeLast();
    return chapterText;
  }

  List<String> bsOnTextSpan(TextSpan prevTextSpan, String newText,
      TextStyle textStyle, Size pageSize) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: paginatedHtml.isNotEmpty
          ? SafeArea(
              child: PageFlipWidget(
                key: GlobalKey(),
                children: <Widget>[
                  for (var i = 0; i < paginatedHtml.length; i++)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingHorizontal,
                        vertical: paddingVertical,
                      ),
                      child: RichText(text: paginatedHtml[i]),
                    )
                ],
              ),
            )
          : Container(),
    );
  }
}
