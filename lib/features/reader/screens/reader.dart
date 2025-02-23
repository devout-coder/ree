import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/services/html_paginator.dart';

class BookView extends StatefulWidget {
  final Uint8List? bookBytes;
  const BookView({super.key, this.bookBytes});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  int _currentPage = 0;

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
    List<String> books = [
      "six-easy-pieces",
      "hitchhiker's-guide-to-galaxy",
      "innovators",
      "animal_farm",
      "neuromancer",
      "1984",
      "12-rules-for-life",
      "fahrenheit-451",
      "verity",
      "brief-history-of-time",
    ];
    Uint8List epubBytes =
        widget.bookBytes ?? await loadEpubAsBytes('assets/${books[2]}.epub');

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
  double paddingVertical = 30;

  Map<String, EpubByteContentFile>? images;
  // EpubContent? content;
  List<Widget> paginatedHtml = [];
  List<String> chapterTitles = [];

  List<EpubChapter> parseChapters(EpubBook epubBook) {
    List<EpubChapter> allChapters = [];

    if (epubBook.Chapters != null) {
      for (var chapter in epubBook.Chapters!) {
        chapterTitles.add(chapter.Title ?? "");
        allChapters.add(chapter);
        // if (chapter.SubChapters != null) {
        //   allChapters.addAll(chapter.SubChapters!);
        // }
      }
    }

    return allChapters;
  }

  void parseAllChapters(EpubBook epubBook, BuildContext context) async {
    images = epubBook.Content?.Images;
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

    for (int i = 0; i < onlyChapterContent.length; i++) {
      chapterStartPages.add(paginatedHtml.length);

      paginatedHtml.addAll(await HtmlPaginator.paginateHtml(
        htmlContent: onlyChapterContent[i],
        context: context,
        pageHeight: safeHeight - 2 * paddingVertical,
        pageWidth: safeWidth - 2 * paddingHorizontal,
        paddingHorizontal: paddingHorizontal,
        paddingVertical: paddingVertical,
        images: images,
      ));
    }
    setState(() {});
    debugPrint("done with all chapters");
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
                children: paginatedHtml,
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
