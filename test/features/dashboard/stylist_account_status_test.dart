import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/data/models/remote/login_response.dart';
import 'package:snip_fair/core/data/models/remote/simple_response.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/stylist_account/stylist_account_status.dart';
import 'package:snip_fair/core/domain/entities/stylist_profile_details/stylist_profile_details.dart';
import 'package:snip_fair/core/domain/entities/user/user.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/presentation/cubit/app_cubit.dart';
import 'package:snip_fair/core/routing/routes.gr.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';
import 'package:snip_fair/features/dashboard/widgets/stylist_account_status_banner.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAppCubit extends MockCubit<AppState> implements AppCubit {}

/// Shaped like `StylistActivation::status()`.
Map<String, dynamic> _account(
  String state, {
  bool isActive = false,
  List<(String, String, bool)>? requirements,
  String? message,
}) {
  final reqs = requirements ??
      const [
        ('email_verified', 'Verify your email address', true),
        ('basic_details', 'Add your country and years of experience', true),
        ('identity_document', 'Upload your identification document', false),
        ('user_bio', 'Update your biography', false),
        ('payment_method', 'Add an active payout method', true),
      ];
  return {
    'is_active': isActive,
    'state': state,
    'verification_complete': reqs.every((r) => r.$3),
    'approval_status': 'unverified',
    'is_available': false,
    'requirements': [
      for (final r in reqs) {'key': r.$1, 'label': r.$2, 'completed': r.$3},
    ],
    'missing_requirements': [
      for (final r in reqs)
        if (!r.$3) r.$1,
    ],
    'message': message ?? 'Backend message for $state.',
  };
}

StylistAccountStatus _status(String state, {bool isActive = false}) =>
    StylistAccountStatus.tryParse(_account(state, isActive: isActive))!;

void main() {
  group('StylistAccountStatus.tryParse', () {
    test('parses the backend block', () {
      final status = _status('incomplete');

      expect(status.isActive, isFalse);
      expect(status.state, StylistAccountState.incomplete);
      expect(status.requirements, hasLength(5));
      expect(status.missingRequirements, ['identity_document', 'user_bio']);
      expect(status.outstandingRequirements.map((r) => r.label), [
        'Upload your identification document',
        'Update your biography',
      ]);
      expect(status.message, 'Backend message for incomplete.');
    });

    test('every backend state maps; unknown states are kept as unknown', () {
      const states = {
        'active': StylistAccountState.active,
        'incomplete': StylistAccountState.incomplete,
        'not_submitted': StylistAccountState.notSubmitted,
        'pending_approval': StylistAccountState.pendingApproval,
        'rejected': StylistAccountState.rejected,
        'unavailable': StylistAccountState.unavailable,
        'flagged': StylistAccountState.flagged,
        'banned': StylistAccountState.banned,
        'something_new': StylistAccountState.unknown,
      };
      states.forEach((raw, expected) {
        expect(_status(raw).state, expected, reason: raw);
      });
    });

    test('is_active alone decides activation', () {
      // verification complete but awaiting approval: still inactive.
      final pending = StylistAccountStatus.tryParse({
        ..._account('pending_approval', requirements: const []),
        'verification_complete': true,
      })!;
      expect(pending.isActive, isFalse);
      expect(_status('active', isActive: true).isActive, isTrue);
    });

    test('missing or non-boolean is_active is not trusted', () {
      expect(StylistAccountStatus.tryParse(null), isNull);
      expect(StylistAccountStatus.tryParse('active'), isNull);
      expect(StylistAccountStatus.tryParse({'state': 'active'}), isNull);
      expect(
        StylistAccountStatus.tryParse({'is_active': 'false', 'state': 'x'}),
        isNull,
      );
    });

    test('malformed requirement entries are skipped safely', () {
      final status = StylistAccountStatus.tryParse({
        'is_active': false,
        'state': 'incomplete',
        'requirements': [
          'nonsense',
          {'label': 'no key'},
          {'key': 'works', 'completed': false},
        ],
      })!;
      expect(status.requirements.single.key, 'works');
      expect(status.requirements.single.label, 'works');
      expect(status.outstandingRequirements.single.key, 'works');
    });

    test('login and profile responses carry it; GET /user does not', () {
      final login = LoginResponse.fromJson({
        'token': 't',
        'role': 'stylist',
        'user': {'id': 1, 'role': 'stylist'},
        'stylist_account': _account('incomplete'),
      });
      expect(login.stylistAccount?.state, StylistAccountState.incomplete);

      final customer = LoginResponse.fromJson({
        'token': 't',
        'role': 'customer',
        'user': {'id': 2, 'role': 'customer'},
      });
      expect(customer.stylistAccount, isNull);

      final profile = StylistProfileDetails.fromJson({
        'user': null,
        'stylist_account': _account('rejected'),
      });
      expect(profile.stylistAccount?.state, StylistAccountState.rejected);
    });
  });

  group('requirement routes', () {
    test('each backend requirement opens its own screen', () {
      String? name(String key) =>
          stylistRequirementRoute(key, email: 'a@b.co')?.routeName;
      expect(name('email_verified'), VerifyEmailRoute.name);
      expect(name('basic_details'), SellerBusinessCreateRoute.name);
      expect(name('identity_document'), StylistBusinessIdVerifyRoute.name);
      expect(name('user_bio'), SellerPersonalDetailsRoute.name);
      expect(name('address'), SellerPersonalDetailsRoute.name);
      expect(name('location_service'), SellerAvailabilityScheduleRoute.name);
      expect(name('user_avatar'), SellerProfileManagementRoute.name);
      expect(name('user_banner'), SellerProfileManagementRoute.name);
      expect(name('portfolio'), SellerPortfolioRoute.name);
      expect(name('social_links'), SellerProfileVerificationRoute.name);
      expect(name('works'), SellerProfileVerificationRoute.name);
      expect(name('payment_method'), SellerPaymentMethodsRoute.name);
      expect(name('unknown_future_step'), isNull);
      expect(stylistRequirementRoute('email_verified'), isNull);
    });
  });

  group('SellerProfileMgtCubit account status', () {
    late _MockProfileRepository repo;
    late SellerProfileMgtCubit cubit;

    setUp(() {
      repo = _MockProfileRepository();
      cubit = SellerProfileMgtCubit(repo);
    });
    tearDown(() => cubit.close());

    test('seeded from sign-in, then replaced by the profile', () async {
      cubit.seedStylistAccount(_status('incomplete'));
      expect(cubit.state.stylistAccount?.state, StylistAccountState.incomplete);

      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'stylist_account': _account('active', isActive: true),
          }),
        ),
      );
      await cubit.getProfileDetails();

      expect(cubit.state.stylistAccount?.isActive, isTrue);
    });

    test('403 VERIFY_EMAIL keeps the sign-in status and is not an error',
        () async {
      cubit.seedStylistAccount(_status('incomplete'));
      when(repo.getStylistProfile).thenAnswer(
        (_) async => const ApiResult.failure(
          error: RemoteException.serverError(
            403,
            ServerError(message: 'Please verify your email address to continue'),
            code: 'VERIFY_EMAIL',
          ),
        ),
      );

      await cubit.getProfileDetails();

      expect(cubit.state.stylistAccount?.state, StylistAccountState.incomplete);
      expect(cubit.state.profileDetails.hasError, isFalse);
      expect(cubit.state.profileDetails.isLoading, isFalse);
    });

    test('a network failure never changes the status', () async {
      cubit.seedStylistAccount(_status('pending_approval'));
      when(repo.getStylistProfile).thenAnswer(
        (_) async =>
            const ApiResult.failure(error: RemoteException.timeoutError()),
      );

      await cubit.getProfileDetails(true);

      expect(
        cubit.state.stylistAccount?.state,
        StylistAccountState.pendingApproval,
      );
    });

    test('a profile without the block keeps the last known status', () async {
      cubit.seedStylistAccount(_status('rejected'));
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(data: StylistProfileDetails()),
      );

      await cubit.getProfileDetails();

      expect(cubit.state.stylistAccount?.state, StylistAccountState.rejected);
    });

    test('logout clears it', () {
      cubit
        ..seedStylistAccount(_status('incomplete'))
        ..onLogout();
      expect(cubit.state.stylistAccount, isNull);
    });
  });

  group('submit for approval', () {
    late _MockProfileRepository repo;
    late SellerProfileMgtCubit cubit;

    void stubUpdate(ApiResult<SimpleResponse> result) {
      when(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: any(named: 'medias'),
        ),
      ).thenAnswer((_) async => result);
    }

    void stubProfile(String state) {
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'user': {
              'stylist_profile': {'business_name': 'Glow Studio'},
            },
            'stylist_account': _account(state, requirements: const []),
          }),
        ),
      );
    }

    setUp(() async {
      repo = _MockProfileRepository();
      cubit = SellerProfileMgtCubit(repo);
      stubProfile('not_submitted');
      await cubit.getProfileDetails();
    });
    tearDown(() => cubit.close());

    test('sends a profile update that changes nothing, then reads pending',
        () async {
      stubUpdate(ApiResult.success(data: SimpleResponse.fromJson({})));
      stubProfile('pending_approval');

      await cubit.submitForApproval();

      final captured = verify(
        () => repo.updateStylistProfile(
          businessName: captureAny(named: 'businessName'),
          socials: captureAny(named: 'socials'),
          medias: captureAny(named: 'medias'),
        ),
      ).captured;
      // The stored name (never blanked), no socials, no media.
      expect(captured, ['Glow Studio', null, null]);
      expect(
        cubit.state.stylistAccount?.state,
        StylistAccountState.pendingApproval,
      );
      expect(cubit.state.submitForApprovalState.data, isTrue);
    });

    test('reports when the backend did not move it to pending', () async {
      stubUpdate(ApiResult.success(data: SimpleResponse.fromJson({})));
      stubProfile('not_submitted');

      await cubit.submitForApproval();

      expect(cubit.state.submitForApprovalState.hasSuccess, isTrue);
      expect(cubit.state.submitForApprovalState.data, isFalse);
    });

    test('a failed submission leaves the status unchanged', () async {
      stubUpdate(
        const ApiResult.failure(error: RemoteException.timeoutError()),
      );

      await cubit.submitForApproval();

      expect(cubit.state.submitForApprovalState.hasError, isTrue);
      expect(
        cubit.state.stylistAccount?.state,
        StylistAccountState.notSubmitted,
      );
    });
  });

  group('StylistAccountStatusBanner', () {
    late _MockProfileRepository repo;
    late SellerProfileMgtCubit profileCubit;
    late _MockAppCubit appCubit;

    setUp(() {
      repo = _MockProfileRepository();
      profileCubit = SellerProfileMgtCubit(repo);
      appCubit = _MockAppCubit();
      when(() => appCubit.state).thenReturn(
        const AppState.authenticated(
          user: User(role: 'stylist', email: 'stylist@example.com'),
        ),
      );
    });
    tearDown(() => profileCubit.close());

    Future<void> pumpBanner(WidgetTester tester) async {
      tester.view
        ..physicalSize = const Size(390 * 3, 844 * 3)
        ..devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider<AppCubit>.value(value: appCubit),
              BlocProvider.value(value: profileCubit),
            ],
            child: const MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: StylistAccountStatusBanner(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    String text(WidgetTester tester, String key) =>
        tester.widget<Text>(find.byKey(Key(key))).data!;

    for (final (state, title, action) in [
      ('incomplete', 'Your account is inactive', 'Continue'),
      ('not_submitted', 'Submit your profile for approval',
          'Submit for approval'),
      ('pending_approval', 'Awaiting approval', null),
      ('rejected', 'Verification not approved', 'Update your details'),
      ('unavailable', 'You are currently unavailable', 'Turn on availability'),
      ('flagged', 'Account restricted', 'Contact support'),
      ('banned', 'Account suspended', 'Contact support'),
    ]) {
      testWidgets('$state shows its own title, message and action',
          (tester) async {
        profileCubit.seedStylistAccount(_status(state));
        await pumpBanner(tester);

        expect(find.byKey(const Key('stylist_account_banner')), findsOneWidget);
        expect(text(tester, 'stylist_account_banner_title'), title);
        expect(
          text(tester, 'stylist_account_banner_message'),
          'Backend message for $state.',
        );
        if (action == null) {
          expect(
            find.byKey(const Key('stylist_account_banner_action')),
            findsNothing,
          );
        } else {
          expect(find.text(action), findsOneWidget);
        }
      });
    }

    testWidgets('incomplete lists only the outstanding backend requirements',
        (tester) async {
      profileCubit.seedStylistAccount(_status('incomplete'));
      await pumpBanner(tester);

      expect(find.text('2 steps left to complete:'), findsOneWidget);
      // The action goes to the first outstanding step, in backend order.
      expect(
        find.text('Next step: Upload your identification document'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('stylist_requirement_identity_document')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('stylist_requirement_user_bio')),
          findsOneWidget);
      expect(
        find.byKey(const Key('stylist_requirement_payment_method')),
        findsNothing,
      );
    });

    testWidgets('active stylists see no banner', (tester) async {
      profileCubit.seedStylistAccount(_status('active', isActive: true));
      await pumpBanner(tester);

      expect(find.byKey(const Key('stylist_account_banner')), findsNothing);
    });

    testWidgets('customers never see it', (tester) async {
      when(() => appCubit.state).thenReturn(
        const AppState.authenticated(user: User(role: 'customer')),
      );
      profileCubit.seedStylistAccount(_status('incomplete'));
      await pumpBanner(tester);

      expect(find.byKey(const Key('stylist_account_banner')), findsNothing);
    });

    testWidgets('no status known yet: nothing is shown', (tester) async {
      await pumpBanner(tester);
      expect(find.byKey(const Key('stylist_account_banner')), findsNothing);
    });

    testWidgets('disappears once the backend confirms the account active',
        (tester) async {
      profileCubit.seedStylistAccount(_status('pending_approval'));
      await pumpBanner(tester);
      expect(find.byKey(const Key('stylist_account_banner')), findsOneWidget);

      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'stylist_account': _account('active', isActive: true),
          }),
        ),
      );
      await profileCubit.getProfileDetails(true);
      await tester.pump();

      expect(find.byKey(const Key('stylist_account_banner')), findsNothing);
    });

    testWidgets('unavailable: the action turns availability on',
        (tester) async {
      when(() => repo.updateAvailability(isAvailable: any(named: 'isAvailable')))
          .thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'stylist_account': _account('active', isActive: true),
          }),
        ),
      );
      profileCubit.seedStylistAccount(_status('unavailable'));
      await pumpBanner(tester);

      await tester.tap(find.text('Turn on availability'));
      await tester.pump();
      await tester.pump();

      verify(() => repo.updateAvailability(isAvailable: true)).called(1);
      expect(find.byKey(const Key('stylist_account_banner')), findsNothing);
    });

    testWidgets('not_submitted: the button submits and shows the new state',
        (tester) async {
      when(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: any(named: 'medias'),
        ),
      ).thenAnswer(
        (_) async => ApiResult.success(data: SimpleResponse.fromJson({})),
      );
      when(repo.getStylistProfile).thenAnswer(
        (_) async => ApiResult.success(
          data: StylistProfileDetails.fromJson({
            'stylist_account':
                _account('pending_approval', requirements: const []),
          }),
        ),
      );
      profileCubit.seedStylistAccount(_status('not_submitted'));
      await pumpBanner(tester);

      await tester.tap(find.text('Submit for approval'));
      await tester.pump();
      await tester.pump();

      verify(
        () => repo.updateStylistProfile(
          businessName: any(named: 'businessName'),
          socials: any(named: 'socials'),
          medias: any(named: 'medias'),
        ),
      ).called(1);
      expect(text(tester, 'stylist_account_banner_title'), 'Awaiting approval');
    });
  });
}
