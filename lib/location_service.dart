import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart';

class LocationModel {
  final double latitude;
  final double longitude;
  final String cityName;
  final bool isAutomatic;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.cityName,
    required this.isAutomatic,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: json['latitude'],
      longitude: json['longitude'],
      cityName: json['cityName'],
      isAutomatic: json['isAutomatic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'cityName': cityName,
      'isAutomatic': isAutomatic,
    };
  }
}

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  static const String _latKey = 'location_lat';
  static const String _lngKey = 'location_lng';
  static const String _cityKey = 'location_city';
  static const String _isAutoKey = 'location_is_auto';
  static const String _isFirstLaunchKey = 'location_is_first_launch';

  // Default Location (Cairo, Egypt)
  final LocationModel _defaultLocation = LocationModel(
    latitude: 30.0444,
    longitude: 31.2357,
    cityName: 'Cairo',
    isAutomatic: true,
  );

  Future<LocationModel> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey(_latKey) && prefs.containsKey(_lngKey)) {
      return LocationModel(
        latitude: prefs.getDouble(_latKey)!,
        longitude: prefs.getDouble(_lngKey)!,
        cityName: prefs.getString(_cityKey) ?? 'Unknown',
        isAutomatic: prefs.getBool(_isAutoKey) ?? true,
      );
    }
    return _defaultLocation;
  }

  Future<void> saveLocation(LocationModel location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_latKey, location.latitude);
    await prefs.setDouble(_lngKey, location.longitude);
    await prefs.setString(_cityKey, location.cityName);
    await prefs.setBool(_isAutoKey, location.isAutomatic);
    notifyListeners();
  }

  Future<bool> isFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirst = prefs.getBool(_isFirstLaunchKey) ?? true;
    if (isFirst) {
      await prefs.setBool(_isFirstLaunchKey, false);
    }
    return isFirst;
  }

  Future<LocationModel?> determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are not enabled
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are denied forever
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      String city = await _getCityName(position.latitude, position.longitude);

      final newLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        cityName: city,
        isAutomatic: true,
      );

      await saveLocation(newLocation);
      return newLocation;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  Future<String> _getCityName(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // Sometimes locality is empty, fallback to subAdministrativeArea or administrativeArea
        String city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? 'Unknown';
        if (city.isEmpty) {
           city = place.country ?? 'Unknown';
        }
        return city;
      }
    } catch (e) {
      debugPrint('Error reverse geocoding: $e');
    }
    return 'Unknown Location';
  }

  Future<LocationModel?> searchCity(String cityName) async {
    try {
      List<Location> locations = await locationFromAddress(cityName);
      if (locations.isNotEmpty) {
        Location loc = locations.first;
        
        // Let's get the properly formatted name back
        String formattedCity = cityName;
        try {
           List<Placemark> placemarks = await placemarkFromCoordinates(loc.latitude, loc.longitude);
           if (placemarks.isNotEmpty) {
              Placemark place = placemarks.first;
              String foundCity = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea ?? '';
              if (foundCity.isNotEmpty) {
                  formattedCity = foundCity;
              }
           }
        } catch (_) {}

        return LocationModel(
          latitude: loc.latitude,
          longitude: loc.longitude,
          cityName: formattedCity,
          isAutomatic: false,
        );
      }
    } catch (e) {
      debugPrint('Error geocoding city: $e');
    }
    return null;
  }
}
