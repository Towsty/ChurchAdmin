import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageCompressionService {
  static Future<File?> compressImage(File imageFile) async {
    // Only compress on mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final String tempPath = '${imageFile.path}_compressed.jpg';
        final result = await FlutterImageCompress.compressAndGetFile(
          imageFile.path,
          tempPath,
          quality: 85,
          minWidth: 500,
          minHeight: 500,
          rotate: 0,
        );

        return result != null ? File(result.path) : null;
      } catch (e) {
        print('Error compressing image: $e');
        return null;
      }
    }

    // Return original file on other platforms
    return imageFile;
  }
}
