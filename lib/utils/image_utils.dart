// lib/utils/image_utils.dart

class ImageUtils {
  static const String baseUrl = 'http://172.20.10.2:5000';

  static String buildFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    String cleanPath = imagePath.replaceAll('\\', '/');
    if (cleanPath.startsWith('http')) return cleanPath;
    return '$baseUrl/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
  }
}
