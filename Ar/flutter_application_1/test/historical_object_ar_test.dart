import 'package:flutter_application_1/models/historical_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('HistoricalObject parses optional AR experience', () {
    final object = HistoricalObject.fromJson({
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
      'panoramas': [],
      'arExperience': {
        'enabled': true,
        'glbAssetPath': 'assets/models/mayak_test.glb',
        'placement': 'local-preview',
      },
    });

    expect(object.arExperience, isNotNull);
    expect(object.arExperience!.enabled, isTrue);
    expect(object.arExperience!.glbAssetPath, 'assets/models/mayak_test.glb');
    expect(object.arExperience!.hasLocalModelReference, isTrue);
    expect(object.arExperience!.placement, 'local-preview');
  });

  test('HistoricalObject selects AR experience by epoch year', () {
    final object = HistoricalObject.fromJson({
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
      'panoramas': [],
      'arExperiences': [
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
    });

    expect(object.arExperiences, hasLength(2));
    expect(
      object.arExperienceForYear('1930')?.glbAssetPath,
      'assets/models/mayak_1930.glb',
    );
  });
}
