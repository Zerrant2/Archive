import 'package:flutter_application_1/admin/services/admin_qr_downloader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminQrDownloader', () {
    test('creates safe file names from object ids', () {
      expect(
        AdminQrDownloader.fileNameForObjectId('nevsky_cathedral'),
        'retroar_nevsky_cathedral_qr.png',
      );
      expect(
        AdminQrDownloader.fileNameForObjectId(' Маяк / 2026 '),
        'retroar_2026_qr.png',
      );
      expect(
        AdminQrDownloader.fileNameForObjectId(''),
        'retroar_object_qr.png',
      );
    });
  });
}
