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
    Uint8List epubBytes = widget.bookBytes ??
        await loadEpubAsBytes('assets/six-easy-pieces.epub');

    EpubBook epubBook = await EpubReader.readBook(epubBytes);
    if (!mounted) return;
    parseAllChapters(epubBook, context);
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

  List<EpubChapter> parseChapters(EpubBook epubBook) =>
      epubBook.Chapters?.fold<List<EpubChapter>>(
        [],
        (acc, next) {
          acc.add(next);
          next.SubChapters?.forEach(acc.add);
          return acc;
        },
      ) ??
      [];

  void parseAllChapters(EpubBook epubBook, BuildContext context) async {
    images = epubBook.Content?.Images;
    // List<String> onlyChapterContent = epubBook.Content?.Html?.values
    //         .toList()
    //         .map((e) => e.Content ?? "")
    //         .toList() ??
    //     [];

    List<EpubChapter> chapters = parseChapters(epubBook);
    List<String> onlyChapterContent =
        chapters.map((e) => e.HtmlContent ?? "").toList();

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

    // // Load initial chapters
    // for (int i = 0;
    //     i < initialChaptersToLoad && i < onlyChapterContent.length;
    //     i++) {
    //   paginatedHtml.addAll(await convertChapterToTextSpans(
    //       onlyChapterContent[i],
    //       pageSize,
    //       realPagePainter,
    //       fakePagePainter,
    //       images));
    //   _lastLoadedChapterIndex = i;
    // }
    // setState(() {});
    // debugPrint("done with initial chapters");
    // // Schedule remaining chapters to load in the background
    // _loadRemainingChapters(onlyChapterContent, pageSize);

    for (int i = 0; i < onlyChapterContent.length; i++) {
      print("i: $i\n${onlyChapterContent[i]}");
      paginatedHtml.addAll(await convertChapterToTextSpans(
          onlyChapterContent[i],
          pageSize,
          realPagePainter,
          fakePagePainter,
          images));
      _lastLoadedChapterIndex = i;
    }
    setState(() {});
    debugPrint("done with initial chapters");
    // Schedule remaining chapters to load in the background
  }

  Future<void> _loadRemainingChapters(
      List<String> chapters, Size pageSize) async {
    for (int i = _lastLoadedChapterIndex + 1; i < chapters.length; i++) {
      if (!mounted) break;

      final newSpans = await convertChapterToTextSpans(
          chapters[i], pageSize, realPagePainter, fakePagePainter, images);

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
