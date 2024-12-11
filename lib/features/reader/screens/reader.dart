import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/models/serialized_span.dart';
import 'package:ree/features/reader/services/paginate.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Uint8List epubBytes =
          widget.bookBytes ?? await loadEpubAsBytes('assets/innovators.epub');

      EpubBook epubBook = await EpubReader.readBook(epubBytes);
      // Try to load saved pages first
      await loadFromJson(epubBook.Title ?? "unknown");

      // If no pages were loaded, parse the epub
      if (paginatedHtml.isEmpty) {
        if (!mounted) return;
        parseAllChapters(epubBook, context);
      }
    });
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

  List<EpubChapter> getChapters(EpubBook epubBook) =>
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

    List<EpubChapter> chapters = getChapters(epubBook);
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
    await saveToJson(epubBook.Title ?? "unknown"); // Save pages after parsing
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

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> _getLocalFile(String bookId) async {
    final path = await _localPath;
    return File('$path/$bookId.json');
  }

  Future<void> saveToJson(String title) async {
    try {
      final serializedPages = paginatedHtml
          .map((textSpan) => SerializedSpan.fromTextSpan(textSpan).toJson())
          .toList();

      final jsonString = jsonEncode(serializedPages);

      // Save to file
      final file = await _getLocalFile(title); // Replace with actual book ID
      await file.writeAsString(jsonString);
      debugPrint('Saved pages to: ${file.path}');
    } catch (e) {
      debugPrint('Error saving JSON: $e');
    }
  }

  Future<void> loadFromJson(String title) async {
    try {
      final file = await _getLocalFile(title); // Replace with actual book ID

      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(jsonString);

        paginatedHtml = jsonList
            .map((json) => SerializedSpan.fromJson(json).toTextSpan())
            .toList();

        setState(() {});
        debugPrint('Loaded pages from: ${file.path}');
      } else {
        debugPrint('No saved pages found');
      }
    } catch (e) {
      debugPrint('Error loading JSON: $e');
    }
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
