import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/geo_place.dart';
import 'package:snip_fair/core/presentation/widgets/custom_text_field.dart';
import 'package:snip_fair/core/services/location_service.dart';
import 'package:snip_fair/features/appointments/update_create_appointment/cubit/update_create_appointment_cubit.dart';

/// A suggestion as Laravel's address search (`GET /geocode/autocomplete`)
/// returns it.
Map<String, dynamic> _suggestion(
  String address, {
  num? lat = -33.9,
  num? lng = 18,
  String? placeId = 'place-1',
}) =>
    {
      'address': address,
      'latitude': lat,
      'longitude': lng,
      'place_id': placeId,
    };

class _Adapter implements HttpClientAdapter {
  _Adapter(this.reply);

  final Future<ResponseBody> Function(RequestOptions) reply;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return reply(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(Object body, [int status = 200]) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _FakeLocationService extends Fake implements LocationService {
  _FakeLocationService(this.answer);

  Future<List<GeoPlace>> Function(String query) answer;
  final queries = <String>[];

  @override
  Future<List<GeoPlace>> placeSearch(String query) {
    queries.add(query);
    return answer(query);
  }
}

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

void main() {
  group('LocationService.placeSearch', () {
    late _Adapter adapter;
    final original = LocationService.createPlaceSearchClient;

    void serve(Future<ResponseBody> Function(RequestOptions) reply) {
      adapter = _Adapter(reply);
      LocationService.createPlaceSearchClient = () =>
          Dio(BaseOptions(baseUrl: 'https://api.example.test/api'))
            ..httpClientAdapter = adapter;
    }

    tearDown(() => LocationService.createPlaceSearchClient = original);

    test('asks Laravel, never the provider, and sends no key', () async {
      serve(
        (_) async => _json({
          'data': [
            _suggestion('12 Long Street, Cape Town, 8001, South Africa'),
            _suggestion(
              '12 Loop Street, Cape Town, 8001, South Africa',
              lat: -33.92,
              lng: 18.42,
              placeId: 'place-loop',
            ),
          ],
        }),
      );

      final places = await LocationService().placeSearch('  12 Lo ');

      expect(places.map((p) => p.address), [
        '12 Long Street, Cape Town, 8001, South Africa',
        '12 Loop Street, Cape Town, 8001, South Africa',
      ]);
      expect([places.first.lat, places.first.lng], [-33.9, 18.0]);
      expect([places.last.lat, places.last.lng], [-33.92, 18.42]);
      expect(places.last.placeId, 'place-loop');

      final request = adapter.requests.single;
      expect(request.uri.host, 'api.example.test');
      expect(request.uri.path, '/api/geocode/autocomplete');
      expect(request.queryParameters, {'text': '12 Lo'});
      expect(request.uri.toString(), isNot(contains('apiKey')));
      expect(request.uri.toString(), isNot(contains('geoapify')));
    });

    for (final query in [
      '72 orange street capetown',
      '72 Orange Street, Cape Town',
    ]) {
      test('"$query" finds 72 Orange Street with its coordinates', () async {
        serve(
          (_) async => _json({
            'data': [
              _suggestion(
                '72 Orange Street, Gardens, Cape Town, 8001, South Africa',
                lat: -33.931,
                lng: 18.4155,
                placeId: 'place-72-orange',
              ),
            ],
          }),
        );

        final places = await LocationService().placeSearch(query);

        expect(adapter.requests.single.queryParameters['text'], query);
        expect(places.single.address,
            '72 Orange Street, Gardens, Cape Town, 8001, South Africa');
        expect([places.single.lat, places.single.lng], [-33.931, 18.4155]);
        expect(places.single.placeId, 'place-72-orange');
        expect(places.single.hasValidCoordinates, isTrue);
      });
    }

    test('no matches is an empty list, not an error', () async {
      serve((_) async => _json({'data': <Object>[]}));

      expect(await LocationService().placeSearch('zzzzqx'), isEmpty);
    });

    test('a suggestion without valid coordinates is skipped, not fatal',
        () async {
      serve(
        (_) async => _json({
          'data': [
            _suggestion('No coordinates', lat: null, lng: null),
            _suggestion('Null Island', lat: 0, lng: 0),
            _suggestion('Out of range', lat: 91, lng: 18),
            'oops',
            _suggestion('7 Kloof Street, Cape Town, South Africa'),
            _suggestion('7 Kloof Street, Cape Town, South Africa'),
          ],
        }),
      );

      final places = await LocationService().placeSearch('7 Kloof');
      expect(places.map((p) => p.address),
          ['7 Kloof Street, Cape Town, South Africa']);
    });

    test('fewer than three characters never calls the server', () async {
      serve((_) async => _json({
            'data': [_suggestion('x')]
          }));

      expect(await LocationService().placeSearch('12'), isEmpty);
      expect(await LocationService().placeSearch('   '), isEmpty);
      expect(adapter.requests, isEmpty);
    });

    test('no key on the server is "not configured"', () async {
      serve(
        (_) async => _json(
          {'code': 'geocoding_not_configured', 'message': 'not configured'},
          503,
        ),
      );

      await expectLater(
        LocationService().placeSearch('12 Long Street'),
        throwsA(
          isA<PlaceSearchException>().having(
            (e) => e.failure,
            'failure',
            PlaceSearchFailure.notConfigured,
          ),
        ),
      );
    });

    for (final (status, body) in [
      (503, {'code': 'geocoding_unavailable', 'reason': 'provider_auth'}),
      (503, {'code': 'geocoding_unavailable', 'reason': 'network'}),
      (429, {'message': 'Too Many Attempts.'}),
      (500, {'message': 'Server Error'}),
      (401, {'message': 'Unauthenticated.'}),
    ]) {
      test('HTTP $status ${body['reason'] ?? ''} is "unavailable"', () async {
        serve((_) async => _json(body, status));

        await expectLater(
          LocationService().placeSearch('12 Long Street'),
          throwsA(
            isA<PlaceSearchException>()
                .having(
                    (e) => e.failure, 'failure', PlaceSearchFailure.unavailable)
                .having((e) => e.statusCode, 'statusCode', status),
          ),
        );
      });
    }

    test('a query the server rejects (422) is an empty list', () async {
      serve((_) async => _json({'message': 'too long'}, 422));

      expect(await LocationService().placeSearch('12 Long Street'), isEmpty);
    });

    test('a timeout or no connection is "unavailable"', () async {
      for (final error in [
        (RequestOptions o) => DioException.connectionTimeout(
              timeout: const Duration(seconds: 10),
              requestOptions: o,
            ),
        (RequestOptions o) => DioException.connectionError(
              requestOptions: o,
              reason: 'offline',
            ),
      ]) {
        serve((options) async => throw error(options));

        await expectLater(
          LocationService().placeSearch('12 Long Street'),
          throwsA(
            isA<PlaceSearchException>().having(
              (e) => e.failure,
              'failure',
              PlaceSearchFailure.unavailable,
            ),
          ),
        );
      }
    });

    test('an unexpected body is "unavailable"', () async {
      serve((_) async => _json({'features': <Object>[]}));

      await expectLater(
        LocationService().placeSearch('12 Long Street'),
        throwsA(isA<PlaceSearchException>()),
      );
    });

    test('the app carries no Geoapify key', () {
      final source =
          File('lib/core/services/location_service.dart').readAsStringSync();
      expect(source, isNot(contains('apiKey')));
      expect(source, isNot(contains('api.geoapify.com')));
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        expect(
          file.readAsStringSync(),
          isNot(contains('api.geoapify.com')),
          reason: file.path,
        );
      }
      expect(
        const PlaceSearchException(
          PlaceSearchFailure.unavailable,
          statusCode: 503,
        ).toString(),
        'PlaceSearchException(unavailable, http: 503)',
      );
    });
  });

  group('CustomPlaceSearchField', () {
    late _FakeLocationService service;
    GeoPlace? selected;
    var selections = 0;

    setUp(() {
      selected = null;
      selections = 0;
      service = _FakeLocationService((_) async => []);
      if (getIt.isRegistered<LocationService>()) {
        getIt.unregister<LocationService>();
      }
      getIt.registerSingleton<LocationService>(service);
    });

    tearDown(() => getIt.unregister<LocationService>());

    Future<void> pumpField(
      WidgetTester tester, {
      double topSpace = 0,
    }) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(height: topSpace),
                    CustomPlaceSearchField(
                      label: 'Location',
                      onSelected: (place) {
                        selected = place;
                        selections++;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    Future<void> type(WidgetTester tester, String text) async {
      await tester.enterText(find.byType(TextField), text);
      await tester.pump();
    }

    Future<void> waitForSuggestions(WidgetTester tester) async {
      await tester.pump(placeSearchDebounce);
      await tester.pumpAndSettle();
    }

    testWidgets('suggestions appear beneath the field and can be picked',
        (tester) async {
      service.answer = (_) async => [
            GeoPlace(
              address: '12 Long Street, Cape Town',
              lat: -33.9,
              lng: 18.4,
            ),
            GeoPlace(
              address: '12 Loop Street, Cape Town',
              lat: -33.92,
              lng: 18.42,
              placeId: 'place-loop',
            ),
          ];
      await pumpField(tester);

      await tester.tap(find.byType(TextField));
      await type(tester, '12 Lo');
      await waitForSuggestions(tester);

      final suggestion = find.text('12 Loop Street, Cape Town');
      expect(suggestion, findsOneWidget);
      expect(find.text('12 Long Street, Cape Town'), findsOneWidget);
      expect(
        tester.getTopLeft(suggestion).dy,
        greaterThan(tester.getBottomLeft(find.byType(TextField)).dy),
        reason: 'shown beneath the input',
      );

      await tester.tap(suggestion);
      await tester.pumpAndSettle();

      expect(selected?.address, '12 Loop Street, Cape Town');
      expect([selected?.lat, selected?.lng], [-33.92, 18.42]);
      expect(selected?.placeId, 'place-loop');
      expect(selections, 1);
      // Dismissed: the picked address replaces the input and its list.
      expect(find.byType(TextField), findsNothing);
      expect(find.text('12 Long Street, Cape Town'), findsNothing);
      expect(find.text('12 Loop Street, Cape Town'), findsOneWidget);
    });

    testWidgets('rapid typing makes one request, for the final text',
        (tester) async {
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      for (final text in ['12 ', '12 L', '12 Lo', '12 Lon', '12 Long']) {
        await type(tester, text);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await waitForSuggestions(tester);

      expect(service.queries, ['12 Long']);
    });

    testWidgets('fewer than three characters never searches', (tester) async {
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '12');
      await waitForSuggestions(tester);

      expect(service.queries, isEmpty);
      expect(find.byKey(const Key('place_search_empty')), findsNothing);
    });

    testWidgets('no matches shows an empty state', (tester) async {
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, 'zzzzqx');
      await waitForSuggestions(tester);

      expect(find.text(placeSearchEmptyMessage), findsOneWidget);
    });

    testWidgets('an unavailable service says so, not "no matches"',
        (tester) async {
      service.answer = (_) async => throw const PlaceSearchException(
            PlaceSearchFailure.unavailable,
            statusCode: 503,
          );
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '12 Long Street');
      await waitForSuggestions(tester);

      expect(find.text(placeSearchErrorMessage), findsOneWidget);
      expect(find.text(placeSearchEmptyMessage), findsNothing);
      expect(find.textContaining('No Items Found'), findsNothing);
    });

    testWidgets('an unconfigured service says so, not "no matches"',
        (tester) async {
      service.answer = (_) async => throw const PlaceSearchException(
            PlaceSearchFailure.notConfigured,
            statusCode: 503,
          );
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '12 Long Street');
      await waitForSuggestions(tester);

      expect(find.text(placeSearchNotConfiguredMessage), findsOneWidget);
      expect(find.text(placeSearchEmptyMessage), findsNothing);
      expect(find.text(placeSearchErrorMessage), findsNothing);
    });

    testWidgets('a network failure is "unavailable", never "no items"',
        (tester) async {
      service.answer = (_) async => throw Exception('socket closed');
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '12 Long Street');
      await waitForSuggestions(tester);

      expect(find.text(placeSearchErrorMessage), findsOneWidget);
      expect(find.textContaining('No Items Found'), findsNothing);
    });

    testWidgets('a slow response shows progress, then the suggestions',
        (tester) async {
      final reply = Completer<List<GeoPlace>>();
      service.answer = (_) => reply.future;
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '12 Long');
      await tester.pump(placeSearchDebounce);
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      reply.complete(
        [GeoPlace(address: '12 Long Street', lat: -33.9, lng: 18.4)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('12 Long Street'), findsOneWidget);
    });

    testWidgets('near the bottom of the screen the list opens upward',
        (tester) async {
      service.answer = (_) async =>
          [GeoPlace(address: '12 Long Street', lat: -33.9, lng: 18.4)];
      await pumpField(tester, topSpace: 700);
      await tester.tap(find.byType(TextField));

      await type(tester, '12 Long');
      await waitForSuggestions(tester);

      final suggestion = find.text('12 Long Street');
      expect(suggestion, findsOneWidget);
      final rect = tester.getRect(suggestion);
      expect(rect.height, greaterThan(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(
        rect.bottom,
        lessThanOrEqualTo(tester.getTopLeft(find.byType(TextField)).dy),
        reason: 'no room below, so it opens above the input',
      );
    });

    testWidgets('an address can still be typed by hand', (tester) async {
      await pumpField(tester);
      await tester.tap(find.byType(TextField));

      await type(tester, '5 Unlisted Lane, Paarl');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(selected?.address, '5 Unlisted Lane, Paarl');
      // No made-up (0, 0) coordinates for a typed address.
      expect([selected?.lat, selected?.lng], [null, null]);
      expect(selected?.hasValidCoordinates, isFalse);
    });
  });

  group('booking address', () {
    test('a picked suggestion keeps its coordinates; clearing clears', () {
      final cubit = UpdateCreateAppointmentCubit(_MockAppointmentRepository());
      addTearDown(cubit.close);

      cubit.onPlaceSelected(
        GeoPlace(address: '12 Loop Street, Cape Town', lat: -33.92, lng: 18.42),
      );
      expect(cubit.state.address, '12 Loop Street, Cape Town');
      expect(cubit.state.addressPlace?.lat, -33.92);
      expect(cubit.state.addressPlace?.lng, 18.42);

      // Typed by hand: the address, but no (made-up) coordinates.
      cubit.onPlaceSelected(GeoPlace(address: '5 Unlisted Lane'));
      expect(cubit.state.address, '5 Unlisted Lane');
      expect(cubit.state.addressPlace, isNull);

      // (0, 0) from anywhere is never kept as a location.
      cubit.onPlaceSelected(GeoPlace(address: 'Null Island', lat: 0, lng: 0));
      expect(cubit.state.addressPlace, isNull);

      cubit.onPlaceSelected(null);
      expect(cubit.state.address, isNull);
      expect(cubit.state.addressPlace, isNull);
    });
  });
}
