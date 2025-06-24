import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:convert';
import 'dart:math';

import 'package:frontend/api_secrets.dart';
import 'package:frontend/widgets/pulsing_marker.dart';
import '../models/point_of_interest.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'search_screen.dart';

class MapStyle {
  final String name;
  final String url;
  final String attribution;
  const MapStyle({required this.name, required this.url, required this.attribution});
}

// --- NEW: A clean way to define our travel modes ---
enum TravelMode { driving, cycling, walking }

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final ApiService _apiService = ApiService();
  List<PointOfInterest> _points = [];
  bool _isLoading = true;
  String? _errorMessage;
  LatLng _currentPosition = LatLng(51.509364, -0.128928);
  final MapController _mapController = MapController();

  final List<MapStyle> _mapStyles = [
    const MapStyle(name: 'OpenStreetMap', url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', attribution: '© OpenStreetMap contributors'),
    const MapStyle(name: 'OpenTopoMap', url: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', attribution: 'Map data: © OpenStreetMap, SRTM | Map style: © OpenTopoMap'),
    const MapStyle(name: 'CyclOSM', url: 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png', attribution: '© CyclOSM & OpenStreetMap contributors'),
  ];
  int _currentMapStyleIndex = 0;

  List<Category> _categories = [];
  Set<int> _selectedCategoryIds = {};
  double _searchRadius = 1000;

  LatLng? _tappedPoint;
  List<LatLng> _routePoints = [];
  Color _routeColor = Colors.deepPurple;
  TravelMode _selectedTravelMode = TravelMode.driving;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _loadNearbyPoints();
    await _loadCategories();
  }

  Future<void> _getRoute(LatLng destination) async {
    setState(() { _isLoading = true; });

    String modeString;
    Color newRouteColor;
    switch (_selectedTravelMode) {
      case TravelMode.cycling:
        modeString = 'cycling-regular';
        newRouteColor = Colors.green;
        break;
      case TravelMode.walking:
        modeString = 'foot-walking';
        newRouteColor = Colors.orange;
        break;
      default:
        modeString = 'driving-car';
        newRouteColor = Colors.deepPurple;
    }

    final url = 'https://api.openrouteservice.org/v2/directions/$modeString/geojson';
    final headers = {
      'Authorization': orsApiKey,
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'coordinates': [[_currentPosition.longitude, _currentPosition.latitude], [destination.longitude, destination.latitude]]
    });

    try {
      final response = await http.post(Uri.parse(url), headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final coords = data['features'][0]['geometry']['coordinates'] as List;
        final summary = data['features'][0]['properties']['summary'];
        final double distanceInKm = summary['distance'] / 1000;
        final double durationInMinutes = summary['duration'] / 60;
        final routePoints = coords.map((coord) => LatLng(coord[1].toDouble(), coord[0].toDouble())).toList();

        if (!mounted) return;
        setState(() {
          _routePoints = routePoints;
          _routeColor = newRouteColor;
          _isLoading = false;
        });

        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(routePoints),
            padding: const EdgeInsets.all(50.0),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedTravelMode.name.capitalize()} route: ${distanceInKm.toStringAsFixed(1)} km, ${durationInMinutes.toStringAsFixed(0)} mins'
            ),
            duration: const Duration(seconds: 5),
          ),
        );

      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to load route: ${errorData['error']['message']}');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error getting route: $e')));
    }
  }

  Future<void> _handleMapLongPress(LatLng tappedPoint) async {
    setState(() {
      _tappedPoint = tappedPoint;
    });

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=${tappedPoint.latitude}&lon=${tappedPoint.longitude}'
      );
      final response = await http.get(url, headers: {'User-Agent': 'ESME Maps App'});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String address = data['display_name'] ?? 'No address found';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(address),
            action: SnackBarAction(
              label: 'Clear',
              onPressed: () => setState(() => _tappedPoint = null),
            ),
          ),
        );
      } else {
        throw Exception('Failed to fetch address');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not find address for this location.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentMapStyle = _mapStyles[_currentMapStyleIndex];
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ESME Maps'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          if (_routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear Route',
              onPressed: () => setState(() => _routePoints.clear()),
            ),
          IconButton(icon: const Icon(Icons.search), onPressed: () async { final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const SearchScreen())); if (result != null && result is PointOfInterest) { _mapController.move(LatLng(result.latitude, result.longitude), 15.0); } }, tooltip: 'Search'),
          IconButton(icon: const Icon(Icons.filter_list), onPressed: _showFilterDialog, tooltip: 'Filter'),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'style') _changeMapStyle();
              if (value == 'radius') _showRadiusSelector();
              if (value == 'refresh') _loadNearbyPoints();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'radius', child: Text('Set Search Radius')),
              const PopupMenuItem(value: 'style', child: Text('Change Map Style')),
              const PopupMenuItem(value: 'refresh', child: Text('Refresh Points')),
            ],
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition,
              initialZoom: 13.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              onLongPress: (tapPosition, point) => _handleMapLongPress(point),
            ),
            children: [
              TileLayer(
                urlTemplate: currentMapStyle.url,
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.esme',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: _routeColor,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _currentPosition, radius: _searchRadius, useRadiusInMeter: true,
                    color: Colors.blue.withOpacity(0.1), borderColor: Colors.blue.withOpacity(0.5), borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ..._points.map((point) => Marker(
                    width: 40.0, height: 40.0,
                    point: LatLng(point.latitude, point.longitude),
                    child: GestureDetector(
                      onTap: () => _showPointDetails(point),
                      child: Container(
                        decoration: BoxDecoration(color: colorScheme.primary, shape: BoxShape.circle, boxShadow: [ BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]),
                        child: Icon(_getCategoryIcon(point.category), color: colorScheme.onPrimary, size: 20),
                      ),
                    ),
                  )),
                  if (_tappedPoint != null)
                    Marker(
                      width: 80.0,
                      height: 80.0,
                      point: _tappedPoint!,
                      child: const Icon(Icons.location_pin, size: 50.0, color: Colors.redAccent),
                    ),
                  Marker(width: 40.0, height: 40.0, point: _currentPosition, child: const PulsingMarker()),
                ],
              ),
            ],
          ),
          Positioned(
            top: 100.0,
            right: 16.0,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomInButton',
                  child: const Icon(Icons.add),
                  onPressed: () { final currentZoom = _mapController.camera.zoom; _mapController.move(_mapController.camera.center, currentZoom + 1); },
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOutButton',
                  child: const Icon(Icons.remove),
                  onPressed: () { final currentZoom = _mapController.camera.zoom; _mapController.move(_mapController.camera.center, currentZoom - 1); },
                ),
              ],
            ),
          ),
          if (_isLoading) Container(color: Colors.black.withOpacity(0.5), child: const Center(child: CircularProgressIndicator())),
          if (_errorMessage != null) Positioned(bottom: 80, left: 20, right: 20, child: Card(color: Colors.redAccent, child: Padding(padding: const EdgeInsets.all(12.0), child: Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center)))),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: _getCurrentLocation, child: const Icon(Icons.my_location)),
    );
  }

  void _showPointDetails(PointOfInterest point) {
  showModalBottomSheet(
    context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
    builder: (context) {
      final colorScheme = Theme.of(context).colorScheme;
      final textTheme = Theme.of(context).textTheme;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return DraggableScrollableSheet(
            // It need it to be a bit taller to fit all the pinned controls
            initialChildSize: 0.65,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (_, controller) {
              return Container(
                decoration: BoxDecoration(color: colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
                child: Column(
                  children: [
                    // --- Part 1: The SCROLLABLE content ---
                    Expanded(
                      child: ListView(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        children: [
                          Center(child: Container(width: 40, height: 5, margin: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(_getCategoryIcon(point.category), color: colorScheme.primary, size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(point.name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                    if (point.category != null) Padding(padding: const EdgeInsets.only(top: 4.0), child: Text(point.category!.name, style: textTheme.bodyLarge?.copyWith(color: colorScheme.secondary))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 40),
                          if (point.description != null && point.description!.isNotEmpty) ...[
                            Text("About", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Text(point.description!, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                            const SizedBox(height: 24),
                          ],
                          _buildInfoTile(context, icon: Icons.location_on_outlined, title: 'Address', subtitle: point.address ?? 'Not available'),
                          const SizedBox(height: 12),
                          _buildInfoTile(context, icon: Icons.directions_walk, title: 'Distance', subtitle: '${calculateDistance(_currentPosition, LatLng(point.latitude, point.longitude)).toStringAsFixed(2)} km away'),
                        ],
                      ),
                    ),

                    // --- Part 2: PINNED Travel Mode Selector ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SegmentedButton<TravelMode>(
                        segments: const <ButtonSegment<TravelMode>>[
                          ButtonSegment<TravelMode>(value: TravelMode.driving, label: Text('Car'), icon: Icon(Icons.directions_car)),
                          ButtonSegment<TravelMode>(value: TravelMode.cycling, label: Text('Bike'), icon: Icon(Icons.directions_bike)),
                          ButtonSegment<TravelMode>(value: TravelMode.walking, label: Text('Walk'), icon: Icon(Icons.directions_walk)),
                        ],
                        selected: {_selectedTravelMode},
                        onSelectionChanged: (Set<TravelMode> newSelection) {
                          setModalState(() {
                            _selectedTravelMode = newSelection.first;
                          });
                          setState(() {
                            _selectedTravelMode = newSelection.first;
                          });
                        },
                      ),
                    ),

                    // --- Part 3: PINNED Action Buttons ---
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.route),
                              label: const Text('Show Route'),
                              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: colorScheme.secondary, foregroundColor: colorScheme.onSecondary),
                              onPressed: () {
                                Navigator.pop(context);
                                _getRoute(LatLng(point.latitude, point.longitude));
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.map),
                              label: const Text('Open Maps'),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                              onPressed: () async {
                                final url = 'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}';
                                if (await canLaunchUrl(Uri.parse(url))) {
                                  await launchUrl(Uri.parse(url));
                                }
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}

  // --- All other methods are unchanged ---
  void _changeMapStyle() { setState(() { _currentMapStyleIndex = (_currentMapStyleIndex + 1) % _mapStyles.length; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Map style: ${_mapStyles[_currentMapStyleIndex].name}'))); }
  Future<void> _loadCategories() async { try { final categories = await _apiService.getCategories(); if (!mounted) return; setState(() { _categories = categories; }); } catch (e) { print('Error loading categories: $e'); } }
  Future<void> _loadNearbyPoints() async { setState(() { _isLoading = true; _errorMessage = null; }); try { final points = await _apiService.getNearbyPoints(_currentPosition.latitude, _currentPosition.longitude, _searchRadius); final filteredPoints = _selectedCategoryIds.isEmpty ? points : points.where((p) => p.category != null && _selectedCategoryIds.contains(p.category!.id)).toList(); if (!mounted) return; setState(() { _points = filteredPoints; _isLoading = false; _errorMessage = _points.isEmpty ? 'No nearby points found.' : null; }); } catch (e) { if (!mounted) return; setState(() { _isLoading = false; _errorMessage = 'Error loading nearby points: $e'; }); } }
  Future<void> _getCurrentLocation() async { setState(() { _isLoading = true; }); try { LocationPermission permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied) throw Exception('Location permissions are denied'); } if (permission == LocationPermission.deniedForever) throw Exception('Location permissions are permanently denied.'); final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high); if (!mounted) return; setState(() { _currentPosition = LatLng(position.latitude, position.longitude); }); _mapController.move(_currentPosition, 14.0); } catch (e) { if (!mounted) return; setState(() { _errorMessage = 'Error getting location: $e'; }); } finally { if (!mounted) return; setState(() { _isLoading = false; }); } }
  IconData _getCategoryIcon(Category? category) { if (category == null) return Icons.location_on; switch(category.name.toLowerCase()) { case 'restaurant': case 'food': return Icons.restaurant; case 'cafe': case 'coffee': return Icons.local_cafe; case 'shopping': case 'store': return Icons.shopping_bag; case 'hotel': case 'lodging': return Icons.hotel; case 'attraction': case 'tourism': return Icons.attractions; case 'park': case 'nature': return Icons.park; case 'transport': case 'station': return Icons.directions_transit; default: return Icons.place; } }
  Widget _buildInfoTile(BuildContext context, {required IconData icon, required String title, required String subtitle}) { final colorScheme = Theme.of(context).colorScheme; final textTheme = Theme.of(context).textTheme; return Row( crossAxisAlignment: CrossAxisAlignment.start, children: [ Icon(icon, color: colorScheme.secondary, size: 24), const SizedBox(width: 16), Expanded( child: Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(title, style: textTheme.bodyLarge), const SizedBox(height: 2), Text(subtitle, style: textTheme.bodyMedium?.copyWith(color: Colors.grey[600])), ], ), ), ], ); }
  void _showFilterDialog() { showModalBottomSheet( context: context, builder: (context) { return StatefulBuilder( builder: (context, setModalState) { return Container( padding: const EdgeInsets.all(16), child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Filter by Category', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16), Wrap( spacing: 8, runSpacing: 8, children: _categories.map((category) { final isSelected = _selectedCategoryIds.contains(category.id); return FilterChip( label: Text(category.name), selected: isSelected, onSelected: (selected) { setModalState(() { if (selected) { _selectedCategoryIds.add(category.id); } else { _selectedCategoryIds.remove(category.id); } }); setState(() {}); }, ); }).toList(), ), const SizedBox(height: 16), Row( mainAxisAlignment: MainAxisAlignment.end, children: [ TextButton(onPressed: () { setModalState(() { _selectedCategoryIds.clear(); }); setState(() {}); }, child: const Text('Clear All')), const SizedBox(width: 8), ElevatedButton(onPressed: () { Navigator.pop(context); _loadNearbyPoints(); }, child: const Text('Apply')), ], ), ], ), ); }, ); }, ); }
  void _showRadiusSelector() { showModalBottomSheet( context: context, builder: (context) { return StatefulBuilder( builder: (context, setModalState) { return Container( padding: const EdgeInsets.all(16), child: Column( mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [ Text('Search Radius', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 16), Text('${(_searchRadius / 1000).toStringAsFixed(1)} km', style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center), Slider( value: _searchRadius, min: 500, max: 5000, divisions: 9, label: '${(_searchRadius / 1000).toStringAsFixed(1)} km', onChanged: (value) { setModalState(() { _searchRadius = value; }); }, ), const SizedBox(height: 16), Row( mainAxisAlignment: MainAxisAlignment.end, children: [ TextButton(onPressed: () { Navigator.pop(context); }, child: const Text('Cancel')), const SizedBox(width: 8), ElevatedButton(onPressed: () { Navigator.pop(context); setState(() {}); _loadNearbyPoints(); }, child: const Text('Apply')), ], ), ], ), ); }, ); }, ); }
}

double calculateDistance(LatLng point1, LatLng point2) { const double earthRadius = 6371; final double lat1 = point1.latitude * (pi / 180); final double lon1 = point1.longitude * (pi / 180); final double lat2 = point2.latitude * (pi / 180); final double lon2 = point2.longitude * (pi / 180); final double dLat = lat2 - lat1; final double dLon = lon2 - lon1; final double a = sin(dLat / 2) * sin(dLat / 2) + cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2); final double c = 2 * atan2(sqrt(a), sqrt(1 - a)); return earthRadius * c; }

extension StringExtension on String {
    String capitalize() {
      return "${this[0].toUpperCase()}${this.substring(1)}";
    }
}