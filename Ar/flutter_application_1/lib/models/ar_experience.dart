class ArExperience {
  final bool enabled;
  final String? epochYear;
  final String? glbUrl;
  final String? usdzUrl;
  final String? glbAssetPath;
  final String? usdzAssetPath;
  final double scale;
  final String placement;
  final String? note;

  const ArExperience({
    this.enabled = false,
    this.epochYear,
    this.glbUrl,
    this.usdzUrl,
    this.glbAssetPath,
    this.usdzAssetPath,
    this.scale = 1.0,
    this.placement = 'plane',
    this.note,
  });

  bool get hasExternalModelReference => _hasValue(glbUrl) || _hasValue(usdzUrl);

  bool get hasLocalModelReference =>
      _hasValue(glbAssetPath) || _hasValue(usdzAssetPath);

  bool get hasModelReference =>
      hasExternalModelReference || hasLocalModelReference;

  List<String> get localAssetPaths => [
    if (_hasValue(glbAssetPath)) glbAssetPath!,
    if (_hasValue(usdzAssetPath)) usdzAssetPath!,
  ];

  factory ArExperience.fromJson(Map<String, dynamic> json) {
    return ArExperience(
      enabled: json['enabled'] as bool? ?? true,
      epochYear: _readString(json['epochYear']),
      glbUrl: _readString(json['glbUrl']),
      usdzUrl: _readString(json['usdzUrl']),
      glbAssetPath: _readString(json['glbAssetPath']),
      usdzAssetPath: _readString(json['usdzAssetPath']),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      placement: _readString(json['placement']) ?? 'plane',
      note: _readString(json['note']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      if (_hasValue(epochYear)) 'epochYear': epochYear,
      if (_hasValue(glbUrl)) 'glbUrl': glbUrl,
      if (_hasValue(usdzUrl)) 'usdzUrl': usdzUrl,
      if (_hasValue(glbAssetPath)) 'glbAssetPath': glbAssetPath,
      if (_hasValue(usdzAssetPath)) 'usdzAssetPath': usdzAssetPath,
      'scale': scale,
      'placement': placement,
      if (_hasValue(note)) 'note': note,
    };
  }

  static String? _readString(Object? value) {
    final text = value?.toString().trim();
    return _hasValue(text) ? text : null;
  }

  static bool _hasValue(String? value) => value != null && value.isNotEmpty;
}
