import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:injectable/injectable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';

/// What one [LocationService.refreshLocation] did.
enum LocationRefreshResult {
  /// A fresh, valid device position was sent to Laravel.
  sent,

  /// A position was sent recently; nothing was done.
  throttled,

  /// Location permission not granted (never prompted from here).
  permissionDenied,

  /// Location permission permanently denied; only device settings can fix it.
  permissionDeniedForever,

  /// Location services are switched off.
  serviceDisabled,

  /// No position within the time limit, or an invalid one (e.g. 0, 0):
  /// nothing was sent.
  unavailable,

  /// Laravel did not accept the position.
  failed,
}

/// The device's location services, behind a seam for tests.
class DeviceLocation {
  const DeviceLocation();

  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  Future<Position> currentPosition(Duration timeLimit) =>
      Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(timeLimit: timeLimit),
      );

  Future<Position?> lastKnownPosition() => Geolocator.getLastKnownPosition();
}

@LazySingleton()
class LocationService {
  LocationService({
    @ignoreParam DeviceLocation? device,
    @ignoreParam ProfileRepository? repository,
  })  : _device = device ?? const DeviceLocation(),
        _repository = repository;

  final DeviceLocation _device;
  final ProfileRepository? _repository;

  ProfileRepository get _repo => _repository ?? getIt<ProfileRepository>();

  /// How long to wait for a position fix before giving up.
  static const positionTimeLimit = Duration(seconds: 12);

  /// A last known position older than this is not used.
  static const maxLastKnownAge = Duration(minutes: 10);

  /// Refreshes closer together than this are skipped (unless forced).
  static const minRefreshInterval = Duration(minutes: 2);

  /// When positions are taken and refreshes throttled; replaceable in tests.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  DateTime? _lastSentAt;
  Future<LocationRefreshResult>? _inFlight;

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

  /// Sends the device's current position to Laravel (`PATCH /user/location`)
  /// so stylist distances are measured from where the customer is now.
  ///
  /// Never prompts for permission (that is [requestLocationPermission]'s
  /// job, behind the app's consent sheet), never waits longer than
  /// [positionTimeLimit] for a fix, and never sends an invalid position.
  /// Called at start-up, on resume and before booking; never blocks them.
  /// Concurrent calls share one refresh; [force] skips the throttle.
  Future<LocationRefreshResult> refreshLocation({bool force = false}) {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final lastSent = _lastSentAt;
    if (!force &&
        lastSent != null &&
        clock().difference(lastSent) < minRefreshInterval) {
      return Future.value(LocationRefreshResult.throttled);
    }
    // Block body: an arrow would hand whenComplete this same future.
    final refresh = _refresh().whenComplete(() {
      _inFlight = null;
    });
    _inFlight = refresh;
    return refresh;
  }

  Future<LocationRefreshResult> _refresh() async {
    try {
      if (!await _device.isServiceEnabled()) {
        return LocationRefreshResult.serviceDisabled;
      }
      switch (await _device.checkPermission()) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          break;
        case LocationPermission.deniedForever:
          return LocationRefreshResult.permissionDeniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationRefreshResult.permissionDenied;
      }

      final position = await _position();
      if (position == null ||
          !GeoPlace.isValidPair(position.latitude, position.longitude)) {
        Logger().w('LocationService: no valid position to send');
        return LocationRefreshResult.unavailable;
      }

      final result = await _repo.updateUserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
      return result.when(
        success: (_) {
          _lastSentAt = clock();
          return LocationRefreshResult.sent;
        },
        failure: (_) => LocationRefreshResult.failed,
      );
    } catch (e) {
      Logger().w('LocationService: refresh failed: ${e.runtimeType}');
      return LocationRefreshResult.unavailable;
    }
  }

  /// A fresh fix, or a recent last known position when no fix arrives in
  /// time.
  Future<Position?> _position() async {
    try {
      return await _device.currentPosition(positionTimeLimit);
    } on TimeoutException {
      Logger().w('LocationService: no position fix within the time limit');
    } catch (e) {
      Logger().w('LocationService: position failed: ${e.runtimeType}');
    }
    final last = await _device.lastKnownPosition().catchError((_) => null);
    if (last == null) return null;
    final age = clock().difference(last.timestamp);
    return age <= maxLastKnownAge ? last : null;
  }

  /// Right after the customer granted permission: send the position now.
  void sendLocationUpdateRequest() {
    unawaited(refreshLocation(force: true));
  }

  void sendConsentToUseLocation(bool consentGiven) {
    unawaited(_updateLocationConsentToServer(consentGiven: consentGiven));
  }

  Future<void> _updateLocationConsentToServer({
    required bool consentGiven,
  }) async {
    try {
      await _repo.updateLocationConsent(consentGiven);
      Fluttertoast.showToast(msg: 'Location consent updated');
    } catch (e, s) {
      Logger().e('LocationService: ', error: e, stackTrace: s);
    }
  }

  /// Fewer characters than this never call address search.
  static const placeSearchMinChars = 3;

  /// Creates the HTTP client for [placeSearch]; replaced in tests.
  @visibleForTesting
  static Dio Function() createPlaceSearchClient =
      () => getIt<HttpService>().client();

  /// Address suggestions in South Africa, from Laravel's address search
  /// (`GET /geocode/autocomplete`), which holds the provider key: the app
  /// carries none.
  ///
  /// Returns an empty list when nothing matches (or the query is shorter than
  /// [placeSearchMinChars]). Throws [PlaceSearchException] when search is not
  /// configured on the server or is unavailable, so the field can tell "no
  /// results" from "unavailable".
  Future<List<GeoPlace>> placeSearch(String query) async {
    final text = query.trim();
    if (text.length < placeSearchMinChars) return [];
    try {
      final response = await createPlaceSearchClient().get<Object?>(
        '/geocode/autocomplete',
        queryParameters: {'text': text},
        options: Options(
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );
      return parsePlaceSuggestions(response.data);
    } on PlaceSearchException {
      rethrow;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data;
      final code = body is Map ? body['code'] : null;
      Logger().w(
        'Place search unavailable: type=${e.type.name} '
        'http=${status ?? 'none'} code=${code ?? 'none'}',
      );
      // Too long or otherwise rejected: nothing can match.
      if (status == 422) return [];
      if (status == 503 && code == 'geocoding_not_configured') {
        throw const PlaceSearchException(
          PlaceSearchFailure.notConfigured,
          statusCode: 503,
        );
      }
      throw PlaceSearchException(
        PlaceSearchFailure.unavailable,
        statusCode: status,
      );
    } catch (e) {
      Logger().w('Place search failed: ${e.runtimeType}');
      throw const PlaceSearchException(PlaceSearchFailure.unavailable);
    }
  }

  /// The places in an address search response
  /// (`{"data": [{"address", "latitude", "longitude", "place_id"}]}`). A
  /// suggestion without an address or valid coordinates is skipped (never
  /// fatal for the others); duplicates are dropped.
  @visibleForTesting
  static List<GeoPlace> parsePlaceSuggestions(Object? body) {
    final data = body is Map ? body['data'] : null;
    if (data is! List) {
      throw const PlaceSearchException(PlaceSearchFailure.unavailable);
    }

    final places = <GeoPlace>[];
    final seen = <String>{};
    for (final item in data) {
      if (item is! Map) continue;
      final address = item['address'];
      final lat = item['latitude'];
      final lng = item['longitude'];
      final placeId = item['place_id'];
      if (address is! String || address.trim().isEmpty) continue;
      if (lat is! num || lng is! num || !GeoPlace.isValidPair(lat, lng)) {
        continue;
      }
      if (!seen.add(address.trim())) continue;
      places.add(
        GeoPlace(
          address: address.trim(),
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          placeId: placeId is String && placeId.isNotEmpty ? placeId : null,
        ),
      );
    }
    return places;
  }
}

enum PlaceSearchFailure {
  /// The server has no address search key configured.
  notConfigured,

  /// The server or the provider could not answer (auth, rate limit, outage,
  /// network).
  unavailable,
}

/// Address search could not be asked, or answered with an error.
class PlaceSearchException implements Exception {
  const PlaceSearchException(this.failure, {this.statusCode});

  final PlaceSearchFailure failure;

  /// The HTTP status, when the server answered.
  final int? statusCode;

  @override
  String toString() =>
      'PlaceSearchException(${failure.name}, http: ${statusCode ?? 'none'})';
}
