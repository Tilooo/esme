import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/point_of_interest.dart';
import '../services/api_service.dart';

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
      'name': 'Stamen Terrain',
      'url': 'https://stamen-tiles.a.ssl.fastly.net/terrain/{z}/{x}/{y}.jpg',
    },
    {
      'name': 'Stamen Toner',
      'url': 'https://stamen-tiles.a.ssl.fastly.net/toner/{z}/{x}/{y}.png',
    },
  ];
  int _currentMapStyleIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Get location after the widget is built
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

  Future<void> _loadNearbyPoints() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Get nearby points within 5km radius
      final nearbyData = await _apiService.getNearbyPoints(
        _currentPosition.latitude, 
        _currentPosition.longitude,
        5.0
      );
      
      // Convert to PointOfInterest objects
      final nearbyPoints = nearbyData.map((item) {
        return PointOfInterest.fromJson(item['point']);
      }).toList();
      
      setState(() {
        _points = nearbyPoints;
        _isLoading = false;
        _errorMessage = null;
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

  void _moveMapToCurrentPosition() {
    try {
      if (_mapController.camera != null) {
        _mapController.move(_currentPosition, 13.0);
      }
    } catch (e) {
      print('Error moving map: $e');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied, please enable in settings'),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });
      
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isLoading = false;
      });
      
      if (_isMapInitialized) {
        _moveMapToCurrentPosition();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Load all points',
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
        ],
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
                        'attribution': '&copy; OpenStreetMap contributors, Stamen Design',
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
                              width: 40.0,
                              height: 40.0,
                              point: LatLng(point.latitude, point.longitude),
                              child: IconButton(
                                icon: Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40.0,
                                ),
                                onPressed: () {
                                  _showPointDetails(point);
                                },
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
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
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                point.name,
                style: const TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (point.category != null)
                Chip(
                  label: Text(point.category!.name),
                  avatar: point.category!.icon != null
                      ? Icon(Icons.category)
                      : null,
                ),
              if (point.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(point.description!),
                ),
              if (point.address != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, size: 16.0),
                      const SizedBox(width: 4.0),
                      Expanded(child: Text(point.address!)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}