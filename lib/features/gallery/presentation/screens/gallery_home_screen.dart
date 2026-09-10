import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../favorites/presentation/screens/favorites_screen.dart';
import '../../../trash/presentation/screens/trash_screen.dart';
import '../../providers/gallery_providers.dart';
import 'album_detail_screen.dart';
import 'albums_list_screen.dart';

class GalleryHomeScreen extends ConsumerStatefulWidget {
  const GalleryHomeScreen({super.key});

  @override
  ConsumerState<GalleryHomeScreen> createState() => _GalleryHomeScreenState();
}

class _GalleryHomeScreenState extends ConsumerState<GalleryHomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final allAlbumAsync = ref.watch(allAlbumProvider);

    final pages = [
      allAlbumAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load photos: $e')),
        data: (album) => album == null
            ? const Center(child: Text('No photos found on this device.'))
            : AlbumDetailScreen(album: album, title: 'GalleryPlus'),
      ),
      const AlbumsListScreen(),
      const FavoritesScreen(),
      const TrashScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.photo_outlined), selectedIcon: Icon(Icons.photo), label: 'Photos'),
          NavigationDestination(icon: Icon(Icons.photo_album_outlined), selectedIcon: Icon(Icons.photo_album), label: 'Albums'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.delete_outline), selectedIcon: Icon(Icons.delete), label: 'Trash'),
        ],
      ),
    );
  }
}
