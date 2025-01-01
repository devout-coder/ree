import 'package:hive_flutter/hive_flutter.dart';
import 'package:ree/features/reader/models/book_metadata.dart';

class HiveTypeIds {
  static const int bookMetadata = 0;
}

class HiveBoxNames {
  static const String bookMetadataBox = 'booksMetadata';
}

Future<void> initHive() async {
  await Hive.initFlutter();
  _registerAdapters();
}

void _registerAdapters() {
  Hive.registerAdapter(BookMetadataAdapter());
}

Future<void> openHiveBoxes() async {
  await Hive.openBox<BookMetadata>(HiveBoxNames.bookMetadataBox);
}
