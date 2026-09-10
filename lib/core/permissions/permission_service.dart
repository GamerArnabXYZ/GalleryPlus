import 'package:photo_manager/photo_manager.dart';

/// Result of a permission check, simplified for the UI layer.
enum GalleryPermissionStatus {
  /// Full access to all photos/videos.
  authorized,

  /// Android 14+ "select photos" partial access — usable, but the user
  /// should be offered a way to grant more.
  limited,

  /// No access — show the permission-denied screen.
  denied,
}

/// Wraps photo_manager's `requestPermissionExtend`, which already knows how
/// to ask for the right permission on every Android version:
///  - API 26-32  -> READ_EXTERNAL_STORAGE
///  - API 33-34+ -> READ_MEDIA_IMAGES / READ_MEDIA_VIDEO
///  - API 34+    -> READ_MEDIA_VISUAL_USER_SELECTED (partial/limited access)
class PermissionService {
  const PermissionService();

  Future<GalleryPermissionStatus> request() async {
    final PermissionState state = await PhotoManager.requestPermissionExtend();
    switch (state) {
      case PermissionState.authorized:
        return GalleryPermissionStatus.authorized;
      case PermissionState.limited:
        return GalleryPermissionStatus.limited;
      case PermissionState.denied:
      case PermissionState.notDetermined:
      default:
        return GalleryPermissionStatus.denied;
    }
  }

  /// Lets the user pick more photos when access is "limited" (Android 14+).
  Future<void> presentLimitedPicker() => PhotoManager.presentLimited();

  /// Opens the system app-settings screen (for permanently denied access).
  Future<void> openAppSettings() => PhotoManager.openSetting();
}
