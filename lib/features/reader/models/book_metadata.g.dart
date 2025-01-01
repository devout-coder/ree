// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookMetadataAdapter extends TypeAdapter<BookMetadata> {
  @override
  final int typeId = 0;

  @override
  BookMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookMetadata(
      title: fields[0] as String,
      coverImagePath: fields[1] as String,
      isProcessed: fields[2] as bool,
      processingProgress: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, BookMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.coverImagePath)
      ..writeByte(2)
      ..write(obj.isProcessed)
      ..writeByte(3)
      ..write(obj.processingProgress);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookMetadata _$BookMetadataFromJson(Map<String, dynamic> json) => BookMetadata(
      title: json['title'] as String,
      coverImagePath: json['coverImagePath'] as String,
      isProcessed: json['isProcessed'] as bool? ?? false,
      processingProgress:
          (json['processingProgress'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$BookMetadataToJson(BookMetadata instance) =>
    <String, dynamic>{
      'title': instance.title,
      'coverImagePath': instance.coverImagePath,
      'isProcessed': instance.isProcessed,
      'processingProgress': instance.processingProgress,
    };
