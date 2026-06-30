import '../../models/historical_object.dart';

class AdminHeritageObject {
  final String id;
  final String name;
  final String address;
  final String century;
  final String architectureType;
  final double latitude;
  final double longitude;
  final String shortDescription;
  final bool published;
  final bool isLocalFallback;

  const AdminHeritageObject({
    required this.id,
    required this.name,
    required this.address,
    required this.century,
    required this.architectureType,
    required this.latitude,
    required this.longitude,
    required this.shortDescription,
    required this.published,
    this.isLocalFallback = false,
  });

  factory AdminHeritageObject.fromSupabase(Map<String, dynamic> json) {
    return AdminHeritageObject(
      id: _readString(json['id']),
      name: _readString(json['name']),
      address: _readString(json['address']),
      century: _readString(json['century']),
      architectureType: _readString(json['architecture_type']),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      shortDescription: _readString(json['short_description']),
      published: json['published'] as bool? ?? false,
    );
  }

  factory AdminHeritageObject.fromHistoricalObject(HistoricalObject object) {
    return AdminHeritageObject(
      id: object.id,
      name: object.name,
      address: object.address,
      century: object.century,
      architectureType: object.architectureType,
      latitude: object.latitude,
      longitude: object.longitude,
      shortDescription: object.shortDescription,
      published: true,
      isLocalFallback: true,
    );
  }

  Map<String, dynamic> toSupabasePayload({String? createdBy}) {
    final payload = <String, dynamic>{
      'id': id,
      'name': name,
      'address': address,
      'century': century,
      'architecture_type': architectureType,
      'latitude': latitude,
      'longitude': longitude,
      'short_description': shortDescription,
      'published': published,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (createdBy != null) {
      payload['created_by'] = createdBy;
    }

    return payload;
  }

  AdminHeritageObject copyWith({
    String? id,
    String? name,
    String? address,
    String? century,
    String? architectureType,
    double? latitude,
    double? longitude,
    String? shortDescription,
    bool? published,
    bool? isLocalFallback,
  }) {
    return AdminHeritageObject(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      century: century ?? this.century,
      architectureType: architectureType ?? this.architectureType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      shortDescription: shortDescription ?? this.shortDescription,
      published: published ?? this.published,
      isLocalFallback: isLocalFallback ?? this.isLocalFallback,
    );
  }

  static String _readString(Object? value) => value?.toString().trim() ?? '';
}
