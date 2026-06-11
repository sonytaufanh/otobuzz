import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class ImageUtils {
  static const _uuid = Uuid();

  /// Compress an image file by resizing and reducing quality.
  /// Returns the compressed file saved to the app's documents directory.
  static Future<File> compressImage(
    File image, {
    int maxWidth = 1024,
    int quality = 80,
  }) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      // Cannot decode, return original
      return image;
    }

    img.Image resized = decoded;
    if (decoded.width > maxWidth) {
      resized = img.copyResize(decoded, width: maxWidth);
    }

    final extension = p.extension(image.path).toLowerCase();
    final encoded = extension == '.png'
        ? img.encodePng(resized, level: 6)
        : img.encodeJpg(resized, quality: quality);

    final appDir = await getApplicationDocumentsDirectory();
    final compressedDir = Directory(p.join(appDir.path, 'photos'));
    if (!await compressedDir.exists()) {
      await compressedDir.create(recursive: true);
    }

    final fileName = '${_uuid.v4()}$extension';
    final outputPath = p.join(compressedDir.path, fileName);
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(encoded);

    return outputFile;
  }
}
