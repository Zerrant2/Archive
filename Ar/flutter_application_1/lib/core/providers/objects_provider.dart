// lib/core/providers/objects_provider.dart
import 'package:flutter/foundation.dart';
import '../../data/repositories/objects_repository.dart';
import '../../models/historical_object.dart';

class ObjectsProvider extends ChangeNotifier {
  List<HistoricalObject> _allObjects = [];
  Map<String, HistoricalObject> _objectsMap = {};
  bool _isLoading = false;
  String? _error;

  List<HistoricalObject> get allObjects => List.unmodifiable(_allObjects);
  Map<String, HistoricalObject> get objectsMap => Map.unmodifiable(_objectsMap);
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get objectsCount => _allObjects.length;

  Future<void> loadObjects() async {
    if (_allObjects.isNotEmpty) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allObjects = await ObjectsRepository.loadObjects();
      _objectsMap = {for (var obj in _allObjects) obj.id: obj};
      _error = null;
      if (kDebugMode) {
        debugPrint('Loaded ${_allObjects.length} objects');
      }
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        debugPrint('Error loading objects: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  HistoricalObject? getObjectById(String id) {
    return _objectsMap[id];
  }

  HistoricalObject? getObjectByName(String name) {
    try {
      return _allObjects.firstWhere((obj) => obj.name == name);
    } catch (e) {
      return null;
    }
  }

  List<String> getObjectNames() {
    return _allObjects.map((obj) => obj.name).toList();
  }

  void clearCache() {
    _allObjects = [];
    _objectsMap = {};
    notifyListeners();
  }
}