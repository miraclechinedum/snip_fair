import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_profile_details/customer_profile_details.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/domain/entities/seller_details/seller_details.dart';
import 'package:snip_fair/core/domain/entities/seller_portfolio_list/seller_portfolio.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/services/location_service.dart';
import 'package:snip_fair/core/utils/distance_format.dart';
import 'package:snip_fair/features/account/customer/personal_details/cubit/customer_personal_details_cubit.dart';
import 'package:snip_fair/features/account/seller/personal_details/cubit/seller_personal_details_cubit.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';
import 'package:snip_fair/features/stylists/onboard/cubit/stylist_onboard_cubit.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _FakeDevice implements DeviceLocation {
  bool enabled = true;
  LocationPermission permission = LocationPermission.whileInUse;

  /// The next fix; a [TimeoutException] when it does not arrive in time.
  Future<Position> Function() fix = () async => _position(-33.9249, 18.4241);
  Position? lastKnown;
  Duration? askedTimeLimit;
  var fixes = 0;
  var permissionRequests = 0;

  @override
  Future<bool> isServiceEnabled() async => enabled;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<Position> currentPosition(Duration timeLimit) {
    askedTimeLimit = timeLimit;
    fixes++;
    return fix();
  }

  @override
  Future<Position?> lastKnownPosition() async => lastKnown;
}

final _now = DateTime(2026, 11, 10, 12);

Position _position(double lat, double lng, {DateTime? at}) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: at ?? _now,
      accuracy: 12,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

const _orangeStreet =
    '72 Orange Street, Gardens, Cape Town, 8001, South Africa';

GeoPlace _picked() => GeoPlace(
      address: _orangeStreet,
      lat: -33.931,
      lng: 18.4155,
      placeId: 'place-72-orange',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(GeoPlace(address: ''));
  });

  group('distance display', () {
    test('unknown distance shows nothing (never "0 km")', () {
      expect(formatDistanceKm(null), isNull);
      expect(formatDistanceAway(null), isNull);
      expect(formatDistanceKm(double.nan), isNull);
      expect(formatDistanceKm(double.infinity), isNull);
      expect(formatDistanceKm(-1), isNull);
      expect(formatDistanceKm('not a number'), isNull);
    });

    test('under 1 km is "< 1 km away"', () {
      for (final km in [0, 0.0, 0.1, 0.3, 0.49, 0.5, 0.99]) {
        expect(formatDistanceAway(km), '< 1 km away', reason: '$km');
      }
    });

    test('under 10 km: one decimal place', () {
      expect(formatDistanceAway(1.0), '1.0 km away');
      expect(formatDistanceAway(1.04), '1.0 km away');
      expect(formatDistanceAway(1.05), '1.1 km away');
      expect(formatDistanceAway(2.35), '2.4 km away');
      expect(formatDistanceAway(4.72), '4.7 km away');
      expect(formatDistanceAway(9.94), '9.9 km away');
      expect(formatDistanceKm(3.2), '3.2 km');
      expect(formatDistanceKm(7), '7.0 km');
    });

    test('10 km and further: whole kilometres', () {
      expect(formatDistanceAway(9.96), '10 km away');
      expect(formatDistanceAway(10), '10 km away');
      expect(formatDistanceAway(12.6), '13 km away');
      expect(formatDistanceAway(1263.42), '1263 km away');
    });

    test('accepts the API number, and a numeric string', () {
      expect(formatDistanceKm('3.2'), '3.2 km');
    });
  });

  group('distance from the API (km or null)', () {
    Map<String, dynamic> stylist(Object? distance) =>
        {'id': 7, 'distance': distance};

    test('a stylist distance is parsed as km, null stays null', () {
      expect(SellerDetails.fromJson(stylist(4.72)).distance, 4.72);
      expect(SellerDetails.fromJson(stylist(3)).distance, 3.0);
      expect(SellerDetails.fromJson(stylist(0)).distance, 0.0);
      expect(SellerDetails.fromJson(stylist(null)).distance, isNull);
      expect(SellerDetails.fromJson({'id': 7}).distance, isNull);
    });

    test('an unavailable distance is never shown as 0 km', () {
      final unknown = SellerDetails.fromJson(stylist(null)).distance;
      final near = SellerDetails.fromJson(stylist(4.72)).distance;
      // A measured 0 is a real distance, not a placeholder.
      final measuredZero = SellerDetails.fromJson(stylist(0)).distance;
      expect(formatDistanceKm(unknown), isNull);
      expect(formatDistanceAway(near), '4.7 km away');
      expect(formatDistanceAway(measuredZero), '< 1 km away');
    });

    test('a portfolio distance is formatted with the same rules', () {
      Object? distanceOf(Object? km) =>
          SellerPortfolio.fromJson({'id': 3, 'distance': km}).distance;
      expect(formatDistanceKm(distanceOf(null)), isNull);
      expect(formatDistanceKm(distanceOf(12.6)), '13 km');
    });
  });

  group('GeoPlace', () {
    test('valid coordinates', () {
      expect(_picked().hasValidCoordinates, isTrue);
      expect(GeoPlace.isValidPair(-90, 180), isTrue);
    });

    test('a typed address has none, and (0, 0) is never valid', () {
      expect(GeoPlace(address: '5 Unlisted Lane').hasValidCoordinates, isFalse);
      for (final (lat, lng) in [
        (0, 0),
        (null, 18.4),
        (-33.9, null),
        (91, 18.4),
        (-33.9, 181),
        (double.nan, 18.4),
      ]) {
        expect(GeoPlace.isValidPair(lat, lng), isFalse, reason: '$lat,$lng');
      }
    });

    test('sends coordinates only when valid', () {
      expect(_picked().coordinateFields, {
        'address_latitude': -33.931,
        'address_longitude': 18.4155,
        'address_place_id': 'place-72-orange',
      });
      expect(GeoPlace(address: 'typed').coordinateFields, isEmpty);
      expect(
        GeoPlace(address: 'x', lat: 0, lng: 0).coordinateFields,
        isEmpty,
      );
    });
  });

  group('LocationService.refreshLocation', () {
    late _FakeDevice device;
    late _MockProfileRepository repo;
    late LocationService service;
    final originalClock = LocationService.clock;
    var now = _now;

    setUp(() {
      now = _now;
      LocationService.clock = () => now;
      device = _FakeDevice();
      repo = _MockProfileRepository();
      service = LocationService(device: device, repository: repo);
      when(
        () => repo.updateUserLocation(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracy: any(named: 'accuracy'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
    });

    tearDown(() => LocationService.clock = originalClock);

    int sent() {
      try {
        return verify(
          () => repo.updateUserLocation(
            latitude: any(named: 'latitude'),
            longitude: any(named: 'longitude'),
            accuracy: any(named: 'accuracy'),
          ),
        ).callCount;
      } on TestFailure {
        return 0;
      }
    }

    test('sends a valid position, with a bounded wait', () async {
      expect(await service.refreshLocation(), LocationRefreshResult.sent);

      verify(
        () => repo.updateUserLocation(
          latitude: -33.9249,
          longitude: 18.4241,
          accuracy: 12,
        ),
      ).called(1);
      expect(device.askedTimeLimit, LocationService.positionTimeLimit);
    });

    final refusals = {
      LocationPermission.denied: LocationRefreshResult.permissionDenied,
      LocationPermission.unableToDetermine:
          LocationRefreshResult.permissionDenied,
      LocationPermission.deniedForever:
          LocationRefreshResult.permissionDeniedForever,
    };
    for (final MapEntry(key: permission, value: result) in refusals.entries) {
      test('$permission: nothing is sent and nobody is prompted', () async {
        device.permission = permission;

        expect(await service.refreshLocation(), result);
        expect(device.fixes, 0);
        expect(sent(), 0);
      });
    }

    test('location services off: nothing is sent', () async {
      device.enabled = false;

      expect(
        await service.refreshLocation(),
        LocationRefreshResult.serviceDisabled,
      );
      expect(sent(), 0);
    });

    test('(0, 0) is never sent', () async {
      device.fix = () async => _position(0, 0);

      expect(
        await service.refreshLocation(),
        LocationRefreshResult.unavailable,
      );
      expect(sent(), 0);
    });

    test('no fix in time: a recent last known position is used', () async {
      device
        ..fix = (() async => throw TimeoutException('no fix'))
        ..lastKnown = _position(
          -33.93,
          18.42,
          at: _now.subtract(const Duration(minutes: 3)),
        );

      expect(await service.refreshLocation(), LocationRefreshResult.sent);
      verify(
        () => repo.updateUserLocation(
          latitude: -33.93,
          longitude: 18.42,
          accuracy: 12,
        ),
      ).called(1);
    });

    test('no fix in time and only a stale position: nothing is sent', () async {
      device
        ..fix = (() async => throw TimeoutException('no fix'))
        ..lastKnown = _position(
          -33.93,
          18.42,
          at: _now.subtract(const Duration(hours: 2)),
        );

      expect(
        await service.refreshLocation(),
        LocationRefreshResult.unavailable,
      );
      expect(sent(), 0);
    });

    test('no position at all: nothing is sent, nothing thrown', () async {
      device.fix = () async => throw const LocationServiceDisabledException();

      expect(
        await service.refreshLocation(),
        LocationRefreshResult.unavailable,
      );
      expect(sent(), 0);
    });

    test('refreshes are throttled; a forced one is not', () async {
      expect(await service.refreshLocation(), LocationRefreshResult.sent);
      now = now.add(const Duration(seconds: 30));
      expect(await service.refreshLocation(), LocationRefreshResult.throttled);
      expect(
        await service.refreshLocation(force: true),
        LocationRefreshResult.sent,
      );
      now = now.add(LocationService.minRefreshInterval);
      expect(await service.refreshLocation(), LocationRefreshResult.sent);
      expect(sent(), 3);
    });

    test('concurrent refreshes share one request', () async {
      final fix = Completer<Position>();
      device.fix = () => fix.future;

      final first = service.refreshLocation();
      final second = service.refreshLocation(force: true);
      fix.complete(_position(-33.9, 18.4));

      expect(await first, LocationRefreshResult.sent);
      expect(await second, LocationRefreshResult.sent);
      expect(device.fixes, 1);
      expect(sent(), 1);
    });

    test('a rejected update is reported and retried next time', () async {
      when(
        () => repo.updateUserLocation(
          latitude: any(named: 'latitude'),
          longitude: any(named: 'longitude'),
          accuracy: any(named: 'accuracy'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.failure(error: RemoteException.httpError(422)),
      );

      expect(await service.refreshLocation(), LocationRefreshResult.failed);
      // Not throttled: nothing was accepted.
      expect(await service.refreshLocation(), LocationRefreshResult.failed);
    });
  });

  group('booking: the distance is measured from where the customer is now', () {
    late _MockAppointmentRepository repo;

    setUp(() {
      repo = _MockAppointmentRepository();
      when(() => repo.customerFetchPortfolioById(id: any(named: 'id')))
          .thenAnswer(
        (_) async => ApiResult.success(
          data: SellerPortfolio(id: 3, userId: '8', price: 300),
        ),
      );
      var calls = 0;
      when(() => repo.customerFetchStylistById('8')).thenAnswer(
        (_) async => ApiResult.success(
          data: SellerDetails(distance: ++calls == 1 ? null : 0.3),
        ),
      );
    });

    Future<UpdateCreateAppointmentCubit> open(
      WidgetTester tester,
      Future<LocationRefreshResult> Function() refresh,
    ) async {
      final cubit = UpdateCreateAppointmentCubit(
        repo,
        refreshLocation: refresh,
      );
      addTearDown(cubit.close);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              cubit.initialize(context, portfolioId: '3');
              return const SizedBox();
            },
          ),
        ),
      );
      return cubit;
    }

    testWidgets('a new position refreshes the stylist distance',
        (tester) async {
      final location = Completer<LocationRefreshResult>();
      final cubit = await open(tester, () => location.future);
      await tester.pump();
      expect(cubit.state.fetchSellerDetailsState.data?.distance, isNull);

      location.complete(LocationRefreshResult.sent);
      await tester.pump();
      await tester.pump();

      expect(cubit.state.fetchSellerDetailsState.data?.distance, 0.3);
      verify(() => repo.customerFetchStylistById('8')).called(2);
    });

    for (final result in [
      LocationRefreshResult.permissionDenied,
      LocationRefreshResult.permissionDeniedForever,
      LocationRefreshResult.serviceDisabled,
      LocationRefreshResult.unavailable,
    ]) {
      testWidgets('$result: booking goes on, distance stays unknown',
          (tester) async {
        final cubit = await open(tester, () async => result);
        await tester.pump();
        await tester.pump();

        expect(cubit.state.fetchPortfolioState.hasSuccess, isTrue);
        expect(cubit.state.fetchSellerDetailsState.hasSuccess, isTrue);
        expect(cubit.state.fetchSellerDetailsState.data?.distance, isNull);
        verify(() => repo.customerFetchStylistById('8')).called(1);
      });
    }

    testWidgets('a failing refresh never breaks the booking screen',
        (tester) async {
      final cubit = await open(tester, () async => throw StateError('gps'));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.fetchSellerDetailsState.hasSuccess, isTrue);
    });
  });

  group('address coordinates are sent with the address', () {
    late _MockProfileRepository repo;

    setUp(() {
      repo = _MockProfileRepository();
      when(
        () => repo.updateBusinessInfo(
          businessName: any(named: 'businessName'),
          country: any(named: 'country'),
          yearsOfExperience: any(named: 'yearsOfExperience'),
          bio: any(named: 'bio'),
          addressPlace: any(named: 'addressPlace'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      when(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          addressPlace: any(named: 'addressPlace'),
          yearsOfExperience: any(named: 'yearsOfExperience'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      when(
        () => repo.updateCustomerProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          addressPlace: any(named: 'addressPlace'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
    });

    GeoPlace? sentBusinessPlace() => verify(
          () => repo.updateBusinessInfo(
            businessName: any(named: 'businessName'),
            country: any(named: 'country'),
            yearsOfExperience: any(named: 'yearsOfExperience'),
            bio: any(named: 'bio'),
            addressPlace: captureAny(named: 'addressPlace'),
          ),
        ).captured.single as GeoPlace?;

    test('stylist onboarding: a picked address sends its coordinates',
        () async {
      final cubit = StylistOnboardCubit(repo);
      addTearDown(cubit.close);

      cubit.onAddressChanged(_orangeStreet, place: _picked());
      await cubit.updateBusinessInfo();

      final place = sentBusinessPlace();
      expect(place?.address, _orangeStreet);
      expect(place?.coordinateFields['address_latitude'], -33.931);
      expect(place?.coordinateFields['address_longitude'], 18.4155);
    });

    test('stylist onboarding: a typed address sends no coordinates', () async {
      final cubit = StylistOnboardCubit(repo);
      addTearDown(cubit.close);

      cubit
        ..onAddressChanged(_orangeStreet, place: _picked())
        // Edited by hand afterwards: the old coordinates no longer apply.
        ..onAddressChanged('72 Orange St, Cape Town');
      await cubit.updateBusinessInfo();

      expect(sentBusinessPlace(), isNull);
    });

    test('stylist profile sends the picked address coordinates', () async {
      final cubit = SellerPersonalDetailsCubit(repo);
      addTearDown(cubit.close);

      cubit.onAddressChanged(_orangeStreet, place: _picked());
      await cubit.updateBusinessInfo(StylistProfileDetails());

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          addressPlace: captureAny(named: 'addressPlace'),
          yearsOfExperience: any(named: 'yearsOfExperience'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).captured.single as GeoPlace?;
      expect(captured?.placeId, 'place-72-orange');
    });

    test('customer profile sends the picked address coordinates', () async {
      final cubit = CustomerPersonalDetailsCubit(repo);
      addTearDown(cubit.close);

      cubit.onAddressChanged(_orangeStreet, place: _picked());
      await cubit.updateProfile(CustomerProfileDetails());

      final captured = verify(
        () => repo.updateCustomerProfile(
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          addressPlace: captureAny(named: 'addressPlace'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).captured.single as GeoPlace?;
      expect(captured?.hasValidCoordinates, isTrue);
    });
  });

  group('the requests carry the coordinates', () {
    late List<RequestOptions> requests;

    setUp(() {
      requests = [];
      getIt
        ..allowReassignment = true
        ..registerSingleton<HttpRequestExceptionMapper>(
          HttpRequestExceptionMapper(ErrorResponseMapper()),
        )
        ..registerSingleton<HttpService>(_FakeHttpService(requests));
    });
    tearDown(getIt.reset);

    test('PATCH /stylist/basic/profile', () async {
      await SnipFairBackendRemoteSource().updateBusinessInfo(
        businessName: 'Glow',
        country: _orangeStreet,
        yearsOfExperience: '4',
        bio: 'Bio',
        addressPlace: _picked(),
      );

      expect(requests.single.path, '/stylist/basic/profile');
      expect(requests.single.data, containsPair('country', _orangeStreet));
      expect(requests.single.data, containsPair('address_latitude', -33.931));
      expect(requests.single.data, containsPair('address_longitude', 18.4155));
      expect(
        requests.single.data,
        containsPair('address_place_id', 'place-72-orange'),
      );
    });

    test('PATCH /user (location settings): typed address, no coordinates',
        () async {
      await SnipFairBackendRemoteSource().updateUser(
        useLocation: false,
        address: '5 Unlisted Lane',
        addressPlace: GeoPlace(address: '5 Unlisted Lane'),
      );

      final data = requests.single.data as Map;
      expect(data['country'], '5 Unlisted Lane');
      expect(data.containsKey('address_latitude'), isFalse);
      expect(data.containsKey('address_longitude'), isFalse);
      expect(data.values, isNot(contains(0)));
    });

    test('PATCH /stylist/profile (form data)', () async {
      await SnipFairBackendRemoteSource().updateStylistProfile(
        businessName: 'Glow',
        country: _orangeStreet,
        addressPlace: _picked(),
      );

      final fields = {
        for (final f in (requests.single.data as FormData).fields)
          f.key: f.value,
      };
      expect(fields['address_latitude'], '-33.931');
      expect(fields['address_longitude'], '18.4155');
      expect(fields['address_place_id'], 'place-72-orange');
    });

    test('coordinates are never sent without their address', () async {
      await SnipFairBackendRemoteSource().updateUser(
        useLocation: true,
        addressPlace: _picked(),
      );

      expect(
        (requests.single.data as Map).keys,
        isNot(contains('address_latitude')),
      );
    });
  });
}

class _FakeHttpService implements HttpService {
  _FakeHttpService(this.requests);

  final List<RequestOptions> requests;

  @override
  Dio client({
    bool requireAuth = true,
    bool optionalAuth = false,
    bool isFormDataRequest = false,
  }) =>
      Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8002/api'))
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) {
              requests.add(options);
              handler.resolve(
                Response<Map<String, dynamic>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const {},
                ),
              );
            },
          ),
        );
}
