import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/app_strings.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(-6.236889, 106.8079006);
  static const double _zoom = 13;
  static const double _radius = 50;

  final Set<Marker> _markers = {};
  final Set<Circle> _circles = {};
  LatLng _currentLocation = const LatLng(0, 0);
  LatLng? _markerLocation;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 18),
      );
    } on PermissionDeniedException {
      debugPrint(AppStrings.locationDenied);
    } on LocationServiceDisabledException {
      debugPrint(AppStrings.locationDisabled);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    _addMarker(position);
    _addCircle(position);
    _showDistanceCheckSheet();
  }

  void _addMarker(LatLng position) {
    final lat = position.latitude.toStringAsFixed(6);
    final long = position.longitude.toStringAsFixed(6);

    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(title: "$lat, $long"),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    );

    setState(() {
      _markerLocation = position;
      _markers
        ..clear()
        ..add(marker);
    });
  }

  void _addCircle(LatLng position) {
    final circle = Circle(
      circleId: CircleId(position.toString()),
      center: position,
      radius: _radius,
      fillColor: Colors.blue.withValues(alpha: 0.2),
      strokeColor: Colors.blue,
      strokeWidth: 2,
    );

    setState(() {
      _circles
        ..clear()
        ..add(circle);
    });
  }

  void _showDistanceCheckSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.checkDistanceTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkDistance,
                child: const Text(AppStrings.checkDistanceButton),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkDistance() async {
    if (_markerLocation == null) return;

    final distance = Geolocator.distanceBetween(
      _currentLocation.latitude,
      _currentLocation.longitude,
      _markerLocation!.latitude,
      _markerLocation!.longitude,
    );

    final result = distance <= _radius
        ? AppStrings.accepted
        : AppStrings.rejected;

    if (!context.mounted) return;

    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(AppStrings.absenceResultTitle),
        content: Text("Distance: ${distance.toStringAsFixed(2)} m\n$result"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.chooseLocation)),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: const CameraPosition(
          target: _defaultCenter,
          zoom: _zoom,
        ),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        markers: _markers,
        circles: _circles,
        onTap: _onMapTap,
      ),
    );
  }
}
