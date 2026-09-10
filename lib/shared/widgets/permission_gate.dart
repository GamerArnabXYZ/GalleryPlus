import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/permissions/permission_service.dart';
import '../../features/gallery/providers/gallery_providers.dart';
import '../../core/theme/app_theme.dart';

/// Wrap any screen that needs media access with this. Shows a proper
/// full-screen request/denied state instead of silently failing.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({super.key, required this.builder});

  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(permissionProvider);

    return status.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) => _DeniedView(
        message: 'Something went wrong requesting permissions.\n$e',
      ),
      data: (status) {
        switch (status) {
          case GalleryPermissionStatus.authorized:
            return builder(context);
          case GalleryPermissionStatus.limited:
            return Column(
              children: [
                const _LimitedBanner(),
                Expanded(child: builder(context)),
              ],
            );
          case GalleryPermissionStatus.denied:
            return const _DeniedView(
              message:
                  'GalleryPlus needs access to your photos and videos to show them here.',
            );
        }
      },
    );
  }
}

class _DeniedView extends ConsumerWidget {
  const _DeniedView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppTheme.spaceLg),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTheme.spaceLg),
              SizedBox(
                width: double.infinity,
                height: AppTheme.minTapTarget,
                child: FilledButton(
                  onPressed: () =>
                      ref.read(permissionProvider.notifier).check(),
                  child: const Text('Grant Access'),
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              SizedBox(
                width: double.infinity,
                height: AppTheme.minTapTarget,
                child: OutlinedButton(
                  onPressed: () =>
                      ref.read(permissionProvider.notifier).openAppSettings(),
                  child: const Text('Open App Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitedBanner extends ConsumerWidget {
  const _LimitedBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd,
            vertical: AppTheme.spaceSm,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: scheme.onSecondaryContainer, size: 20),
              const SizedBox(width: AppTheme.spaceSm),
              Expanded(
                child: Text(
                  'Limited access — only selected photos are visible.',
                  style: TextStyle(color: scheme.onSecondaryContainer),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(permissionProvider.notifier).presentLimitedPicker(),
                child: const Text('Manage'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
