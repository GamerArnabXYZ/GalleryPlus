import 'package:hive_flutter/hive_flutter.dart';

import 'models/trash_entry.dart';

/// Box names, centralized so every repository references the same string.
class HiveBoxes {
  HiveBoxes._();
  static const String trash = 'trash_box';
  static const String favorites = 'favorites_box';
}

/// Call once from main() before runApp().
class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    Hive.registerAdapter(TrashEntryAdapter());

    await Future.wait([
      Hive.openBox<TrashEntry>(HiveBoxes.trash),
      Hive.openBox<bool>(HiveBoxes.favorites),
    ]);

    _initialized = true;
  }
}
