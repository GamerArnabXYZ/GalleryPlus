import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/gallery/presentation/screens/gallery_home_screen.dart';
import 'shared/widgets/permission_gate.dart';

class GalleryPlusApp extends StatelessWidget {
  const GalleryPlusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GalleryPlus',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const PermissionGate(
        builder: _buildHome,
      ),
    );
  }

  static Widget _buildHome(BuildContext context) => const GalleryHomeScreen();
}
