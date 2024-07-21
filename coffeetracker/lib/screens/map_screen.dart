import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geocoding/geocoding.dart';

class MapScreen extends StatefulWidget {
  final Function(String) onLocationPicked;
  final LatLng? initialPosition;

  const MapScreen({required this.onLocationPicked, this.initialPosition, Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  // final LatLng _initialPosition = const LatLng(51.5074, -0.1278); // Initial position (London)
  LatLng? _selectedPosition;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      // _getCurrentLocation();
    } else if (status.isDenied) {
      // Handle the case where the user denied the permission
      // Optionally, show a dialog to inform the user why the permission is necessary
    } else if (status.isPermanentlyDenied) {
      // Handle the case where the user permanently denied the permission
      // Optionally, show a dialog to inform the user how to enable the permission from settings
      openAppSettings();
    }
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _selectedPosition = LatLng(position.latitude, position.longitude);
      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _selectedPosition!, zoom: 15.0),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Shop's Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              print(_selectedPosition);
              if (_selectedPosition != null) {
                _getAddressFromLatLng(_selectedPosition!);
              } else {
                Navigator.pop(context);
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
              if (widget.initialPosition != null) {
                mapController.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: widget.initialPosition!, zoom: 15.0),
                  ),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: widget.initialPosition ?? LatLng(51.5074, -0.1278), // Default to London if no initial position
              zoom: 10.0,
            ),
            onTap: (position) {
              setState(() {
                _selectedPosition = position;
              });
            },
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId('selected'),
                      position: _selectedPosition!,
                    ),
                  }
                : {},
          ),
          Positioned(
            bottom: 110,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _getCurrentLocation,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address = "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
        widget.onLocationPicked(address);
        Navigator.pop(context, address);  // Return the address to the previous screen
      }
    } catch (e) {
      print(e);
      throw Exception('Failed to load address from coordinates');
    }
  }
}
