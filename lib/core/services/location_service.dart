import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:snip_fair/core/data/models/remote/auto_complete_result.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/network/http_service.dart';

@LazySingleton()
class LocationService {
  Timer? _timer;

  void startPingingLocationToServer() {
    _timer?.cancel();
    _timer = null;
    _timer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _updateCurrentLocationToServer(),
    );
  }

  void stopPingingLocationToServer() {
    _timer?.toString();
  }

  ///Write function to check location permission and return true or false
  Future<bool> checkLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return false;
    }
    return true;
  }

  //Write functions to request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) {
      return false;
    }
    return true;
  }

  //Write function to go to location settings
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<void> _updateCurrentLocationToServer() async {
    final repo = getIt<ProfileRepository>();
    try {
      final position = await _determinePosition();
      await repo.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (e, s) {
      Logger().e('LocationService: ', error: e, stackTrace: s);
    }
  }

  void sendLocationUpdateRequest() {
    unawaited(_updateCurrentLocationToServer());
  }

  void sendConsentToUseLocation(bool consentGiven) {
    unawaited(_updateLocationConsentToServer(consentGiven: consentGiven));
  }

  Future<void> _updateLocationConsentToServer(
      {required bool consentGiven}) async {
    final repo = getIt<ProfileRepository>();
    try {
      await repo.updateLocationConsent(consentGiven);
      Fluttertoast.showToast(msg: 'Location consent updated');
    } catch (e, s) {
      Logger().e('LocationService: ', error: e, stackTrace: s);
    }
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return Geolocator.getCurrentPosition();
  }

  Future<List<GeoPlace>> placeSearch(String query) async {
    try {
      final response = await Dio(
        BaseOptions(
          baseUrl: 'https://api.geoapify.com',
          validateStatus: (status) => status == 200,
        ),
      ).get<Map<String, dynamic>>('/v1/geocode/autocomplete', queryParameters: {
        'text': query,
        'apiKey': '444cf10f491e417d81d839ee58801389',
        'limit': '5',
        'lang': 'za',
        'filter': 'countrycode:za',
      });

      final autocomplete = AutoCompleteResult.fromJson(response.data!);
      return autocomplete.features!
          .map(
            (element) => GeoPlace(
              address: element.properties?.formatted ?? 'N/A',
              lat: element.properties?.lat ?? 0.0,
              lng: element.properties?.lon ?? 0.0,
            ),
          )
          .toList();
    } catch (e) {
      Logger().e('PLACE SEARCH ERROR: ', error: e);
      return [];
    }
  }
}
