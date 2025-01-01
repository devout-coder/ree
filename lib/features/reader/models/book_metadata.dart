import 'package:hive_flutter/hive_flutter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:ree/hive_boxes.dart';
part 'book_metadata.g.dart';

@JsonSerializable()
@HiveType(typeId: HiveTypeIds.bookMetadata)
class BookMetadata extends HiveObject with EquatableMixin {
  @HiveField(0)
  final String title;

  @HiveField(1)
  final String coverImagePath;

  @HiveField(2)
  final bool isProcessed;

  @HiveField(3)
  final double processingProgress;

  BookMetadata({
    required this.title,
    required this.coverImagePath,
    this.isProcessed = false,
    this.processingProgress = 0.0,
  });

  BookMetadata copyWith({
    String? title,
    String? coverImagePath,
    bool? isProcessed,
    double? processingProgress,
  }) {
    return BookMetadata(
      title: title ?? this.title,
      coverImagePath: coverImagePath ?? this.coverImagePath,
      isProcessed: isProcessed ?? this.isProcessed,
      processingProgress: processingProgress ?? this.processingProgress,
    );
  }

  @override
  List<Object?> get props =>
      [title, coverImagePath, isProcessed, processingProgress];
}
