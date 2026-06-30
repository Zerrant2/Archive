// lib/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../core/providers/objects_provider.dart';
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
  HistoricalObject? _selectedObject;
  
  final LatLng _volgogradCenter = const LatLng(48.7186, 44.5133);
  
  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ObjectsProvider>().loadObjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final objectsProvider = context.watch<ObjectsProvider>();
    final objects = objectsProvider.allObjects;
    
    return Scaffold(
      backgroundColor: AppColors.beigeBackground,
      body: Column(
        children: [
          const _MapHeader(),
          
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
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.histoar',
                    ),
                    
                    MarkerLayer(
                      markers: objects.map((object) {
                        return Marker(
                          width: 40.0,
                          height: 40.0,
                          point: LatLng(object.latitude, object.longitude),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedObject = object;
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
                  ],
                ),
                
                if (_selectedObject != null)
                  Positioned(
                    bottom: 20,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      color: AppColors.primaryRed,
      child: Stack(
        children: [
          const Positioned(
            left: 20,
            top: 33,
            child: Text(
              "Карта мест",
              style: TextStyle(
                color: AppColors.whiteText,
                fontSize: 25,
                fontWeight: FontWeight.w800,
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          const Positioned(
            left: 20,
            top: 66,
            child: Text(
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
            right: 20,
            top: 18,
            child: GestureDetector(
              onTap: () {
                final mapState = context.findAncestorStateOfType<_MapScreenState>();
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

  const _LocationCard({
    required this.object,
    required this.onTap,
  });

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
