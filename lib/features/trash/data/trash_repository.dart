import 'dart:io';

import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/db/hive_service.dart';
import '../../../core/db/models/trash_entry.dart';

/// Custom, app-level recycle bin.
///
/// Used on Android 8-10 (API < 30), where MediaStore has no native trash.
/// Trashed files live in the app's private storage (auto-cleared if the
/// app is uninstalled) and are auto-purged 30 days after trashing, matching
/// the native Android 11+ trash window for a consistent experience.
class TrashRepository {
  TrashRepository();

  Box<TrashEntry> get _box => Hive.box<TrashEntry>(HiveBoxes.trash);

  Future<Directory> _trashDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/trash');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  List<TrashEntry> listAll() {
    final items = _box.values.toList();
    items.sort((a, b) => b.trashedAt.compareTo(a.trashedAt));
    return items;
  }

  /// Moves [entity]'s original file into the app trash, records it in Hive,
  /// then removes the original from MediaStore. Returns the created entry,
  /// or null if the underlying file couldn't be read.
  Future<TrashEntry?> trashAsset(AssetEntity entity) async {
    final file = await entity.originFile ?? await entity.file;
    if (file == null || !await file.exists()) return null;

    final isVideo = entity.type == AssetType.video;
    final dir = await _trashDir();
    final fileName = file.uri.pathSegments.isNotEmpty
        ? file.uri.pathSegments.last
        : '${entity.id}${isVideo ? '.mp4' : '.jpg'}';
    final uniqueName = '${DateTime.now().microsecondsSinceEpoch}_$fileName';
    final movedFile = await file.copy('${dir.path}/$uniqueName');
    final sizeBytes = await movedFile.length();

    final entry = TrashEntry(
      id: '${DateTime.now().microsecondsSinceEpoch}',
      originalAssetId: entity.id,
      fileName: fileName,
      trashedFilePath: movedFile.path,
      isVideo: isVideo,
      sizeBytes: sizeBytes,
      trashedAt: DateTime.now(),
    );

    await _box.put(entry.id, entry);
    await PhotoManager.editor.deleteWithIds([entity.id]);
    return entry;
  }

  /// Restores a trashed item back into the device gallery.
  Future<bool> restore(TrashEntry entry) async {
    final file = File(entry.trashedFilePath);
    if (!await file.exists()) {
      await _box.delete(entry.id);
      return false;
    }

    if (entry.isVideo) {
      await PhotoManager.editor.saveVideo(file, title: entry.fileName);
    } else {
      await PhotoManager.editor.saveImage(
        await file.readAsBytes(),
        filename: entry.fileName,
      );
    }

    await file.delete();
    await _box.delete(entry.id);
    return true;
  }

  Future<void> permanentlyDelete(TrashEntry entry) async {
    final file = File(entry.trashedFilePath);
    if (await file.exists()) await file.delete();
    await _box.delete(entry.id);
  }

  /// Call on app start — silently removes anything past the 30-day window.
  Future<void> purgeExpired() async {
    final expired = _box.values.where((e) => e.daysRemaining <= 0).toList();
    for (final entry in expired) {
      await permanentlyDelete(entry);
    }
  }
}
