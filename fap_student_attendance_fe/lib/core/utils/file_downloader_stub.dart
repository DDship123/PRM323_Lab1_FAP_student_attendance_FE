import 'dart:io';
import 'dart:typed_data';

/// Lưu file trên môi trường Desktop / Native (Windows, macOS, Linux, Android)
Future<bool> saveDownloadedFile(Uint8List bytes, String filename) async {
  try {
    // Thử lấy thư mục Downloads trên Windows/Desktop
    String? downloadsDir;
    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        downloadsDir = '$userProfile\\Downloads';
      }
    } else {
      final home = Platform.environment['HOME'];
      if (home != null) {
        downloadsDir = '$home/Downloads';
      }
    }

    final targetDir = downloadsDir != null && Directory(downloadsDir).existsSync()
        ? Directory(downloadsDir)
        : Directory.current;

    final filePath = '${targetDir.path}${Platform.pathSeparator}$filename';
    final file = File(filePath);
    await file.writeAsBytes(bytes);
    return true;
  } catch (e) {
    return false;
  }
}
