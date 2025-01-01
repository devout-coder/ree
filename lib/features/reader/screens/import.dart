import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:epubx/epubx.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ree/features/reader/models/book_metadata.dart';
import 'package:ree/features/reader/screens/reader.dart';
import 'package:ree/features/reader/services/paginate.dart';
import 'package:flutter/src/widgets/image.dart' as img_lib;
import 'package:ree/features/reader/utils/styles.dart';
import 'package:ree/hive_boxes.dart';
import 'package:image/image.dart' as img;

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  late Box<BookMetadata> _booksMetadataBox;

  @override
  void initState() {
    super.initState();
    _booksMetadataBox = Hive.box<BookMetadata>(HiveBoxNames.bookMetadataBox);
  }

  String _generateHash(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Future<String> _saveCoverImage(
    Uint32List imageBytes,
    String bookId, {
    required int width,
    required int height,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final coverImagesDir = Directory('${directory.path}/cover_images');
    if (!await coverImagesDir.exists()) {
      await coverImagesDir.create();
    }

    final decodedImage = img.Image.fromBytes(
      width,
      height,
      imageBytes,
    );

    final pngData = img.encodePng(decodedImage);

    final filePath = '${coverImagesDir.path}/$bookId.png';
    final file = File(filePath);
    await file.writeAsBytes(pngData);

    return filePath;
  }

  Future<void> _processBook(
      EpubBook epubBook, Uint8List bookBytes, String bookId) async {
    // Save cover image
    if (epubBook.CoverImage != null) {
      String coverImagePath = await _saveCoverImage(
        epubBook.CoverImage!.data,
        bookId,
        width: epubBook.CoverImage!.width,
        height: epubBook.CoverImage!.height,
      );

      // Create initial metadata entry
      await _booksMetadataBox.put(
        bookId,
        BookMetadata(
          title: epubBook.Title ?? '',
          coverImagePath: coverImagePath,
        ),
      );
    } else {
      await _booksMetadataBox.put(
        bookId,
        BookMetadata(
          title: epubBook.Title ?? '',
          coverImagePath: "",
        ),
      );
    }
    if (!mounted) return;
    // Process chapters
    final mediaQuery = MediaQuery.of(context);
    final safeWidth = mediaQuery.size.width - mediaQuery.padding.horizontal;
    final safeHeight = mediaQuery.size.height - mediaQuery.padding.vertical;
    final pageSize = Size(
        safeWidth - 2 * paddingHorizontal, safeHeight - 2 * paddingVertical);

    final chapters = epubBook.Chapters?.fold<List<EpubChapter>>(
          [],
          (acc, next) {
            acc.add(next);
            next.SubChapters?.forEach(acc.add);
            return acc;
          },
        ) ??
        [];

    final totalChapters = chapters.length;
    List<TextSpan> processedPages = [];

    for (int i = 0; i < chapters.length; i++) {
      final chapter = chapters[i];
      final chapterContent = chapter.HtmlContent ?? '';

      processedPages.addAll(
        await convertChapterToTextSpans(
          chapterContent,
          pageSize,
          TextPainter(textDirection: TextDirection.ltr),
          TextPainter(textDirection: TextDirection.ltr),
          epubBook.Content?.Images,
        ),
      );

      // Update progress
      final progress = (i + 1) / totalChapters;
      final currentMetadata = _booksMetadataBox.get(bookId);
      if (currentMetadata != null) {
        await _booksMetadataBox.put(
          bookId,
          currentMetadata.copyWith(processingProgress: progress),
        );
      }
    }

    // Mark as processed and save pages
    final currentMetadata = _booksMetadataBox.get(bookId);
    if (currentMetadata != null) {
      await _booksMetadataBox.put(
        bookId,
        currentMetadata.copyWith(
          isProcessed: true,
          processingProgress: 1.0,
        ),
      );
    }

    // Save processed pages
    await saveProcessedPages(bookId, processedPages);
  }

  void _importBook() async {
    const XTypeGroup typeGroup = XTypeGroup(
      label: 'Books',
      extensions: <String>['epub'],
    );

    final XFile? file = await openFile(
      acceptedTypeGroups: <XTypeGroup>[typeGroup],
    );

    if (file != null) {
      final bytes = await file.readAsBytes();
      final epubBook = await EpubReader.readBook(bytes);
      final bookId = _generateHash(epubBook.Title ?? DateTime.now().toString());

      // Start processing in the background
      _processBook(epubBook, bytes, bookId);
    }
  }

  Future<void> _clearProcessedBooks() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final processedBooksDir = Directory('${directory.path}/processed_books');

      if (await processedBooksDir.exists()) {
        await processedBooksDir.delete(recursive: true);
        await processedBooksDir.create();
      }

      // Also clear the cover images
      final coverImagesDir = Directory('${directory.path}/cover_images');
      if (await coverImagesDir.exists()) {
        await coverImagesDir.delete(recursive: true);
        await coverImagesDir.create();
      }

      // Clear the Hive box
      await _booksMetadataBox.clear();
    } catch (e) {
      debugPrint('Error clearing processed books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // _clearProcessedBooks();
    return Scaffold(
      body: SafeArea(
        child: ValueListenableBuilder(
          valueListenable: _booksMetadataBox.listenable(),
          builder: (context, Box<BookMetadata> box, _) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: box.length,
              itemBuilder: (context, index) {
                final metadata = box.getAt(index);
                if (metadata == null) return const SizedBox();
                return GestureDetector(
                  onTap: metadata.isProcessed
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookView(
                                bookId: box.keyAt(index),
                              ),
                            ),
                          )
                      : null,
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (metadata.coverImagePath.isNotEmpty)
                              img_lib.Image.file(
                                File(metadata.coverImagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint(
                                      'Error loading cover image: $error');
                                  debugPrint(
                                      'Cover image path: ${metadata.coverImagePath}');
                                  return Container(
                                    color: Colors.red[300],
                                    child: const Icon(Icons.book, size: 40),
                                  );
                                },
                              )
                            else
                              Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.book, size: 40),
                              ),
                            if (!metadata.isProcessed)
                              Center(
                                child: CircularProgressIndicator(
                                  value: metadata.processingProgress,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        metadata.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _importBook,
        child: const Icon(Icons.add),
      ),
    );
  }
}
