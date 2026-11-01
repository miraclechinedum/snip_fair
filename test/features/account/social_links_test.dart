import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/datasources/remote/snip_fair_backend_remote_source.dart';
import 'package:snip_fair/core/data/models/remote/mapper/error_response_mapper.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/social.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/errors/exception/mapper/http_request_exception_mapper.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/network/http_service.dart';
import 'package:snip_fair/core/presentation/widgets/social_links_view.dart';
import 'package:snip_fair/core/utils/social_links.dart';
import 'package:snip_fair/features/account/seller/personal_details/cubit/seller_personal_details_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_verification/cubit/seller_profile_verification_cubit.dart';
import 'package:snip_fair/features/account/seller/profile_verification/views/seller_profile_verification_screen.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _works = [
  'storage/works/one.jpg',
  'storage/works/two.jpg',
];

StylistProfileDetails _profile() => StylistProfileDetails.fromJson({
      'user': {
        'stylist_profile': {
          'business_name': 'Glow Studio',
          'works': _works,
          'socials': [
            {
              'social_app': 'Instagram',
              'url': 'https://www.instagram.com/glow',
            },
            {
              'social_app': 'TikTok',
              'url': 'https://www.tiktok.com/@glow',
            },
          ],
        },
      },
    });

void main() {
  setUpAll(() => registerFallbackValue(<Social>[]));

  group('SocialLinks.isValidProfileUrl (mirrors Laravel SocialProfileUrl)', () {
    test('accepts full https profile URLs', () {
      for (final url in [
        'https://www.instagram.com/yourname',
        'https://www.tiktok.com/@yourname',
        'https://facebook.com/some.page',
        '  https://x.com/yourname  ',
      ]) {
        expect(SocialLinks.isValidProfileUrl(url), isTrue, reason: url);
      }
    });

    test('rejects handles, http, bare domains and credentials', () {
      for (final url in [
        '@yourname',
        'yourname',
        'instagram.com/yourname',
        'http://www.instagram.com/yourname',
        'https://localhost/yourname',
        'https://user:pass@instagram.com/x',
        '',
        null,
      ]) {
        expect(SocialLinks.isValidProfileUrl(url), isFalse, reason: '$url');
      }
    });
  });

  group('SocialLinks.displayable', () {
    test('keeps valid links and drops empty or unsafe ones', () {
      final links = SocialLinks.displayable([
        (platform: 'Instagram', url: 'https://www.instagram.com/glow'),
        (platform: 'TikTok', url: 'https://www.tiktok.com/@glow'),
        (platform: 'YouTube', url: 'https://youtube.com/@glow'),
        (platform: 'Empty', url: ''),
        (platform: 'Blank', url: '   '),
        (platform: 'Null', url: null),
        (platform: 'Handle', url: '@glow'),
        (platform: 'Script', url: 'javascript:alert(1)'),
        (platform: null, url: 'https://www.pinterest.com/glow'),
      ]);

      expect(links.map((l) => l.platform), [
        'Instagram',
        'TikTok',
        'YouTube',
        'Pinterest',
      ]);
      expect(links.first.uri.toString(), 'https://www.instagram.com/glow');
      expect(SocialLinks.iconFor(links.first), Iconsax.instagram);
      expect(SocialLinks.iconFor(links[1]), Iconsax.link_2);
    });

    test('no socials: nothing to show', () {
      expect(SocialLinks.displayable(const []), isEmpty);
    });
  });

  group('SocialLinksView', () {
    late List<Uri> opened;
    late Future<bool> Function(Uri) original;

    setUp(() {
      opened = [];
      original = SocialLinksView.launcher;
      SocialLinksView.launcher = (uri) async {
        opened.add(uri);
        return true;
      };
    });
    tearDown(() => SocialLinksView.launcher = original);

    Future<void> pump(WidgetTester tester, List<SocialProfileLink> links) =>
        tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, __) => MaterialApp(
              home: Scaffold(
                body: SocialLinksView(title: 'Social media', links: links),
              ),
            ),
          ),
        );

    final links = SocialLinks.displayable([
      (platform: 'Instagram', url: 'https://www.instagram.com/glow'),
      (platform: 'TikTok', url: 'https://www.tiktok.com/@glow'),
    ]);

    testWidgets('shows each link with its platform name and label',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, links);

      expect(find.text('Instagram'), findsOneWidget);
      expect(find.text('TikTok'), findsOneWidget);
      expect(find.bySemanticsLabel('Open Instagram profile'), findsOneWidget);
      expect(find.bySemanticsLabel('Open TikTok profile'), findsOneWidget);
      expect(
        tester.getSize(find.byKey(Key('social_link_${links.first.uri}'))).height,
        greaterThanOrEqualTo(48),
      );
      handle.dispose();
    });

    testWidgets('tapping opens the exact profile URL', (tester) async {
      await pump(tester, links);

      await tester.tap(find.text('TikTok'));
      await tester.pump();

      expect(opened.single.toString(), 'https://www.tiktok.com/@glow');
    });

    testWidgets('a failed launch shows a message instead of crashing',
        (tester) async {
      SocialLinksView.launcher = (_) async => throw StateError('no handler');
      await pump(tester, links);

      await tester.tap(find.text('Instagram'));
      await tester.pumpAndSettle();

      expect(
        find.text("We couldn't open Instagram. Please try again later."),
        findsOneWidget,
      );
    });

    testWidgets('no links: no title, no placeholders', (tester) async {
      await pump(tester, const []);

      expect(find.text('Social media'), findsNothing);
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('editing social links', () {
    late _MockProfileRepository repo;
    late SellerProfileVerificationCubit cubit;

    setUp(() {
      repo = _MockProfileRepository();
      when(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: any(named: 'medias'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          yearsOfExperience: any(named: 'yearsOfExperience'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      cubit = SellerProfileVerificationCubit(repo, _profile());
    });
    tearDown(() => cubit.close());

    test('existing links are loaded into the editor', () {
      expect(cubit.state.socials.map((s) => s.socialApp), [
        'Instagram',
        'TikTok',
      ]);
    });

    test('a handle is rejected; a full https URL is added', () {
      cubit
        ..onSocialAppChanged('Facebook')
        ..onSocialUrlChanged('@glow');
      expect(cubit.state.canAddSocial, isFalse);
      expect(cubit.state.socialLinkUrlError, SocialLinks.invalidUrlMessage);
      cubit.onAddSocialAccount();
      expect(cubit.state.socials, hasLength(2));

      cubit
        ..onSocialUrlChanged(' https://facebook.com/glow ')
        ..onAddSocialAccount();
      expect(cubit.state.socials, hasLength(3));
      expect(cubit.state.socials.last.url, 'https://facebook.com/glow');
      expect(cubit.state.socialLinkUrlError, isNull);
    });

    test('an existing link can be edited in place', () {
      cubit.onEditSocialAccount(1);
      expect(cubit.state.socialApp.value, 'TikTok');
      expect(cubit.state.socialLink.value, 'https://www.tiktok.com/@glow');

      cubit
        ..onSocialUrlChanged('https://www.tiktok.com/@glowstudio')
        ..onAddSocialAccount();

      expect(cubit.state.socials, hasLength(2));
      expect(cubit.state.socials[1].url, 'https://www.tiktok.com/@glowstudio');
      expect(cubit.state.editingSocialIndex, isNull);
    });

    test('cancelling an edit leaves the link unchanged', () {
      cubit
        ..onEditSocialAccount(0)
        ..onSocialUrlChanged('https://www.instagram.com/other')
        ..onCancelSocialEdit();

      expect(cubit.state.socials[0].url, 'https://www.instagram.com/glow');
      expect(cubit.state.editingSocialIndex, isNull);
    });

    test('a link can be removed', () {
      cubit.onRemoveSocialAccount(cubit.state.socials.first);
      expect(cubit.state.socials.single.socialApp, 'TikTok');
    });

    test('a socials-only save omits media so work images are kept',
        () async {
      cubit
        ..onSocialAppChanged('YouTube')
        ..onSocialUrlChanged('https://youtube.com/@glow')
        ..onAddSocialAccount();

      await cubit.submitRequirements();

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: 'Glow Studio',
          socials: captureAny(named: 'socials'),
          medias: captureAny(named: 'medias'),
        ),
      ).captured;
      expect((captured[0] as List<Social>).map((s) => s.url), [
        'https://www.instagram.com/glow',
        'https://www.tiktok.com/@glow',
        'https://youtube.com/@glow',
      ]);
      expect(captured[1], isNull);
    });

    test('changed work images are sent', () async {
      cubit.onSelectImages([..._works, '/tmp/new.jpg']);

      await cubit.submitRequirements();

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: captureAny(named: 'medias'),
        ),
      ).captured;
      expect(captured.single, [..._works, '/tmp/new.jpg']);
    });

    test('personal details saves never send socials or media', () async {
      final details = SellerPersonalDetailsCubit(repo);
      addTearDown(details.close);

      await details.updateBusinessInfo(_profile());

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: captureAny(named: 'socials'),
          medias: captureAny(named: 'medias'),
          phone: any(named: 'phone'),
          country: any(named: 'country'),
          yearsOfExperience: any(named: 'yearsOfExperience'),
          bio: any(named: 'bio'),
          gender: any(named: 'gender'),
        ),
      ).captured;
      expect(captured, [null, null]);
    });
  });

  group('approved stylists edit social links on their own', () {
    late _MockProfileRepository repo;
    late SellerProfileVerificationCubit cubit;

    setUp(() {
      repo = _MockProfileRepository();
      when(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: any(named: 'medias'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      cubit = SellerProfileVerificationCubit(repo, _profile());
    });
    tearDown(() => cubit.close());

    test('save is only offered once the links change', () {
      expect(cubit.state.canSaveSocialLinks, isFalse);
      cubit
        ..onEditSocialAccount(0)
        ..onSocialUrlChanged('https://www.instagram.com/glowstudio')
        ..onAddSocialAccount();
      expect(cubit.state.canSaveSocialLinks, isTrue);
    });

    test('the last link cannot be removed and saved', () {
      cubit
        ..onRemoveSocialAccount(cubit.state.socials.first)
        ..onRemoveSocialAccount(cubit.state.socials.first);
      expect(cubit.state.socials, isEmpty);
      expect(cubit.state.canSaveSocialLinks, isFalse);
    });

    test('saving sends socials only — work images are not sent', () async {
      cubit.onRemoveSocialAccount(cubit.state.socials.last);

      await cubit.saveSocialLinks();

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: 'Glow Studio',
          socials: captureAny(named: 'socials'),
          medias: captureAny(named: 'medias'),
        ),
      ).captured;
      expect((captured[0] as List<Social>).single.socialApp, 'Instagram');
      expect(captured[1], isNull);
      expect(cubit.state.submitState.hasSuccess, isTrue);
    });

    testWidgets('the editor stays available after approval', (tester) async {
      final profileCubit = SellerProfileMgtCubit(repo);
      addTearDown(profileCubit.close);
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'profile_completeness': {'status_approved': true},
          }),
        ),
      );
      await profileCubit.getProfileDetails();
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider.value(value: cubit),
              BlocProvider.value(value: profileCubit),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(child: SocialMediaAccountsView()),
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('social_edit_0')), findsOneWidget);
      expect(find.byKey(const Key('social_remove_1')), findsOneWidget);
      expect(find.byKey(const Key('social_link_field')), findsOneWidget);
      expect(find.byKey(const Key('social_keep_one_hint')), findsNothing);

      await tester.tap(find.byKey(const Key('social_remove_1')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('social_remove_0')));
      await tester.pump();

      expect(find.byKey(const Key('social_keep_one_hint')), findsOneWidget);
    });
  });

  group('PATCH /stylist/profile form data', () {
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

    Future<Map<String, String>> send({
      List<Social>? socials,
      List<String>? medias,
    }) async {
      await SnipFairBackendRemoteSource().updateStylistProfile(
        businessName: 'Glow Studio',
        socials: socials,
        medias: medias,
      );
      final data = requests.single.data as FormData;
      return {for (final f in data.fields) f.key: f.value};
    }

    test('socials only: no media field is sent', () async {
      final fields = await send(
        socials: [
          Social(socialApp: 'Instagram', url: 'https://www.instagram.com/g'),
        ],
      );

      expect(requests.single.path, '/stylist/profile');
      expect(requests.single.queryParameters, {'_method': 'PATCH'});
      expect(
        fields['socials'],
        '[{"social_app":"Instagram","url":"https://www.instagram.com/g"}]',
      );
      expect(fields.keys.where((k) => k.startsWith('media')), isEmpty);
    });

    test('an empty socials list is sent as [] (removes all links)', () async {
      final fields = await send(socials: const []);
      expect(fields['socials'], '[]');
    });

    test('omitted socials and media keep both unchanged', () async {
      final fields = await send();
      expect(fields.containsKey('socials'), isFalse);
      expect(fields.keys.where((k) => k.startsWith('media')), isEmpty);
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
