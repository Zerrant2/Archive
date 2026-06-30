import 'package:flutter_application_1/admin/models/admin_heritage_object.dart';
import 'package:flutter_application_1/models/historical_object.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdminHeritageObject', () {
    test('parses Supabase row', () {
      final object = AdminHeritageObject.fromSupabase({
        'id': 'mayak',
        'name': 'Маяк',
        'address': 'Набережная',
        'century': 'XXI век',
        'architecture_type': 'Современная архитектура',
        'latitude': 48.7,
        'longitude': 44.5,
        'short_description': 'Описание',
        'published': true,
      });

      expect(object.id, 'mayak');
      expect(object.name, 'Маяк');
      expect(object.architectureType, 'Современная архитектура');
      expect(object.published, isTrue);
      expect(object.isLocalFallback, isFalse);
    });

    test('maps local historical object as fallback', () {
      final local = HistoricalObject.fromJson({
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
      });

      final object = AdminHeritageObject.fromHistoricalObject(local);

      expect(object.id, 'mayak');
      expect(object.published, isTrue);
      expect(object.isLocalFallback, isTrue);
    });
  });
}
