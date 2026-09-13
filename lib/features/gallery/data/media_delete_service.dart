import 'package:photo_manager/photo_manager.dart';

import '../../trash/data/trash_repository.dart';

enum DeleteOutcome { movedToTrash, failed }

/// Delete flow, per Arnab's request: EVERY deleted item — on every Android
/// version — moves into GalleryPlus's own trash (Hive-tracked, stored in
/// app-private storage), not the OS-level MediaStore trash. This keeps
/// behaviour identical across devices/OEMs and guarantees the in-app Trash
/// screen is always the single source of truth, with a 30-day auto-purge.
class MediaDeleteService {
  MediaDeleteService({TrashRepository? trashRepository})
      : _trash = trashRepository ?? TrashRepository();

  final TrashRepository _trash;

  Future<DeleteOutcome> deleteAssets(List<AssetEntity> assets) async {
    if (assets.isEmpty) return DeleteOutcome.failed;

    var movedAny = false;
    for (final asset in assets) {
      final entry = await _trash.trashAsset(asset);
      if (entry != null) movedAny = true;
    }
    return movedAny ? DeleteOutcome.movedToTrash : DeleteOutcome.failed;
  }
}
