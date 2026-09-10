import 'package:hive/hive.dart';

import '../../../core/db/hive_service.dart';

/// Stores favorite marks as assetId -> true in a Hive box.
/// No custom model needed — kept intentionally simple.
class FavoritesRepository {
  Box<bool> get _box => Hive.box<bool>(HiveBoxes.favorites);

  bool isFavorite(String assetId) => _box.get(assetId) ?? false;

  Future<void> toggle(String assetId) async {
    if (isFavorite(assetId)) {
      await _box.delete(assetId);
    } else {
      await _box.put(assetId, true);
    }
  }

  Set<String> allFavoriteIds() => _box.keys.cast<String>().toSet();

  /// Call when an asset is permanently deleted, so stale favorite marks
  /// don't linger.
  Future<void> remove(String assetId) => _box.delete(assetId);
}
