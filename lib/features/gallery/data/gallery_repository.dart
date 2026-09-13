import 'package:photo_manager/photo_manager.dart';

enum GallerySortOption { dateNewest, dateOldest, sizeLargest, sizeSmallest }

/// Thin, testable wrapper around photo_manager. Nothing here touches Hive
/// or UI — pure data access.
class GalleryRepository {
  const GalleryRepository();

  static const int pageSize = 60;

  FilterOptionGroup _filterFor(GallerySortOption sort) {
    // Only date can be ordered natively/efficiently by MediaStore.
    // Size sorting is applied client-side (see sortBySizeIfNeeded) because
    // file byte-size isn't a queryable MediaStore column via photo_manager.
    final asc = sort == GallerySortOption.dateOldest;
    return FilterOptionGroup(
      orders: [OrderOption(type: OrderOptionType.createDate, asc: asc)],
      imageOption: const FilterOption(),
      videoOption: const FilterOption(),
    );
  }

  /// All albums on the device, "Recent"/"All" first.
  Future<List<AssetPathEntity>> getAlbums(GallerySortOption sort) {
    return PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: false,
      filterOption: _filterFor(sort),
    );
  }

  /// The single "All Photos & Videos" virtual album.
  Future<AssetPathEntity?> getAllAlbum(GallerySortOption sort) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      hasAll: true,
      onlyAll: true,
      filterOption: _filterFor(sort),
    );
    return albums.isEmpty ? null : albums.first;
  }

  Future<int> assetCount(AssetPathEntity album) => album.assetCountAsync;

  /// One lazily-loaded page of assets for an album.
  Future<List<AssetEntity>> getAssetsPage(
    AssetPathEntity album, {
    required int page,
    int size = pageSize,
  }) {
    return album.getAssetListPaged(page: page, size: size);
  }

  /// Fetches every asset in [album] — only used for the opt-in "sort by
  /// size" mode, since that requires reading each file's byte length.
  Future<List<AssetEntity>> getAllAssets(AssetPathEntity album) async {
    final count = await album.assetCountAsync;
    return album.getAssetListRange(start: 0, end: count);
  }

  /// Computes file sizes (bounded concurrency) and sorts. Call only when the
  /// user explicitly asks for size-based sorting.
  Future<List<AssetEntity>> sortBySize(
    List<AssetEntity> assets, {
    bool largestFirst = true,
  }) async {
    const batchSize = 12;
    final withSize = <MapEntry<AssetEntity, int>>[];

    for (var i = 0; i < assets.length; i += batchSize) {
      final batch = assets.skip(i).take(batchSize);
      final sizes = await Future.wait(batch.map((a) async {
        try {
          final file = await a.file;
          return await file?.length() ?? 0;
        } catch (_) {
          return 0;
        }
      }));
      final batchList = batch.toList();
      for (var j = 0; j < batchList.length; j++) {
        withSize.add(MapEntry(batchList[j], sizes[j]));
      }
    }

    withSize.sort((a, b) =>
        largestFirst ? b.value.compareTo(a.value) : a.value.compareTo(b.value));
    return withSize.map((e) => e.key).toList();
  }

  /// Permanently deletes assets from MediaStore. Returns the ids that were
  /// actually removed.
  Future<List<String>> deletePermanently(List<String> assetIds) {
    return PhotoManager.editor.deleteWithIds(assetIds);
  }

  Future<void> refreshPathProperties(AssetPathEntity album) =>
      album.fetchPathProperties().then((_) {});

  void clearThumbnailCache() => PhotoManager.clearFileCache();
}
