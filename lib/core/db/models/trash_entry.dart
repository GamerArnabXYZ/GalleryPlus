import 'package:hive/hive.dart';

/// A single item sitting in GalleryPlus's own trash.
///
/// Only used on Android 8-10 (API < 30), where the OS has no native
/// MediaStore trash. The original bytes are moved into the app's private
/// storage so they survive until the user restores or permanently deletes
/// them (or the 30-day auto-purge runs), mirroring Android 11+'s behaviour.
class TrashEntry {
  TrashEntry({
    required this.id,
    required this.originalAssetId,
    required this.fileName,
    required this.trashedFilePath,
    required this.isVideo,
    required this.sizeBytes,
    required this.trashedAt,
  });

  final String id;
  final String originalAssetId;
  final String fileName;
  final String trashedFilePath;
  final bool isVideo;
  final int sizeBytes;
  final DateTime trashedAt;

  int get daysRemaining {
    final expiresAt = trashedAt.add(const Duration(days: 30));
    final remaining = expiresAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }
}

/// Hand-written adapter — avoids requiring build_runner in CI.
class TrashEntryAdapter extends TypeAdapter<TrashEntry> {
  @override
  final int typeId = 1;

  @override
  TrashEntry read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return TrashEntry(
      id: fields[0] as String,
      originalAssetId: fields[1] as String,
      fileName: fields[2] as String,
      trashedFilePath: fields[3] as String,
      isVideo: fields[4] as bool,
      sizeBytes: fields[5] as int,
      trashedAt: DateTime.fromMillisecondsSinceEpoch(fields[6] as int),
    );
  }

  @override
  void write(BinaryWriter writer, TrashEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.originalAssetId)
      ..writeByte(2)
      ..write(obj.fileName)
      ..writeByte(3)
      ..write(obj.trashedFilePath)
      ..writeByte(4)
      ..write(obj.isVideo)
      ..writeByte(5)
      ..write(obj.sizeBytes)
      ..writeByte(6)
      ..write(obj.trashedAt.millisecondsSinceEpoch);
  }
}
