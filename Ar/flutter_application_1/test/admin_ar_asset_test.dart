import 'package:flutter_application_1/admin/models/admin_ar_asset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminArAsset', () {
    test('parses Supabase row', () {
      final asset = AdminArAsset.fromSupabase({
        'id': 'asset-id',
        'object_id': 'mayak',
        'title': 'Маяк 3D',
        'epoch_year': '1930',
        'glb_url': 'https://example.com/mayak.glb',
        'usdz_url': null,
        'glb_asset_path': '',
        'usdz_asset_path': null,
        'scale': 1.25,
        'placement': 'plane',
        'published': true,
      });

      expect(asset.id, 'asset-id');
      expect(asset.objectId, 'mayak');
      expect(asset.displayTitle, 'Маяк 3D');
      expect(asset.epochYear, '1930');
      expect(asset.modelSource, 'https://example.com/mayak.glb');
      expect(asset.scale, 1.25);
      expect(asset.placement, 'plane');
      expect(asset.published, isTrue);
    });

    test('creates clean Supabase payload', () {
      final asset = AdminArAsset(
        objectId: 'old-object',
        title: ' mayak_default ',
        epochYear: ' 1589 ',
        glbUrl: ' ',
        usdzUrl: 'https://example.com/mayak.usdz',
        glbAssetPath: 'assets/models/mayak.glb',
        usdzAssetPath: '',
        scale: 0.8,
        placement: ' ',
        published: false,
      );

      final payload = asset.toSupabasePayload(objectId: 'mayak');

      expect(payload.containsKey('id'), isFalse);
      expect(payload['object_id'], 'mayak');
      expect(payload['title'], 'mayak_default');
      expect(payload['epoch_year'], '1589');
      expect(payload['glb_url'], isNull);
      expect(payload['usdz_url'], 'https://example.com/mayak.usdz');
      expect(payload['glb_asset_path'], 'assets/models/mayak.glb');
      expect(payload['usdz_asset_path'], isNull);
      expect(payload['scale'], 0.8);
      expect(payload['placement'], 'plane');
      expect(payload['published'], isFalse);
      expect(payload['updated_at'], isA<String>());
    });
  });
}
