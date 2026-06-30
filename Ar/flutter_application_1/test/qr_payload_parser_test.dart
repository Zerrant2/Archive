import 'package:flutter_application_1/services/qr_payload_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QrPayloadParser', () {
    test('extracts direct object id', () {
      expect(QrPayloadParser.extractObjectToken('mayak'), 'mayak');
    });

    test('extracts object id from deep link', () {
      expect(
        QrPayloadParser.extractObjectToken('retroar://object/mayak'),
        'mayak',
      );
    });

    test('extracts object id from url query', () {
      expect(
        QrPayloadParser.extractObjectToken(
          'https://example.com/ar?objectId=mayak',
        ),
        'mayak',
      );
    });

    test('extracts object id from url path', () {
      expect(
        QrPayloadParser.extractObjectToken('https://example.com/object/mayak'),
        'mayak',
      );
    });

    test('extracts object id from json payload', () {
      expect(
        QrPayloadParser.extractObjectToken('{"objectId":"mayak"}'),
        'mayak',
      );
    });

    test('returns null for empty payload', () {
      expect(QrPayloadParser.extractObjectToken('   '), isNull);
    });
  });
}
