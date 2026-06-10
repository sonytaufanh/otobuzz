import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  final _uuid = const Uuid();

  /// Pick image from camera or gallery, resize, and save to app directory.
  /// Returns the local file path, or null if cancelled.
  Future<String?> pickAndSaveImage({
    required ImageSource source,
    int maxWidth = 1024,
  }) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth.toDouble(),
      imageQuality: 85,
    );

    if (pickedFile == null) return null;

    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(appDir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final extension = p.extension(pickedFile.path).toLowerCase();
    final fileName = '${_uuid.v4()}$extension';
    final savedPath = p.join(photosDir.path, fileName);

    // Read and resize if needed
    final bytes = await pickedFile.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      // Fallback: just copy the file as-is
      await File(pickedFile.path).copy(savedPath);
      return savedPath;
    }

    img.Image resized = decoded;
    if (decoded.width > maxWidth) {
      resized = img.copyResize(decoded, width: maxWidth);
    }

    final encoded = extension == '.png'
        ? img.encodePng(resized)
        : img.encodeJpg(resized, quality: 85);

    await File(savedPath).writeAsBytes(encoded);
    return savedPath;
  }

  /// Pick image for vehicle (smaller size)
  Future<String?> pickVehiclePhoto({required ImageSource source}) async {
    return pickAndSaveImage(source: source, maxWidth: 800);
  }

  /// Pick image for maintenance proof
  Future<String?> pickMaintenancePhoto({required ImageSource source}) async {
    return pickAndSaveImage(source: source, maxWidth: 1024);
  }

  /// Delete a photo file from storage
  Future<void> deletePhoto(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
