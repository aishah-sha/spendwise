// lib/services/image_picker_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();

  // Quality settings
  static const int defaultImageQuality = 85;
  static const double maxWidth = 1200.0;
  static const double maxHeight = 1200.0;

  // ============ MAIN PICKER METHODS ============

  /// Pick a single image from camera
  Future<File?> pickImageFromCamera({
    int quality = defaultImageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: quality,
        maxWidth: maxWidth ?? ImagePickerService.maxWidth,
        maxHeight: maxHeight ?? ImagePickerService.maxHeight,
      );

      if (image == null) return null;
      return await _saveImageToPermanentStorage(image);
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick a single image from gallery
  Future<File?> pickImageFromGallery({
    int quality = defaultImageQuality,
    double? maxWidth,
    double? maxHeight,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
        maxWidth: maxWidth ?? ImagePickerService.maxWidth,
        maxHeight: maxHeight ?? ImagePickerService.maxHeight,
      );

      if (image == null) return null;
      return await _saveImageToPermanentStorage(image);
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick profile image from gallery (with permanent storage)
  Future<String?> pickProfileImageFromGallery({
    int quality = 60,
    double maxSize = 300.0,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxSize,
        maxHeight: maxSize,
        imageQuality: quality,
      );

      if (image == null) return null;

      // Wait a moment to ensure file is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Save to permanent storage
      final savedFile = await _saveImageToPermanentStorage(image);

      if (savedFile != null && await savedFile.exists()) {
        debugPrint('✅ Profile image saved: ${savedFile.path}');
        return savedFile.path;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking profile image from gallery: $e');
      return null;
    }
  }

  /// Pick profile image from camera (with permanent storage)
  Future<String?> pickProfileImageFromCamera({
    int quality = 60,
    double maxSize = 300.0,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxSize,
        maxHeight: maxSize,
        imageQuality: quality,
      );

      if (image == null) return null;

      // Wait a moment to ensure file is ready
      await Future.delayed(const Duration(milliseconds: 100));

      // Save to permanent storage
      final savedFile = await _saveImageToPermanentStorage(image);

      if (savedFile != null && await savedFile.exists()) {
        debugPrint('✅ Profile image saved: ${savedFile.path}');
        return savedFile.path;
      }

      return null;
    } catch (e) {
      debugPrint('Error picking profile image from camera: $e');
      return null;
    }
  }

  /// Pick multiple images from gallery
  Future<List<File>> pickMultipleImages({
    int quality = defaultImageQuality,
    double? maxWidth,
    double? maxHeight,
    int maxCount = 10,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: quality,
        maxWidth: maxWidth ?? ImagePickerService.maxWidth,
        maxHeight: maxHeight ?? ImagePickerService.maxHeight,
      );

      if (images.isEmpty) return [];

      final limitedImages = images.take(maxCount).toList();
      final List<File> savedFiles = [];

      for (final image in limitedImages) {
        final savedFile = await _saveImageToPermanentStorage(image);
        if (savedFile != null) {
          savedFiles.add(savedFile);
        }
      }

      return savedFiles;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  // ============ STORAGE METHODS ============

  /// Save image to app's permanent storage
  Future<File?> _saveImageToPermanentStorage(XFile image) async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDocDir.path}/images');

      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      final String extension = path.extension(image.path);
      final String fileName =
          'img_${DateTime.now().millisecondsSinceEpoch}$extension';
      final String permanentPath = '${imagesDir.path}/$fileName';

      final File tempFile = File(image.path);
      final File permanentFile = await tempFile.copy(permanentPath);

      debugPrint('✅ Image saved to: $permanentPath');
      return permanentFile;
    } catch (e) {
      debugPrint('❌ Error saving image to permanent storage: $e');
      return null;
    }
  }

  // ============ DELETE METHODS ============

  /// Delete an image file
  Future<bool> deleteImage(String imagePath) async {
    try {
      if (imagePath.isEmpty) return false;

      final File imageFile = File(imagePath);
      if (await imageFile.exists()) {
        await imageFile.delete();
        debugPrint('🗑️ Image deleted: $imagePath');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }

  /// Delete multiple images
  Future<int> deleteMultipleImages(List<String> imagePaths) async {
    int deletedCount = 0;
    for (final path in imagePaths) {
      if (await deleteImage(path)) {
        deletedCount++;
      }
    }
    return deletedCount;
  }

  // ============ UTILITY METHODS ============

  /// Check if image file exists
  Future<bool> imageExists(String imagePath) async {
    if (imagePath.isEmpty) return false;
    try {
      return await File(imagePath).exists();
    } catch (e) {
      return false;
    }
  }

  /// Get image file size in bytes
  Future<int?> getImageSize(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get image as bytes
  Future<List<int>?> getImageBytes(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Clear all images from app storage
  Future<int> clearAllImages() async {
    try {
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final Directory imagesDir = Directory('${appDocDir.path}/images');

      if (await imagesDir.exists()) {
        final List<FileSystemEntity> files = await imagesDir.list().toList();
        int deletedCount = 0;

        for (final file in files) {
          if (file is File) {
            await file.delete();
            deletedCount++;
          }
        }

        debugPrint('🗑️ Cleared $deletedCount images from storage');
        return deletedCount;
      }
      return 0;
    } catch (e) {
      debugPrint('❌ Error clearing images: $e');
      return 0;
    }
  }

  // ============ UI METHODS ============

  /// Show image picker options bottom sheet
  Future<File?> showImagePickerOptions({
    required BuildContext context,
    bool isDarkMode = false,
    String? title,
  }) async {
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              if (title != null) ...[
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green, size: 28),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Capture a new photo with your camera',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await pickImageFromCamera();
                  if (context.mounted && selectedImage != null) {
                    Navigator.pop(context, selectedImage);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Colors.blue,
                  size: 28,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Select an existing photo',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImage = await pickImageFromGallery();
                  if (context.mounted && selectedImage != null) {
                    Navigator.pop(context, selectedImage);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    return selectedImage;
  }

  /// Show profile image picker options (FAST - returns path directly)
  Future<String?> showProfileImagePickerOptions({
    required BuildContext context,
    bool isDarkMode = false,
  }) async {
    String? selectedPath;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green, size: 28),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  selectedPath = await pickProfileImageFromCamera();
                  if (context.mounted && selectedPath != null) {
                    Navigator.pop(context, selectedPath);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Colors.blue,
                  size: 28,
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  selectedPath = await pickProfileImageFromGallery();
                  if (context.mounted && selectedPath != null) {
                    Navigator.pop(context, selectedPath);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    return selectedPath;
  }

  /// Show multiple image picker options
  Future<List<File>> showMultipleImagePickerOptions({
    required BuildContext context,
    bool isDarkMode = false,
    int maxCount = 10,
  }) async {
    List<File> selectedImages = [];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Colors.green, size: 28),
                title: Text(
                  'Take a Photo',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImageFromCamera();
                  if (image != null) {
                    selectedImages.add(image);
                  }
                  if (context.mounted) {
                    Navigator.pop(context, selectedImages);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: Colors.blue,
                  size: 28,
                ),
                title: Text(
                  'Choose Multiple Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  'Select up to $maxCount photos',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white60 : Colors.grey[600],
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  selectedImages = await pickMultipleImages(maxCount: maxCount);
                  if (context.mounted) {
                    Navigator.pop(context, selectedImages);
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    return selectedImages;
  }
}
