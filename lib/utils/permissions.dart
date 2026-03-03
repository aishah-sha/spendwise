import 'package:permission_handler/permission_handler.dart';

class PermissionHandler {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  static Future<bool> requestGalleryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  static Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  static Future<bool> checkGalleryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }
}
