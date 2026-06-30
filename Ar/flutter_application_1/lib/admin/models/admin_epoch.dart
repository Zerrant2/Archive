class AdminEpoch {
  final String? id;
  final String objectId;
  final String year;
  final String label;
  final String description;
  final String? panoramaUrl;
  final String? panoramaAssetPath;
  final int sortOrder;
  final bool published;

  const AdminEpoch({
    this.id,
    required this.objectId,
    required this.year,
    required this.label,
    required this.description,
    this.panoramaUrl,
    this.panoramaAssetPath,
    required this.sortOrder,
    required this.published,
  });

  factory AdminEpoch.fromSupabase(Map<String, dynamic> json) {
    return AdminEpoch(
      id: _readNullableString(json['id']),
      objectId: _readString(json['object_id']),
      year: _readString(json['year']),
      label: _readString(json['label']),
      description: _readString(json['description']),
      panoramaUrl: _readNullableString(json['panorama_url']),
      panoramaAssetPath: _readNullableString(json['panorama_asset_path']),
      sortOrder: _readInt(json['sort_order']),
      published: json['published'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toSupabasePayload({required String objectId}) {
    final payload = <String, dynamic>{
      'object_id': objectId,
      'year': year.trim(),
      'label': label.trim(),
      'description': description.trim(),
      'panorama_url': _emptyToNull(panoramaUrl),
      'panorama_asset_path': _emptyToNull(panoramaAssetPath),
      'sort_order': sortOrder,
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    final cleanId = id?.trim();
    if (cleanId != null && cleanId.isNotEmpty) {
      payload['id'] = cleanId;
    }

    return payload;
  }

  String get displayTitle {
    final cleanLabel = label.trim();
    if (cleanLabel.isNotEmpty) return cleanLabel;
    return year.trim().isEmpty ? 'Новая эпоха' : year.trim();
  }

  String get panoramaSource {
    final cleanUrl = panoramaUrl?.trim();
    if (cleanUrl != null && cleanUrl.isNotEmpty) return cleanUrl;
    return panoramaAssetPath?.trim() ?? '';
  }

  AdminEpoch copyWith({
    String? id,
    String? objectId,
    String? year,
    String? label,
    String? description,
    String? panoramaUrl,
    String? panoramaAssetPath,
    int? sortOrder,
    bool? published,
  }) {
    return AdminEpoch(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      year: year ?? this.year,
      label: label ?? this.label,
      description: description ?? this.description,
      panoramaUrl: panoramaUrl ?? this.panoramaUrl,
      panoramaAssetPath: panoramaAssetPath ?? this.panoramaAssetPath,
      sortOrder: sortOrder ?? this.sortOrder,
      published: published ?? this.published,
    );
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';

  static String? _readNullableString(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String? _emptyToNull(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
