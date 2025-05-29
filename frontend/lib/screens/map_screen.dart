import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/point_of_interest.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import 'search_screen.dart';

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
  LatLng _currentPosition = LatLng(51.509364, -0.128928); // Default to London
  final MapController _mapController = MapController();
  bool _isMapInitialized = false;

  // Map styles
  final List<Map<String, String>> _mapStyles = [
    {
      'name': 'OpenStreetMap',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'OpenTopoMap',
      'url': 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'CyclOSM',
      'url': 'https://{s}.tile-cyclosm.openstreetmap.fr/cyclosm/{z}/{x}/{y}.png',
    },
  ];
  int _currentMapStyleIndex = 0;

  // State variables for new features
  List<Category> _categories = [];
  Set<int> _selectedCategoryIds = {};
  double _searchRadius = 1000; // Default radius in meters

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCategories(); // Load categories for filter

    // Gets location after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  void _changeMapStyle() {
    setState(() {
      _currentMapStyleIndex = (_currentMapStyleIndex + 1) % _mapStyles.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Map style: ${_mapStyles[_currentMapStyleIndex]['name']}')),
    );
  }

  Future<void> _loadData() async {
    try {
      final points = await _apiService.getPointsOfInterest();
      setState(() {
        _points = points;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading data: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  // Method to load categories
  Future<void> _loadCategories() async {
    try {
      final categories = await _apiService.getCategories();
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadNearbyPoints() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final points = await _apiService.getNearbyPoints(
        _currentPosition.latitude,
        _currentPosition.longitude,
        _searchRadius,
      );

      // Category filters if any are selected
      final filteredPoints = _selectedCategoryIds.isEmpty
          ? points
          : points.where((point) =>
              point.category != null &&
              _selectedCategoryIds.contains(point.category!.id)
            ).toList();

      setState(() {
        _points = filteredPoints;
        _isLoading = false;
        if (_points.isEmpty) {
          _errorMessage = 'No nearby points found';
        } else {
          _errorMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading nearby points: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading nearby points: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Checks location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Gets current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });

      _moveMapToCurrentPosition();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error getting location: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _moveMapToCurrentPosition() {
    if (_isMapInitialized) {
      _mapController.move(_currentPosition, 13.0);
    }
  }

  // Method to show filter dialog
  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategoryIds.contains(category.id);
                      return FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedCategoryIds.add(category.id);
                            } else {
                              _selectedCategoryIds.remove(category.id);
                            }
                          });
                          setState(() {}); // Updates the main screen
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategoryIds.clear();
                          });
                          setState(() {}); // Updates the main screen
                        },
                        child: const Text('Clear All'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadNearbyPoints(); // Reloads with filters applied
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Method to show radius selector
  void _showRadiusSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Radius',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${(_searchRadius / 1000).toStringAsFixed(1)} km',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  Slider(
                    value: _searchRadius,
                    min: 500,
                    max: 5000,
                    divisions: 9,
                    label: '${(_searchRadius / 1000).toStringAsFixed(1)} km',
                    onChanged: (value) {
                      setModalState(() {
                        _searchRadius = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          setState(() {}); // Updates the main screen
                          _loadNearbyPoints(); // Reloads with new radius
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method for category icons
  IconData _getCategoryIcon(Category? category) {
    if (category == null) return Icons.location_on;

    // Map category names to appropriate icons
    switch(category.name.toLowerCase()) {
      case 'restaurant':
      case 'food':
      case 'dining':
        return Icons.restaurant;
      case 'cafe':
      case 'coffee':
        return Icons.coffee;
      case 'shopping':
      case 'store':
      case 'mall':
        return Icons.shopping_bag;
      case 'hotel':
      case 'lodging':
        return Icons.hotel;
      case 'attraction':
      case 'tourism':
        return Icons.attractions;
      case 'park':
      case 'nature':
        return Icons.park;
      case 'transport':
      case 'station':
      case 'bus':
      case 'train':
        return Icons.directions_transit;
      default:
        return Icons.place;
    }
  }

  // Helper method for action buttons
  Widget _actionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ESME Maps'),
        centerTitle: false,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.near_me),
            onPressed: _loadNearbyPoints,
            tooltip: 'Load nearby points',
          ),
          IconButton(
            icon: const Icon(Icons.layers),
            onPressed: _changeMapStyle,
            tooltip: 'Change map style',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter by category',
          ),
          IconButton(
            icon: const Icon(Icons.radar),
            onPressed: _showRadiusSelector,
            tooltip: 'Set search radius',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
              if (result != null && result is PointOfInterest) {
                setState(() {
                  _mapController.move(
                    LatLng(result.latitude, result.longitude),
                    15.0,
                  );
                });
              }
            },
            tooltip: 'Search',
          ),
        ],
        bottom: _isLoading ? PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
          ),
        ) : null,
      ),
      body: Stack(
        children: [
          _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: TextStyle(color: Colors.red)))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition,
                    initialZoom: 13.0,
                    onMapReady: () {
                      setState(() {
                        _isMapInitialized = true;
                      });
                      _moveMapToCurrentPosition();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _mapStyles[_currentMapStyleIndex]['url'],
                      additionalOptions: const {
                        'attribution': '&copy; OpenStreetMap contributors',
                      },
                      // The stackTrace parameter
                      errorTileCallback: (tile, error, stackTrace) {
                        print('Error loading tile: $error');
                        if (stackTrace != null) {
                          print('Stack trace: $stackTrace');
                        }
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        // Current location marker
                        Marker(
                          width: 40.0,
                          height: 40.0,
                          point: _currentPosition,
                          child: const Icon(
                            Icons.my_location,
                            color: Colors.blue,
                            size: 40.0,
                          ),
                        ),
                        // Points of interest markers
                        ..._points.map((point) => Marker(
                          width: 50.0,
                          height: 50.0,
                          point: LatLng(point.latitude, point.longitude),
                          child: GestureDetector(
                            onTap: () => _showPointDetails(point),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(point.category),
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    size: 20,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    point.name,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading map data...',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  void _showPointDetails(PointOfInterest point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.4,
          minChildSize: 0.2,
          maxChildSize: 0.8,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(20),
                children: [
                  // Handles for dragging
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                  ),
                  // Title and category
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getCategoryIcon(point.category),
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              point.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (point.category != null)
                              Chip(
                                label: Text(point.category!.name),
                                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                                labelStyle: TextStyle(
                                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                                ),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  // Description
                  if (point.description != null && point.description!.isNotEmpty) ...[
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      point.description!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Address
                  if (point.address != null && point.address!.isNotEmpty) ...[
                    Text(
                      'Address',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            point.address!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _actionButton(
                        context,
                        icon: Icons.directions,
                        label: 'Directions',
                        onTap: () {
                          // Opens maps app with directions
                          final url = 'https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}';
                          // Implements url launcher
                        },
                      ),
                      _actionButton(
                        context,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () {
                          // Shares location
                        },
                      ),
                      _actionButton(
                        context,
                        icon: Icons.star_border,
                        label: 'Save',
                        onTap: () {
                          // Saves to favorites
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}