// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/models/heritage_route.dart';
import '../core/models/heritage_route_progress.dart';
import '../core/models/nearby_place.dart';
import '../core/providers/objects_provider.dart';
import '../core/services/heritage_route_progress_service.dart';
import '../core/services/heritage_route_service.dart';
import '../core/services/nearby_places_service.dart';
import '../data/repositories/heritage_routes_repository.dart';
import '../models/historical_object.dart';
import '../theme/app_colors.dart';
import '../theme/app_decorations.dart';
import 'object_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late MapController _mapController;
  final _nearbyPlacesService = NearbyPlacesService();
  final _routesRepository = HeritageRoutesRepository();
  final _routeProgressService = const HeritageRouteProgressService();

  HistoricalObject? _selectedObject;
  NearbyPlace? _selectedNearbyPlace;
  HeritageRoute? _selectedRoute;
  List<NearbyPlace> _nearbyPlaces = const [];
  NearbyPlaceCategory? _selectedNearbyCategory;
  bool _showNearbyPanel = false;
  bool _showRoutesPanel = false;
  bool _isNearbyLoading = false;
  bool _isRouteCatalogLoading = true;
  bool _isSavingRouteProgress = false;
  int _currentRouteStep = 0;
  String? _nearbyError;
  List<HeritageRoute> _routeTemplates = const [];
  Map<String, HeritageRouteProgress> _routeProgressById = const {};

  final LatLng _volgogradCenter = const LatLng(48.7186, 44.5133);
  LatLng _nearbyCenter = const LatLng(48.7186, 44.5133);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObjectsProvider>().loadObjects();
    });
    _loadRouteState();
  }

  Future<void> _loadRouteState() async {
    final templates = await _routesRepository.loadRoutes();
    final progress = await _routeProgressService.loadAll();
    if (!mounted) return;

    setState(() {
      _routeTemplates = templates;
      _routeProgressById = progress;
      _isRouteCatalogLoading = false;
    });
  }

  LatLng get _currentNearbySearchCenter {
    final selected = _selectedObject;
    if (selected != null) {
      return LatLng(selected.latitude, selected.longitude);
    }
    return _volgogradCenter;
  }

  Future<void> _toggleNearbyPanel() async {
    if (_showNearbyPanel) {
      setState(() {
        _showNearbyPanel = false;
        _selectedNearbyPlace = null;
        _nearbyPlaces = const [];
        _nearbyError = null;
      });
      return;
    }

    final searchCenter = _currentNearbySearchCenter;
    setState(() {
      _showNearbyPanel = true;
      _showRoutesPanel = false;
      _nearbyCenter = searchCenter;
      _selectedObject = null;
      _selectedNearbyPlace = null;
    });
    await _loadNearbyPlaces();
  }

  Future<void> _loadNearbyPlaces({NearbyPlaceCategory? category}) async {
    setState(() {
      _isNearbyLoading = true;
      _nearbyError = null;
      _selectedNearbyCategory = category;
    });

    try {
      final places = await _nearbyPlacesService.getNearbyPlaces(
        center: _nearbyCenter,
        radiusKm: 2.5,
        category: category,
      );

      if (!mounted) return;
      setState(() {
        _nearbyPlaces = places;
        _isNearbyLoading = false;
        _nearbyError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _nearbyPlaces = const [];
        _isNearbyLoading = false;
        _nearbyError = 'Не удалось загрузить места рядом';
      });
    }
  }

  void _selectNearbyPlace(NearbyPlace place) {
    _mapController.move(place.position, 16);
    setState(() {
      _selectedNearbyPlace = place;
      _selectedObject = null;
      _showNearbyPanel = true;
      _showRoutesPanel = false;
    });
  }

  void _toggleRoutesPanel() {
    setState(() {
      _showRoutesPanel = !_showRoutesPanel;
      if (_showRoutesPanel) {
        _showNearbyPanel = false;
        _selectedNearbyPlace = null;
        _selectedObject = null;
      }
    });
  }

  void _selectRoute(HeritageRoute route, List<HistoricalObject> objects) {
    final points = HeritageRouteService.routePoints(route, objects);
    final center = HeritageRouteService.routeCenter(points);
    final progress = _routeProgressById[route.id];
    final firstUnvisitedIndex = route.objectIds.indexWhere(
      (objectId) => progress?.isVisited(objectId) != true,
    );

    setState(() {
      _selectedRoute = route;
      _currentRouteStep = firstUnvisitedIndex < 0 ? 0 : firstUnvisitedIndex;
      _showRoutesPanel = false;
      _showNearbyPanel = false;
      _selectedObject = null;
      _selectedNearbyPlace = null;
    });

    if (points.isNotEmpty) {
      _mapController.move(center, 13.4);
    }
  }

  Future<void> _toggleRouteStopVisited(
    HeritageRoute route,
    HistoricalObject stop,
  ) async {
    if (_isSavingRouteProgress) return;

    final current =
        _routeProgressById[route.id] ?? HeritageRouteProgress.empty(route.id);
    final wasCompleted = current.isCompleted;
    setState(() => _isSavingRouteProgress = true);

    try {
      final updated = await _routeProgressService.toggleVisited(
        route: route,
        objectId: stop.id,
        current: current,
      );
      if (!mounted) return;

      setState(() {
        _routeProgressById = {..._routeProgressById, route.id: updated};
        _isSavingRouteProgress = false;
      });

      if (!wasCompleted && updated.isCompleted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Маршрут «${route.name}» завершен'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSavingRouteProgress = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось сохранить прогресс маршрута')),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _selectedRoute = null;
      _currentRouteStep = 0;
      _selectedObject = null;
    });
  }

  void _focusRouteStop(
    int index,
    List<HistoricalObject> routeStops, {
    bool openObject = false,
  }) {
    if (index < 0 || index >= routeStops.length) return;

    final object = routeStops[index];
    _mapController.move(LatLng(object.latitude, object.longitude), 16);
    setState(() {
      _currentRouteStep = index;
      _selectedObject = openObject ? object : null;
      _selectedNearbyPlace = null;
      _showNearbyPanel = false;
      _showRoutesPanel = false;
    });
  }

  HeritageRoute? _activeRoute(List<HeritageRoute> routes) {
    final selectedRoute = _selectedRoute;
    if (selectedRoute == null) return null;

    for (final route in routes) {
      if (route.id == selectedRoute.id) return route;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = context.watch<ObjectsProvider>();
    final objects = objectsProvider.allObjects;
    final routes = _isRouteCatalogLoading
        ? <HeritageRoute>[]
        : HeritageRouteService.buildRoutes(objects, templates: _routeTemplates);
    final activeRoute = _activeRoute(routes);
    final routePoints = activeRoute == null
        ? <LatLng>[]
        : HeritageRouteService.routePoints(activeRoute, objects);
    final routeStops = activeRoute == null
        ? <HistoricalObject>[]
        : HeritageRouteService.routeObjects(activeRoute, objects);
    final activeRouteProgress = activeRoute == null
        ? null
        : _routeProgressById[activeRoute.id] ??
              HeritageRouteProgress.empty(activeRoute.id);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.beigeBackground,
      body: Column(
        children: [
          _MapHeader(
            isNearbyActive: _showNearbyPanel,
            isRouteActive: _showRoutesPanel || activeRoute != null,
            onToggleNearby: _toggleNearbyPanel,
            onToggleRoutes: _toggleRoutesPanel,
          ),

          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _volgogradCenter,
                    initialZoom: 14.0,
                    minZoom: 10.0,
                    maxZoom: 18.0,
                    onTap: (_, _) {
                      setState(() {
                        _selectedObject = null;
                      });
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.histoar',
                    ),

                    if (routePoints.length > 1)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: AppColors.darkRed,
                            strokeWidth: 5,
                          ),
                        ],
                      ),

                    MarkerLayer(
                      markers: objects.map((object) {
                        return Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(object.latitude, object.longitude),
                          child: GestureDetector(
                            onTap: () {
                              final routeIndex = routeStops.indexWhere(
                                (routeObject) => routeObject.id == object.id,
                              );
                              setState(() {
                                _selectedObject = object;
                                _selectedNearbyPlace = null;
                                _showNearbyPanel = false;
                                _showRoutesPanel = false;
                                if (routeIndex != -1) {
                                  _currentRouteStep = routeIndex;
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.darkRed,
                                size: 36,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    if (routeStops.isNotEmpty)
                      MarkerLayer(
                        markers: routeStops.indexed.map((entry) {
                          final index = entry.$1;
                          final object = entry.$2;
                          return Marker(
                            width: 34,
                            height: 34,
                            point: LatLng(object.latitude, object.longitude),
                            child: GestureDetector(
                              onTap: () => _focusRouteStop(
                                index,
                                routeStops,
                                openObject: true,
                              ),
                              child: _RouteStopMarker(
                                index: index,
                                isActive: index == _currentRouteStep,
                                isVisited:
                                    activeRouteProgress?.isVisited(object.id) ??
                                    false,
                                color:
                                    activeRoute?.theme.color ??
                                    AppColors.darkRed,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    if (_nearbyPlaces.isNotEmpty)
                      MarkerLayer(
                        markers: _nearbyPlaces.map((place) {
                          return Marker(
                            width: 38,
                            height: 38,
                            point: place.position,
                            child: GestureDetector(
                              onTap: () => _selectNearbyPlace(place),
                              child: _NearbyPlaceMarker(place: place),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),

                if (_selectedObject != null && !_showNearbyPanel)
                  Positioned(
                    bottom: 20 + bottomInset,
                    left: 16,
                    right: 16,
                    child: _LocationCard(
                      object: _selectedObject!,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ObjectDetailScreen(
                              objectName: _selectedObject!.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_selectedNearbyPlace != null && !_showNearbyPanel)
                  Positioned(
                    bottom: 20 + bottomInset,
                    left: 16,
                    right: 16,
                    child: _NearbyPlaceCompactCard(
                      place: _selectedNearbyPlace!,
                      onClose: () {
                        setState(() {
                          _selectedNearbyPlace = null;
                        });
                      },
                    ),
                  ),
                if (_showRoutesPanel)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _RoutesPanel(
                      routes: routes,
                      selectedRoute: activeRoute,
                      progressByRouteId: _routeProgressById,
                      isLoading: _isRouteCatalogLoading,
                      bottomInset: bottomInset,
                      onClose: _toggleRoutesPanel,
                      onRouteTap: (route) => _selectRoute(route, objects),
                    ),
                  ),
                if (activeRoute != null &&
                    activeRouteProgress != null &&
                    !_showRoutesPanel &&
                    !_showNearbyPanel &&
                    _selectedObject == null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 14 + bottomInset,
                    child: _RouteProgressPanel(
                      route: activeRoute,
                      stops: routeStops,
                      progress: activeRouteProgress,
                      currentIndex: _currentRouteStep,
                      isSavingProgress: _isSavingRouteProgress,
                      onClose: _clearRoute,
                      onStopTap: (index) => _focusRouteStop(index, routeStops),
                      onOpenStop: (index) =>
                          _focusRouteStop(index, routeStops, openObject: true),
                      onToggleVisited: (index) => _toggleRouteStopVisited(
                        activeRoute,
                        routeStops[index],
                      ),
                    ),
                  ),
                if (_showNearbyPanel)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _NearbyPlacesPanel(
                      places: _nearbyPlaces,
                      isLoading: _isNearbyLoading,
                      errorText: _nearbyError,
                      selectedCategory: _selectedNearbyCategory,
                      bottomInset: bottomInset,
                      onCategoryChanged: (category) {
                        _loadNearbyPlaces(category: category);
                      },
                      onShowAll: () {
                        _loadNearbyPlaces();
                      },
                      onClose: _toggleNearbyPanel,
                      onPlaceTap: _selectNearbyPlace,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  final bool isNearbyActive;
  final bool isRouteActive;
  final VoidCallback onToggleNearby;
  final VoidCallback onToggleRoutes;

  const _MapHeader({
    required this.isNearbyActive,
    required this.isRouteActive,
    required this.onToggleNearby,
    required this.onToggleRoutes,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.viewPaddingOf(context).top;

    return Container(
      width: double.infinity,
      height: 105 + topInset,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            top: 33 + topInset,
            child: const Text(
              "Карта мест",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 66 + topInset,
            child: const Text(
              "Исторические объекты Волгограда",
              style: TextStyle(
                color: Color(0xFFBCB0B0),
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          Positioned(
            right: 116,
            top: 18 + topInset,
            child: GestureDetector(
              onTap: onToggleRoutes,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isRouteActive
                      ? AppColors.whiteText
                      : AppColors.whiteText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.route,
                  color: isRouteActive
                      ? AppColors.primaryRed
                      : AppColors.whiteText,
                  size: 22,
                ),
              ),
            ),
          ),
          Positioned(
            right: 68,
            top: 18 + topInset,
            child: GestureDetector(
              onTap: onToggleNearby,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isNearbyActive
                      ? AppColors.whiteText
                      : AppColors.whiteText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.explore,
                  color: isNearbyActive
                      ? AppColors.primaryRed
                      : AppColors.whiteText,
                  size: 22,
                ),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: 18 + topInset,
            child: GestureDetector(
              onTap: () {
                final mapState = context
                    .findAncestorStateOfType<_MapScreenState>();
                mapState?._mapController.move(
                  const LatLng(48.7186, 44.5133),
                  14.0,
                );
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.whiteText.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.my_location,
                  color: AppColors.whiteText,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final HistoricalObject object;
  final VoidCallback onTap;

  const _LocationCard({required this.object, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryRed.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: AppDecorations.redGradientSquare,
              child: const Icon(
                Icons.account_balance,
                color: AppColors.whiteText,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    object.name,
                    style: const TextStyle(
                      color: AppColors.whiteText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    object.century,
                    style: const TextStyle(
                      color: Color(0xFFBCB0B0),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.whiteText.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: AppColors.whiteText,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStopMarker extends StatelessWidget {
  final int index;
  final bool isActive;
  final bool isVisited;
  final Color color;

  const _RouteStopMarker({
    required this.index,
    required this.isActive,
    required this.isVisited,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isVisited
            ? const Color(0xFF2E7D32)
            : isActive
            ? color
            : AppColors.whiteText,
        shape: BoxShape.circle,
        border: Border.all(
          color: isVisited ? const Color(0xFF2E7D32) : color,
          width: isActive ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: isVisited
            ? const Icon(Icons.check, color: AppColors.whiteText, size: 18)
            : Text(
                '${index + 1}',
                style: TextStyle(
                  color: isActive ? AppColors.whiteText : color,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Montserrat',
                ),
              ),
      ),
    );
  }
}

class _RoutesPanel extends StatelessWidget {
  final List<HeritageRoute> routes;
  final HeritageRoute? selectedRoute;
  final Map<String, HeritageRouteProgress> progressByRouteId;
  final bool isLoading;
  final double bottomInset;
  final VoidCallback onClose;
  final ValueChanged<HeritageRoute> onRouteTap;

  const _RoutesPanel({
    required this.routes,
    required this.selectedRoute,
    required this.progressByRouteId,
    required this.isLoading,
    required this.bottomInset,
    required this.onClose,
    required this.onRouteTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 316 + bottomInset,
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.beigeBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyBackground,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Маршруты',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.primaryRed),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (routes.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Для маршрута нужно минимум два объекта на карте',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.blueText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return _RouteCard(
                    route: route,
                    isSelected: selectedRoute?.id == route.id,
                    progress: progressByRouteId[route.id],
                    onTap: () => onRouteTap(route),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final HeritageRoute route;
  final bool isSelected;
  final HeritageRouteProgress? progress;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.isSelected,
    required this.progress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = route.theme.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 238,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.whiteText,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    progress?.isCompleted == true
                        ? Icons.check
                        : route.theme.icon,
                    color: progress?.isCompleted == true
                        ? const Color(0xFF2E7D32)
                        : color,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    route.theme.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              route.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 6),
            Text(
              route.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.blueText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _RouteMetric(
                  icon: Icons.place,
                  text: '${route.pointsCount}',
                  color: color,
                ),
                _RouteMetric(
                  icon: Icons.directions_walk,
                  text: _formatDistance(route.distanceKm),
                  color: color,
                ),
                _RouteMetric(
                  icon: Icons.schedule,
                  text: '${route.durationMinutes} мин',
                  color: color,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteMetric extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _RouteMetric({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteProgressPanel extends StatelessWidget {
  final HeritageRoute route;
  final List<HistoricalObject> stops;
  final HeritageRouteProgress progress;
  final int currentIndex;
  final bool isSavingProgress;
  final VoidCallback onClose;
  final ValueChanged<int> onStopTap;
  final ValueChanged<int> onOpenStop;
  final ValueChanged<int> onToggleVisited;

  const _RouteProgressPanel({
    required this.route,
    required this.stops,
    required this.progress,
    required this.currentIndex,
    required this.isSavingProgress,
    required this.onClose,
    required this.onStopTap,
    required this.onOpenStop,
    required this.onToggleVisited,
  });

  @override
  Widget build(BuildContext context) {
    if (stops.isEmpty) return const SizedBox.shrink();

    final color = route.theme.color;
    final safeIndex = currentIndex.clamp(0, stops.length - 1).toInt();
    final stop = stops[safeIndex];
    final hasPrevious = safeIndex > 0;
    final hasNext = safeIndex < stops.length - 1;
    final visitedCount = progress.visitedCountFor(route.objectIds);
    final completion = stops.isEmpty ? 0.0 : visitedCount / stops.length;
    final isCurrentVisited = progress.isVisited(stop.id);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.whiteText.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  route.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.primaryRed),
                tooltip: 'Закрыть маршрут',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${safeIndex + 1}/${stops.length} • ${stop.name}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.blueText,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 6,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: progress.isCompleted
                        ? const Color(0xFF2E7D32)
                        : color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$visitedCount/${stops.length}',
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _RouteNavButton(
                icon: Icons.chevron_left,
                isEnabled: hasPrevious,
                onTap: () => onStopTap(safeIndex - 1),
              ),
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: stops.length,
                    itemBuilder: (context, index) {
                      final isActive = index == safeIndex;
                      return GestureDetector(
                        onTap: () => onStopTap(index),
                        child: Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color
                                : color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: isActive ? AppColors.whiteText : color,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              _RouteNavButton(
                icon: Icons.chevron_right,
                isEnabled: hasNext,
                onTap: () => onStopTap(safeIndex + 1),
              ),
              const SizedBox(width: 6),
              _RouteDetailsButton(
                color: color,
                onTap: () => onOpenStop(safeIndex),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSavingProgress
                  ? null
                  : () => onToggleVisited(safeIndex),
              icon: Icon(
                isCurrentVisited ? Icons.undo : Icons.check_circle_outline,
                size: 19,
              ),
              label: Text(
                isCurrentVisited ? 'Снять отметку' : 'Отметить точку',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentVisited ? AppColors.blueText : color,
                foregroundColor: AppColors.whiteText,
                disabledBackgroundColor: AppColors.greyBackground,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteNavButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final VoidCallback onTap;

  const _RouteNavButton({
    required this.icon,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: isEnabled ? onTap : null,
      icon: Icon(
        icon,
        color: isEnabled ? AppColors.primaryRed : AppColors.greyBackground,
      ),
      tooltip: 'Точка маршрута',
    );
  }
}

class _RouteDetailsButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const _RouteDetailsButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.info_outline,
          color: AppColors.whiteText,
          size: 21,
        ),
      ),
    );
  }
}

class _NearbyPlaceMarker extends StatelessWidget {
  final NearbyPlace place;

  const _NearbyPlaceMarker({required this.place});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.whiteText,
        shape: BoxShape.circle,
        border: Border.all(color: place.category.color, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(place.category.icon, color: place.category.color, size: 20),
    );
  }
}

class _NearbyPlacesPanel extends StatelessWidget {
  final List<NearbyPlace> places;
  final bool isLoading;
  final String? errorText;
  final NearbyPlaceCategory? selectedCategory;
  final double bottomInset;
  final ValueChanged<NearbyPlaceCategory> onCategoryChanged;
  final VoidCallback onShowAll;
  final VoidCallback onClose;
  final ValueChanged<NearbyPlace> onPlaceTap;

  const _NearbyPlacesPanel({
    required this.places,
    required this.isLoading,
    required this.errorText,
    required this.selectedCategory,
    required this.bottomInset,
    required this.onCategoryChanged,
    required this.onShowAll,
    required this.onClose,
    required this.onPlaceTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 306 + bottomInset,
      padding: EdgeInsets.fromLTRB(14, 10, 14, 12 + bottomInset),
      decoration: BoxDecoration(
        color: AppColors.beigeBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.greyBackground,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Места рядом',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.primaryRed,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Montserrat',
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, color: AppColors.primaryRed),
                tooltip: 'Закрыть',
              ),
            ],
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _NearbyCategoryChip(
                  label: 'Все',
                  icon: Icons.layers,
                  color: AppColors.primaryRed,
                  isSelected: selectedCategory == null,
                  onTap: onShowAll,
                ),
                ...NearbyPlaceCategory.values.map((category) {
                  return _NearbyCategoryChip(
                    label: category.label,
                    icon: category.icon,
                    color: category.color,
                    isSelected: selectedCategory == category,
                    onTap: () => onCategoryChanged(category),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      );
    }

    final error = errorText;
    if (error != null) {
      return Center(
        child: Text(
          error,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    if (places.isEmpty) {
      return const Center(
        child: Text(
          'Поблизости ничего не найдено',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.blueText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return _NearbyPlaceCard(place: place, onTap: () => onPlaceTap(place));
      },
    );
  }
}

class _NearbyCategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _NearbyCategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        onSelected: (_) => onTap(),
        avatar: Icon(
          icon,
          size: 16,
          color: isSelected ? AppColors.whiteText : color,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.whiteText : AppColors.primaryRed,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          fontFamily: 'Montserrat',
        ),
        backgroundColor: AppColors.whiteText,
        selectedColor: color,
        checkmarkColor: AppColors.whiteText,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onTap;

  const _NearbyPlaceCard({required this.place, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 206,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.whiteText,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: place.category.color.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: place.category.color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    place.category.icon,
                    color: place.category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    place.category.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: place.category.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              place.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primaryRed,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
            const SizedBox(height: 6),
            if (place.address != null)
              Text(
                place.address!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blueText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const Spacer(),
            Row(
              children: [
                const Icon(
                  Icons.directions_walk,
                  size: 15,
                  color: AppColors.blueText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDistance(place.distanceKm),
                  style: const TextStyle(
                    color: AppColors.blueText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.primaryRed,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyPlaceCompactCard extends StatelessWidget {
  final NearbyPlace place;
  final VoidCallback onClose;

  const _NearbyPlaceCompactCard({required this.place, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryRed.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.whiteText,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(place.category.icon, color: place.category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.whiteText,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${place.category.label} • ${_formatDistance(place.distanceKm)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFBCB0B0),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: AppColors.whiteText),
          ),
        ],
      ),
    );
  }
}

String _formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} м';
  return '${km.toStringAsFixed(1)} км';
}
