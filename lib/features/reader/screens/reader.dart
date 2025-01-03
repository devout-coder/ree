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

  bool _areControlsVisible = false;

  // Add this new field to store chapter starting pages
  List<int> chapterStartPages = [];

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
  List<String> chapterTitles = [];

  TextPainter fakePagePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );
  TextPainter realPagePainter = TextPainter(
    textDirection: TextDirection.ltr,
  );

  List<EpubChapter> parseChapters(EpubBook epubBook) {
    List<EpubChapter> allChapters = [];

    if (epubBook.Chapters != null) {
      for (var chapter in epubBook.Chapters!) {
        allChapters.add(chapter);
        // if (chapter.SubChapters != null) {
        //   allChapters.addAll(chapter.SubChapters!);
        // }
      }
    }

    return allChapters;
  }

  List<String> parseChapterTitles(List<EpubChapter> chapters) {
    return chapters.map((e) => e.Title ?? "").toList();
  }

  void parseAllChapters(EpubBook epubBook, BuildContext context) async {
    images = epubBook.Content?.Images;
    // List<String> onlyChapterContent = epubBook.Content?.Html?.values
    //         .toList()
    //         .map((e) => e.Content ?? "")
    //         .toList() ??
    //     [];

    List<EpubChapter> chapters = parseChapters(epubBook);
    chapterTitles = parseChapterTitles(chapters);
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
      // Store the current length before adding new pages
      chapterStartPages.add(paginatedHtml.length);

      print("$i ${chapterTitles[i]}\n${onlyChapterContent[i]}");
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

  void _toggleControls() {
    setState(() {
      _areControlsVisible = !_areControlsVisible;
    });
    // Auto-hide controls after 3 seconds
    if (_areControlsVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _areControlsVisible = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Text('Table of Contents'),
            ),
            for (int i = 0; i < chapterTitles.length; i++)
              ListTile(
                title: Text(chapterTitles[i]),
                onTap: () {
                  setState(() {
                    _currentPage = chapterStartPages[i];
                  });
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
      body: SafeArea(
        child: GestureDetector(
          onVerticalDragEnd: (_) => _toggleControls(),
          child: Stack(
            children: [
              PageFlipWidget(
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
              // Top control bar
              AnimatedOpacity(
                opacity: _areControlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 56,
                  color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.9),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.font_download),
                        onPressed: () {
                          // TODO: Implement font settings
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Bottom control bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _areControlsVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    height: 56,
                    color: Theme.of(context)
                        .scaffoldBackgroundColor
                        .withOpacity(0.9),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
