import 'dart:convert';

class QrPayloadParser {
  const QrPayloadParser._();

  static String? extractObjectToken(String rawPayload) {
    final payload = rawPayload.trim();
    if (payload.isEmpty) return null;

    final jsonToken = _extractFromJson(payload);
    if (jsonToken != null) return jsonToken;

    final uriToken = _extractFromUri(payload);
    if (uriToken != null) return uriToken;

    return payload;
  }

  static String? _extractFromJson(String payload) {
    if (!payload.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return null;

      return _firstNonEmptyString([
        decoded['objectId'],
        decoded['object_id'],
        decoded['id'],
        decoded['slug'],
        decoded['objectName'],
        decoded['name'],
      ]);
    } catch (_) {
      return null;
    }
  }

  static String? _extractFromUri(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri == null || (!uri.hasScheme && !payload.contains('/'))) return null;

    final queryToken = _firstNonEmptyString([
      uri.queryParameters['objectId'],
      uri.queryParameters['object_id'],
      uri.queryParameters['id'],
      uri.queryParameters['slug'],
      uri.queryParameters['name'],
    ]);
    if (queryToken != null) return queryToken;

    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList();
    if (segments.isEmpty) return null;

    final objectIndex = segments.indexWhere((segment) {
      final normalized = segment.toLowerCase();
      return normalized == 'object' || normalized == 'objects';
    });

    if (objectIndex >= 0 && objectIndex + 1 < segments.length) {
      return Uri.decodeComponent(segments[objectIndex + 1]).trim();
    }

    if (uri.scheme == 'retroar' || uri.scheme == 'arhiv') {
      return Uri.decodeComponent(segments.last).trim();
    }

    return null;
  }

  static String? _firstNonEmptyString(List<Object?> values) {
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    return null;
  }
}
