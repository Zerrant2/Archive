import 'dart:typed_data';

import 'admin_qr_downloader_stub.dart'
    if (dart.library.html) 'admin_qr_downloader_web.dart'
    as platform;

class AdminQrDownloader {
  const AdminQrDownloader._();

  static Future<bool> downloadPng({
    required Uint8List bytes,
    required String objectId,
  }) {
    return platform.downloadPng(bytes, fileNameForObjectId(objectId));
  }

  static String fileNameForObjectId(String objectId) {
    final normalized = objectId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_-]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return 'retroar_${normalized.isEmpty ? 'object' : normalized}_qr.png';
  }
}
