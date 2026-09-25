import 'dart:typed_data';
import 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart' as impl;

export 'file_downloader_stub.dart'
    if (dart.library.html) 'file_downloader_web.dart';

class FileDownloader {
  static Future<bool> downloadBytes(Uint8List bytes, String filename) {
    return impl.saveDownloadedFile(bytes, filename);
  }
}
