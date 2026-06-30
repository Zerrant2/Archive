class AdminArAsset {
  final String? id;
  final String objectId;
  final String title;
  final String? epochYear;
  final String? glbUrl;
  final String? usdzUrl;
  final String? glbAssetPath;
  final String? usdzAssetPath;
  final double scale;
  final String placement;
  final bool published;

  const AdminArAsset({
    this.id,
    required this.objectId,
    required this.title,
    this.epochYear,
    this.glbUrl,
    this.usdzUrl,
    this.glbAssetPath,
    this.usdzAssetPath,
    required this.scale,
    required this.placement,
    required this.published,
  });

  factory AdminArAsset.fromSupabase(Map<String, dynamic> json) {
    return AdminArAsset(
      id: _readNullableString(json['id']),
      objectId: _readString(json['object_id']),
      title: _readString(json['title']),
      epochYear: _readNullableString(json['epoch_year']),
      glbUrl: _readNullableString(json['glb_url']),
      usdzUrl: _readNullableString(json['usdz_url']),
      glbAssetPath: _readNullableString(json['glb_asset_path']),
      usdzAssetPath: _readNullableString(json['usdz_asset_path']),
      scale: _readDouble(json['scale']),
      placement: _readString(json['placement'], fallback: 'plane'),
      published: json['published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabasePayload({required String objectId}) {
    final payload = <String, dynamic>{
      'object_id': objectId,
      'title': title.trim(),
      'epoch_year': _emptyToNull(epochYear),
      'glb_url': _emptyToNull(glbUrl),
      'usdz_url': _emptyToNull(usdzUrl),
      'glb_asset_path': _emptyToNull(glbAssetPath),
      'usdz_asset_path': _emptyToNull(usdzAssetPath),
      'scale': scale,
      'placement': placement.trim().isEmpty ? 'plane' : placement.trim(),
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final cleanId = id?.trim();
    if (cleanId != null && cleanId.isNotEmpty) {
      payload['id'] = cleanId;
    }

    return payload;
  }

  bool get hasModelReference => modelSource.isNotEmpty;

  String get displayTitle {
    final cleanTitle = title.trim();
    return cleanTitle.isEmpty ? 'Новый 3D ассет' : cleanTitle;
  }

  String get modelSource {
    for (final value in [glbUrl, usdzUrl, glbAssetPath, usdzAssetPath]) {
      final text = value?.trim();
      if (text != null && text.isNotEmpty) return text;
    }
    return '';
  }

  static String _readString(Object? value, {String fallback = ''}) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? fallback : text;
  }

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static double _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 1.0;
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
