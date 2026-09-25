class HeritageRouteProgress {
  final String routeId;
  final Set<String> visitedObjectIds;
  final DateTime? completedAt;

  const HeritageRouteProgress({
    required this.routeId,
    required this.visitedObjectIds,
    this.completedAt,
  });

  factory HeritageRouteProgress.empty(String routeId) {
    return HeritageRouteProgress(
      routeId: routeId,
      visitedObjectIds: const <String>{},
    );
  }

  factory HeritageRouteProgress.fromJson(Map<String, dynamic> json) {
    final visited = (json['visitedObjectIds'] as List<dynamic>? ?? const [])
        .map((value) => value.toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
    final completedAtText = json['completedAt']?.toString();

    return HeritageRouteProgress(
      routeId: json['routeId']?.toString() ?? '',
      visitedObjectIds: visited,
      completedAt: completedAtText == null
          ? null
          : DateTime.tryParse(completedAtText),
    );
  }

  bool get isCompleted => completedAt != null;

  bool isVisited(String objectId) => visitedObjectIds.contains(objectId);

  int visitedCountFor(Iterable<String> objectIds) {
    return objectIds.where(visitedObjectIds.contains).length;
  }

  Map<String, dynamic> toJson() {
    final visited = visitedObjectIds.toList()..sort();
    return {
      'routeId': routeId,
      'visitedObjectIds': visited,
      'completedAt': completedAt?.toIso8601String(),
    };
  }
}
