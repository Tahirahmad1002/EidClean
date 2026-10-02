// 📁 lib/screens/citizen/location_picker_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng _center = const LatLng(34.1558, 73.2194);
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _loading = false;
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // ─── NOMINATIM: Reverse Geocode (coords → address) ───
  Future<String> _reverseGeocode(LatLng latLng) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?'
        'format=json&lat=${latLng.latitude}&lon=${latLng.longitude}&zoom=18&addressdetails=1',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'EidCleanApp/1.0 (contact@eidclean.pk)'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['display_name'] != null) {
          return data['display_name'].toString();
        }
      }
    } catch (e) {
      print('Reverse geocode error: $e');
    }
    return '${latLng.latitude.toStringAsFixed(4)}, ${latLng.longitude.toStringAsFixed(4)}';
  }

  // ─── NOMINATIM: Forward Geocode (address → coords) ──
  Future<List<dynamic>> _searchLocation(String query) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?'
        'format=json&q=${Uri.encodeComponent(query)}&limit=1&countrycodes=pk',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'EidCleanApp/1.0 (contact@eidclean.pk)'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as List;
      }
    } catch (e) {
      print('Search error: $e');
    }
    return [];
  }

  // ─── GET CURRENT LOCATION (GPS) ───
  Future<void> _getCurrentLocation() async {
    setState(() => _loading = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() => _loading = false);
        _showSnack('Location permission denied');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = newCenter;
        _selectedLocation = newCenter;
      });

      _mapController.move(newCenter, 15);
      final address = await _reverseGeocode(newCenter);
      setState(() {
        _selectedAddress = address;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _showSnack('Error getting location: $e');
    }
  }

  // ─── HANDLE MAP TAP ───
  Future<void> _onMapTap(LatLng latLng) async {
    setState(() {
      _selectedLocation = latLng;
      _selectedAddress = 'Loading address...';
    });
    final address = await _reverseGeocode(latLng);
    setState(() => _selectedAddress = address);
  }

  // ─── SEARCH ADDRESS ───
  Future<void> _searchAddress() async {
    if (_searchCtrl.text.trim().isEmpty) return;
    setState(() => _searching = true);

    final results = await _searchLocation(_searchCtrl.text.trim());

    if (results.isNotEmpty) {
      final lat = double.parse(results[0]['lat']);
      final lon = double.parse(results[0]['lon']);
      final latLng = LatLng(lat, lon);

      setState(() {
        _center = latLng;
        _selectedLocation = latLng;
        _searching = false;
      });
      _mapController.move(latLng, 15);
      final address = await _reverseGeocode(latLng);
      setState(() => _selectedAddress = address);
    } else {
      setState(() => _searching = false);
      _showSnack('Location not found. Try "Mandian Abbottabad"');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _confirmLocation() {
    if (_selectedLocation == null) {
      _showSnack('Please tap on the map to select a location');
      return;
    }

    Navigator.pop(context, {
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        title: const Text(
          'Select Pickup Location',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ─── MAP ───
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              onTap: (tapPosition, latLng) => _onMapTap(latLng),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.eidclean_app',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFEF4444),
                        size: 45,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ─── SEARCH BAR ───
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (_) => _searchAddress(),
                decoration: InputDecoration(
                  hintText: 'Search area (e.g., Mandian Abbottabad)',
                  prefixIcon:
                      const Icon(Icons.search, color: Color(0xFF10B981)),
                  suffixIcon: _searching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: _searchAddress,
                        ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),

          // ─── MY LOCATION BUTTON ───
          Positioned(
            bottom: 180,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF10B981),
              child: const Icon(Icons.my_location),
            ),
          ),

          // ─── BOTTOM CONFIRM CARD ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedAddress.isEmpty
                              ? 'Tap on map to select'
                              : _selectedAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Confirm Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── LOADING OVERLAY ───
          if (_loading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}