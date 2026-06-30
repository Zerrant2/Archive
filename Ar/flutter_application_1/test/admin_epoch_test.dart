import 'package:flutter_application_1/admin/models/admin_epoch.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminEpoch', () {
    test('parses Supabase row', () {
      final epoch = AdminEpoch.fromSupabase({
        'id': 'epoch-id',
        'object_id': 'mayak',
        'year': '1930',
        'label': 'Сталинград',
        'description': 'Исторический слой',
        'panorama_url': 'https://example.com/panorama.jpg',
        'panorama_asset_path': null,
        'sort_order': 1930,
        'published': true,
      });

      expect(epoch.id, 'epoch-id');
      expect(epoch.objectId, 'mayak');
      expect(epoch.displayTitle, 'Сталинград');
      expect(epoch.panoramaSource, 'https://example.com/panorama.jpg');
      expect(epoch.sortOrder, 1930);
      expect(epoch.published, isTrue);
    });

    test('creates clean Supabase payload', () {
      final epoch = AdminEpoch(
        objectId: 'old-object',
        year: ' 1589 ',
        label: ' Ранняя эпоха ',
        description: ' ',
        panoramaUrl: ' ',
        panoramaAssetPath: 'assets/panoramas/mayak_1589.jpg',
        sortOrder: 1589,
        published: false,
      );

      final payload = epoch.toSupabasePayload(objectId: 'mayak');

      expect(payload.containsKey('id'), isFalse);
      expect(payload['object_id'], 'mayak');
      expect(payload['year'], '1589');
      expect(payload['label'], 'Ранняя эпоха');
      expect(payload['description'], '');
      expect(payload['panorama_url'], isNull);
      expect(payload['panorama_asset_path'], 'assets/panoramas/mayak_1589.jpg');
      expect(payload['sort_order'], 1589);
      expect(payload['published'], isFalse);
      expect(payload['updated_at'], isA<String>());
    });
  });
}
