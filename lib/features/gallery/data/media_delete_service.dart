import 'package:photo_manager/photo_manager.dart';

import '../../trash/data/trash_repository.dart';
import 'gallery_repository.dart';

enum DeleteOutcome { movedToNativeTrash, movedToAppTrash, failed }

/// Orchestrates the "delete" flow requested by Arnab:
///  - Android 11+ (API 30+): native MediaStore trash (30-day OS recycle bin)
///  - Android 8-10 (API 26-29): custom in-app trash (Hive + private storage)
///
/// We don't branch on `Build.VERSION.SDK_INT` directly — instead we simply
/// attempt the native trash call and fall back on failure, since
/// photo_manager itself throws on API < 30. This keeps the logic in one
/// place and self-adjusting to whatever device it runs on.
class MediaDeleteService {
  MediaDeleteService({
    GalleryRepository? galleryRepository,
    TrashRepository? trashRepository,
  })  : _gallery = galleryRepository ?? const GalleryRepository(),
        _trash = trashRepository ?? TrashRepository();

  final GalleryRepository _gallery;
  final TrashRepository _trash;

  Future<DeleteOutcome> deleteAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return DeleteOutcome.failed;

    try {
      await _gallery.moveToNativeTrash(assets);
      return DeleteOutcome.movedToNativeTrash;
    } catch (_) {
      // Android 10 and below (or OEM restriction) — use the app's own trash.
      var movedAny = false;
      for (final asset in assets) {
        final entry = await _trash.trashAsset(asset);
        if (entry != null) movedAny = true;
      }
      return movedAny ? DeleteOutcome.movedToAppTrash : DeleteOutcome.failed;
    }
  }
}
