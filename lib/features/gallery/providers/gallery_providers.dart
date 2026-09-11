import 'package:flutter_riverpod/flutter_riverpod.dart';
// StateProvider/StateNotifier/StateNotifierProvider moved to "legacy" in
// Riverpod 3.0 — still fully supported, just needs this explicit import.
import 'package:flutter_riverpod/legacy.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/permissions/permission_service.dart';
import '../../favorites/data/favorites_repository.dart';
import '../../trash/data/trash_repository.dart';
import '../data/gallery_repository.dart';
import '../data/media_delete_service.dart';

// ---- Repositories / services (plain DI, no lifecycle needed) ----

final galleryRepositoryProvider =
    Provider<GalleryRepository>((ref) => const GalleryRepository());

final trashRepositoryProvider =
    Provider<TrashRepository>((ref) => TrashRepository());

final favoritesRepositoryProvider =
    Provider<FavoritesRepository>((ref) => FavoritesRepository());

final permissionServiceProvider =
    Provider<PermissionService>((ref) => const PermissionService());

final mediaDeleteServiceProvider = Provider<MediaDeleteService>((ref) {
  return MediaDeleteService(
    galleryRepository: ref.watch(galleryRepositoryProvider),
    trashRepository: ref.watch(trashRepositoryProvider),
  );
});

// ---- Permission state ----

class PermissionNotifier extends StateNotifier<AsyncValue<GalleryPermissionStatus>> {
  PermissionNotifier(this._service) : super(const AsyncValue.loading()) {
    check();
  }

  final PermissionService _service;

  Future<void> check() async {
    state = const AsyncValue.loading();
    try {
      final status = await _service.request();
      state = AsyncValue.data(status);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> presentLimitedPicker() async {
    await _service.presentLimitedPicker();
    await check();
  }

  Future<void> openAppSettings() => _service.openAppSettings();
}

final permissionProvider =
    StateNotifierProvider<PermissionNotifier, AsyncValue<GalleryPermissionStatus>>(
  (ref) => PermissionNotifier(ref.watch(permissionServiceProvider)),
);

// ---- Sorting ----

final sortOptionProvider =
    StateProvider<GallerySortOption>((ref) => GallerySortOption.dateNewest);

// ---- Albums ----

final albumsProvider = FutureProvider<List<AssetPathEntity>>((ref) {
  final sort = ref.watch(sortOptionProvider);
  return ref.watch(galleryRepositoryProvider).getAlbums(sort);
});

final allAlbumProvider = FutureProvider<AssetPathEntity?>((ref) {
  final sort = ref.watch(sortOptionProvider);
  return ref.watch(galleryRepositoryProvider).getAllAlbum(sort);
});
