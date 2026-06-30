import 'package:flutter_application_1/models/historical_object.dart';
import 'package:flutter_application_1/services/historical_experience_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistoricalExperienceService', () {
    test('uses any available panorama as a valid experience', () {
      final object = _object(
        panoramas: [
          {
            'year': '1930',
            'label': 'СССР',
            'imagePath': 'assets/panoramas/missing.jpg',
          },
          {
            'year': '1589',
            'label': 'Основание',
            'imagePath': 'assets/panoramas/mayak_1589.jpg',
          },
        ],
      );

      final availablePanoramas =
          HistoricalExperienceService.availablePanoramasFor(object, {
            'assets/panoramas/mayak_1589.jpg',
          });

      expect(availablePanoramas, hasLength(1));
      expect(availablePanoramas.single.year, '1589');
      expect(
        HistoricalExperienceService.hasAvailableExperience(object, {
          'assets/panoramas/mayak_1589.jpg',
        }),
        isTrue,
      );
    });

    test('uses local 3D model as a valid experience', () {
      final object = _object(
        arExperience: {
          'enabled': true,
          'glbAssetPath': 'assets/models/mayak_test.glb',
        },
      );

      expect(
        HistoricalExperienceService.hasAvailableExperience(object, {
          'assets/models/mayak_test.glb',
        }),
        isTrue,
      );
    });

    test('uses remote panorama URLs as ready experience', () {
      final object = _object(
        panoramas: [
          {
            'year': '2010',
            'label': 'Открытие',
            'imagePath': 'https://example.com/mayak_2010.jpg',
          },
        ],
      );

      final availablePanoramas =
          HistoricalExperienceService.availablePanoramasFor(object, const {});

      expect(availablePanoramas, hasLength(1));
      expect(availablePanoramas.single.isRemoteImage, isTrue);
      expect(
        HistoricalExperienceService.hasAvailableExperience(object, const {}),
        isTrue,
      );
    });

    test('uses epoch-specific 3D models as ready experience', () {
      final object = _object(
        arExperiences: [
          {
            'enabled': true,
            'epochYear': '1589',
            'glbAssetPath': 'assets/models/mayak_1589.glb',
          },
          {
            'enabled': true,
            'epochYear': '1930',
            'glbAssetPath': 'assets/models/mayak_1930.glb',
          },
        ],
      );

      expect(
        HistoricalExperienceService.hasAvailableExperience(object, {
          'assets/models/mayak_1930.glb',
        }),
        isTrue,
      );
      expect(
        object.arExperienceForYear('1930')?.glbAssetPath,
        'assets/models/mayak_1930.glb',
      );
    });
  });
}

HistoricalObject _object({
  List<Map<String, Object?>> panoramas = const [],
  Map<String, Object?>? arExperience,
  List<Map<String, Object?>> arExperiences = const [],
}) {
  final json = <String, Object?>{
    'id': 'mayak',
    'name': 'Маяк',
    'century': 'XXI век',
    'architectureType': 'Современная архитектура',
    'address': 'Волгоград',
    'yearsOfExistence': '2010 - настоящее время',
    'sources': 'Архив',
    'shortDescription': 'Кратко',
    'detailedDescription': 'Подробно',
    'imageAsset': 'assets/images/mayak.jpg',
    'latitude': 48.7,
    'longitude': 44.5,
    'simpleQuestions': [],
    'hardQuestions': [],
    'panoramas': panoramas,
  };

  if (arExperience != null) {
    json['arExperience'] = arExperience;
  }
  if (arExperiences.isNotEmpty) {
    json['arExperiences'] = arExperiences;
  }

  return HistoricalObject.fromJson(json);
}
