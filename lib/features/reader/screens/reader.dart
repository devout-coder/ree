import 'package:flutter/material.dart';
import 'package:ree/features/page_flip/page_flip.dart';
import 'package:ree/features/reader/models/serialized_span.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:ree/features/reader/utils/styles.dart';

class BookView extends StatefulWidget {
  final String bookId;
  const BookView({super.key, required this.bookId});

  @override
  State<BookView> createState() => _BookViewState();
}

class _BookViewState extends State<BookView> {
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load the processed pages
      await loadFromJson(widget.bookId);
      setState(() {});
    });
  }

  List<TextSpan> paginatedHtml = [];

  Future<void> loadFromJson(String bookId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/processed_books/$bookId.json');

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
