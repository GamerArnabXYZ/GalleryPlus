import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'app.dart';
import 'core/db/hive_service.dart';
import 'features/trash/data/trash_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Required one-time init for media_kit's native video backend.
  MediaKit.ensureInitialized();

  await HiveService.init();
  // Silently drop anything past the 30-day app-trash window on every launch.
  await TrashRepository().purgeExpired();

  runApp(const ProviderScope(child: GalleryPlusApp()));
}
