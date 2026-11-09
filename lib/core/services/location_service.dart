import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';

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
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
      return false;
    }
    return true;
  }

  //Write functions to request location permission
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always && permission != LocationPermission.whileInUse) {
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

  Future<void> _updateLocationConsentToServer({
    required bool consentGiven,
  }) async {
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

  /// Fewer characters than this never call the address provider.
  static const placeSearchMinChars = 3;

  /// Creates the HTTP client for [placeSearch]; replaced in tests.
  @visibleForTesting
  static Dio Function(BaseOptions options) createPlaceSearchClient = Dio.new;

  /// Address suggestions in South Africa from Geoapify's autocomplete.
  ///
  /// Returns an empty list when nothing matches (or the query is shorter than
  /// [placeSearchMinChars]). Throws [PlaceSearchException] when the provider
  /// could not be asked or answered with an error, so the field can tell "no
  /// results" from "unavailable". The request URL carries the API key, so only
  /// the error type and HTTP status are ever logged.
  Future<List<GeoPlace>> placeSearch(String query) async {
    final text = query.trim();
    if (text.length < placeSearchMinChars) return [];
    try {
      final response = await createPlaceSearchClient(
        BaseOptions(
          baseUrl: 'https://api.geoapify.com',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) => status == 200,
        ),
      ).get<Map<String, dynamic>>(
        '/v1/geocode/autocomplete',
        queryParameters: {
          'text': text,
          'apiKey': '444cf10f491e417d81d839ee58801389',
          'limit': '5',
          'lang': 'en',
          'filter': 'countrycode:za',
        },
      );
      return parsePlaceSuggestions(response.data);
    } on PlaceSearchException {
      rethrow;
    } on DioException catch (e) {
      Logger().w(
        'Place search unavailable: type=${e.type.name} '
        'http=${e.response?.statusCode ?? 'none'}',
      );
      throw PlaceSearchException(e.response?.statusCode);
    } catch (e) {
      Logger().w('Place search failed: ${e.runtimeType}');
      throw const PlaceSearchException(null);
    }
  }

  /// The places in a Geoapify autocomplete response: the formatted address
  /// and its coordinates. A suggestion without an address or coordinates is
  /// skipped (never fatal for the others); duplicates are dropped.
  @visibleForTesting
  static List<GeoPlace> parsePlaceSuggestions(Object? body) {
    final features = body is Map ? body['features'] : null;
    if (features is! List) throw const PlaceSearchException(null);

    final places = <GeoPlace>[];
    final seen = <String>{};
    for (final feature in features) {
      final properties = feature is Map ? feature['properties'] : null;
      if (properties is! Map) continue;
      final address = properties['formatted'];
      final lat = properties['lat'];
      final lng = properties['lon'];
      if (address is! String || address.trim().isEmpty) continue;
      if (lat is! num || lng is! num) continue;
      if (!seen.add(address.trim())) continue;
      places.add(
        GeoPlace(
          address: address.trim(),
          lat: lat.toDouble(),
          lng: lng.toDouble(),
        ),
      );
    }
    return places;
  }
}

/// The address provider could not be asked, or answered with an error.
class PlaceSearchException implements Exception {
  const PlaceSearchException(this.statusCode);

  /// The provider's HTTP status, when it answered.
  final int? statusCode;

  @override
  String toString() => 'PlaceSearchException(http: ${statusCode ?? 'none'})';
}
