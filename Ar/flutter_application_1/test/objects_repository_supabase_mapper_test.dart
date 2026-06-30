import 'package:flutter_application_1/data/repositories/objects_repository.dart';
import 'package:flutter_application_1/models/historical_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ObjectsRepository Supabase mapper', () {
    test(
      'maps published object with epochs, ar asset, and local questions',
      () {
        final local = HistoricalObject.fromJson({
          'id': 'mayak',
          'name': 'Маяк local',
          'century': 'XXI век',
          'architectureType': 'Современная архитектура',
          'address': 'Волгоград',
          'yearsOfExistence': '2010 - настоящее время',
          'sources': 'Архив',
          'shortDescription': 'Кратко local',
          'detailedDescription': 'Подробно local',
          'imageAsset': 'assets/images/mayak.jpg',
          'latitude': 48.7,
          'longitude': 44.5,
          'simpleQuestions': [
            {
              'text': 'Год открытия?',
              'options': ['2010', '2011'],
              'correctIndex': 0,
            },
          ],
          'hardQuestions': [],
          'panoramas': [],
        });

        final objects = ObjectsRepository.mapSupabaseRows(
          objectRows: [
            {
              'id': 'mayak',
              'name': 'Маяк',
              'century': 'XXI век',
              'architecture_type': 'Современная архитектура',
              'address': 'наб. Волги',
              'years_of_existence': '',
              'sources': '',
              'short_description': 'Кратко из Supabase',
              'detailed_description': '',
              'cover_image_asset': '',
              'cover_image_url': '',
              'latitude': 48.7003,
              'longitude': 44.5152,
              'published': true,
            },
          ],
          epochRows: [
            {
              'object_id': 'mayak',
              'year': '2010',
              'label': 'Открытие',
              'panorama_url': 'https://example.com/mayak_2010.jpg',
              'panorama_asset_path': 'assets/panoramas/mayak_2010.jpg',
              'sort_order': 2010,
              'published': true,
            },
          ],
          arAssetRows: [
            {
              'object_id': 'mayak',
              'epoch_year': '',
              'glb_url': 'https://example.com/mayak.glb',
              'usdz_url': '',
              'glb_asset_path': '',
              'usdz_asset_path': '',
              'scale': 0.8,
              'placement': 'plane',
              'published': true,
            },
            {
              'object_id': 'mayak',
              'epoch_year': '2010',
              'glb_url': 'https://example.com/mayak_2010.glb',
              'usdz_url': '',
              'glb_asset_path': '',
              'usdz_asset_path': '',
              'scale': 1.1,
              'placement': 'plane',
              'published': true,
            },
          ],
          localFallbackObjects: [local],
        );

        expect(objects, hasLength(1));
        final object = objects.single;
        expect(object.name, 'Маяк');
        expect(object.yearsOfExistence, local.yearsOfExistence);
        expect(object.sources, local.sources);
        expect(object.detailedDescription, local.detailedDescription);
        expect(object.imageAsset, local.imageAsset);
        expect(object.simpleQuestions, hasLength(1));
        expect(
          object.panoramas.single.imagePath,
          'https://example.com/mayak_2010.jpg',
        );
        expect(object.panoramas.single.isRemoteImage, isTrue);
        expect(object.arExperience?.glbUrl, 'https://example.com/mayak.glb');
        expect(object.arExperience?.scale, 0.8);
        expect(object.arExperiences, hasLength(2));
        expect(
          object.arExperienceForYear('2010')?.glbUrl,
          'https://example.com/mayak_2010.glb',
        );
      },
    );

    test('ignores unpublished rows', () {
      final objects = ObjectsRepository.mapSupabaseRows(
        objectRows: [
          {'id': 'draft', 'name': 'Черновик', 'published': false},
        ],
        epochRows: const [],
        arAssetRows: const [],
      );

      expect(objects, isEmpty);
    });
  });
}
