import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/utils/image_utils.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  /// Pick image from camera or gallery, resize, and save to app directory.
  /// Returns the local file path, or null if cancelled.
  Future<String?> pickAndSaveImage({
    required ImageSource source,
    int maxWidth = 1024,
    int quality = 80,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      imageQuality: quality,
    );

    if (pickedFile == null) return null;

    // Use ImageUtils for compression
    final pickedFileObj = File(pickedFile.path);
    final compressed = await ImageUtils.compressImage(
      pickedFileObj,
      maxWidth: maxWidth,
      quality: quality,
    );

    return compressed.path;
  }

  /// Pick image for vehicle (smaller size)
  Future<String?> pickVehiclePhoto({required ImageSource source}) async {
    return pickAndSaveImage(source: source, maxWidth: 800, quality: 80);
  }

  /// Pick image for maintenance proof
  Future<String?> pickMaintenancePhoto({required ImageSource source}) async {
    return pickAndSaveImage(source: source, maxWidth: 1024, quality: 80);
  }

  /// Delete a photo file from storage
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
