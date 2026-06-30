import 'package:flutter_application_1/models/ar_experience.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArExperience', () {
    test('parses external and local model references', () {
      final experience = ArExperience.fromJson({
        'enabled': true,
        'epochYear': '1930',
        'glbUrl': 'https://example.com/nevsky.glb',
        'usdzUrl': 'https://example.com/nevsky.usdz',
        'glbAssetPath': 'assets/models/nevsky.glb',
        'scale': 0.5,
        'placement': 'plane',
        'note': 'AR beta',
      });

      expect(experience.enabled, isTrue);
      expect(experience.epochYear, '1930');
      expect(experience.hasExternalModelReference, isTrue);
      expect(experience.hasLocalModelReference, isTrue);
      expect(experience.hasModelReference, isTrue);
      expect(experience.localAssetPaths, ['assets/models/nevsky.glb']);
      expect(experience.scale, 0.5);
      expect(experience.placement, 'plane');
    });

    test('treats empty strings as absent values', () {
      final experience = ArExperience.fromJson({
        'enabled': true,
        'glbUrl': ' ',
        'usdzAssetPath': '',
      });

      expect(experience.hasModelReference, isFalse);
      expect(experience.localAssetPaths, isEmpty);
    });
  });
}
