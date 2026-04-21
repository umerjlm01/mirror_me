import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  /// Compresses the image to reduce upload size and processing time
  static Future<File> compressImage(File file) async {
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);
    if (decodedImage == null) throw Exception('Failed to decode image');

    // Resize if too large
    img.Image resized = decodedImage;
    if (decodedImage.width > 800) {
      resized = img.copyResize(decodedImage, width: 800);
    }

    final compressedBytes = img.encodeJpg(resized, quality: 85);
    final tempDir = await getTemporaryDirectory();
    final targetPath =
        '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(compressedBytes);
    return targetFile;
  }
}
