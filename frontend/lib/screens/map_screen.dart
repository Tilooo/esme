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
  LatLng _currentPosition = LatLng(51.509364, -0.128928); // Default to London
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _getCurrentLocation();
  }

  Future<void> _loadData() async {
    try {
      final points = await _apiService.getPointsOfInterest();
      setState(() {
        _points = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }
      
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentPosition, 13.0);
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentPosition,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
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