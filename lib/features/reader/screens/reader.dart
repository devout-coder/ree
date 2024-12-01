import 'dart:convert';

import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/services/paginate.dart';

class BookView extends StatefulWidget {
  final Uint8List? bookBytes;
  const BookView({super.key, this.bookBytes});

  @override
  State<BookView> createState() => _BookViewState();
}

class BookData {
  String chapterHtmlContent;
  double width;
  double height;

  BookData({
    required this.chapterHtmlContent,
    required this.width,
    required this.height,
  });

  String toJsonString() {
    return jsonEncode(toMap());
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterHtmlContent': chapterHtmlContent,
      'width': width,
      'height': height,
    };
  }

  static BookData fromJsonString(String jsonString) {
    return BookData.fromMap(jsonDecode(jsonString));
  }

  static BookData fromMap(Map<String, dynamic> map) {
    return BookData(
      chapterHtmlContent: map['chapterHtmlContent'] as String,
      width: map['width'] as double,
      height: map['height'] as double,
    );
  }

  @override
  String toString() => toJsonString();
}

TextPainter realPagePainter = TextPainter(
  textDirection: TextDirection.ltr,
);
TextPainter fakePagePainter = TextPainter(
  textDirection: TextDirection.ltr,
);
Map<String, EpubByteContentFile>? images;

class _BookViewState extends State<BookView> {
  int _currentPage = 0;

  static const int initialChaptersToLoad = 2;
  int _lastLoadedChapterIndex = 0;

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

  // Map<String, EpubByteContentFile>? images;
  // EpubContent? content;
  List<TextSpan> paginatedHtml = [];

  // TextPainter fakePagePainter = TextPainter(
  //   textDirection: TextDirection.ltr,
  // );
  // TextPainter realPagePainter = TextPainter(
  //   textDirection: TextDirection.ltr,
  // );

  void parseAllChapters(EpubContent? epubContent, BuildContext context) async {
    List<String> onlyChapterContent = epubContent?.Html?.values
            .toList()
            .map((e) => e.Content ?? "")
            .toList() ??
        [];

    final mediaQuery = MediaQuery.of(context);
    final safeWidth = mediaQuery.size.width -
        mediaQuery.padding.left -
        mediaQuery.padding.right;
    final safeHeight = mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    images = epubContent?.Images;
    final effectiveWidth = safeWidth - 2 * paddingHorizontal;
    final effectiveHeight = safeHeight - 2 * paddingVertical;

    for (int i = 0;
        i < initialChaptersToLoad && i < onlyChapterContent.length;
        i++) {
      paginatedHtml.addAll(await doExpensiveWorkInBackground(BookData(
        chapterHtmlContent: onlyChapterContent[i],
        width: effectiveWidth,
        height: effectiveHeight,
      ).toString()));
      _lastLoadedChapterIndex = i;
    }
    setState(() {});
    debugPrint("done with initial chapters");
    // Schedule remaining chapters to load in the background
    _loadRemainingChapters(onlyChapterContent, effectiveWidth, effectiveHeight);
  }

  Future<void> _loadRemainingChapters(
      List<String> chapters, double width, double height) async {
    for (int i = _lastLoadedChapterIndex + 1; i < chapters.length; i++) {
      if (!mounted) break;

      final newSpans = await doExpensiveWorkInBackground(BookData(
        chapterHtmlContent: chapters[i],
        width: width,
        height: height,
      ).toString());

      // setState(() {
      paginatedHtml.addAll(newSpans);
      _lastLoadedChapterIndex = i;
      // });
    }
    debugPrint("done with remaining chapters");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageFlipWidget(
          key: GlobalKey(),
          onLastPageExit: () {
            debugPrint("last page reached");
            setState(() {});
          },
          initialIndex: _currentPage,
          onPageChanged: (pageNumber) {
            _currentPage = pageNumber;
            // debugPrint("current page: $_currentPage");
          },
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
      ),
    );
  }
}
