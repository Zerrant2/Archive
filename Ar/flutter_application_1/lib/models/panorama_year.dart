// lib/models/panorama_year.dart
class PanoramaYear {
  final String year;
  final String label;
  final String imagePath;

  const PanoramaYear({
    required this.year,
    required this.label,
    required this.imagePath,
  });

  bool get isRemoteImage =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  factory PanoramaYear.fromJson(Map<String, dynamic> json) {
    return PanoramaYear(
      year: json['year'] as String,
      label: json['label'] as String,
      imagePath: json['imagePath'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'year': year, 'label': label, 'imagePath': imagePath};
  }
}
