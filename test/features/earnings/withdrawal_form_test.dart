import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snip_fair/core/data/models/server_error.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/customer_wallet_transaction_list.dart';
import 'package:snip_fair/core/domain/entities/customer_wallet_transaction_list/datum.dart';
import 'package:snip_fair/core/domain/entities/payment_method/payment_method.dart';
import 'package:snip_fair/core/domain/entities/stylist_earnings/stylist_earnings.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_attempt.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_lookup.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/errors/exception/remote_exception.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/presentation/widgets/app_text.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/preferences/withdrawal_attempt_store.dart';
import 'package:snip_fair/features/account/seller/earnings/cubit/earnings_cubit.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_earning_screen.dart';
import 'package:snip_fair/features/account/seller/profile_management/cubit/seller_profile_mgt_cubit.dart';

import 'earnings_fixtures.dart';
import 'withdrawal_test_support.dart';

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockSellerProfileMgtCubit extends MockCubit<SellerProfileMgtState>
    implements SellerProfileMgtCubit {}

/// The test font draws every glyph as a full em square, so fixed-height
/// dialogs and header rows overflow in tests only. Overflows are ignored;
/// every other error still fails the test.
void _ignoreTestFontOverflows() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('A RenderFlex overflowed')) {
      return;
    }
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ApiResult<WithdrawalSubmission> _accepted(double amount) =>
    ApiResult.success(data: WithdrawalSubmission(amount: amount));

ApiResult<WithdrawalSubmission> _failed(RemoteException error) =>
    ApiResult.failure(error: error);

RemoteException _server(int status, String message, {String? code}) =>
    RemoteException.serverError(
      status,
      ServerError(message: message),
      code: code,
    );

UserTransaction _row(
  int id,
  String type,
  String status,
  String reference, {
  double amount = 100,
}) =>
    UserTransaction.fromJson({
      'id': id,
      'type': type,
      'amount': amount,
      'description': type == 'refund'
          ? 'Refund of failed withdrawal #14'
          : 'Withdrawal request',
      'status': status,
      'reference': reference,
      'created_at': '2026-11-0${id % 9 + 1}T10:00:00.000000Z',
      'updated_at': '2026-11-0${id % 9 + 1}T10:00:00.000000Z',
    });

void main() {
  late _MockProfileRepository repo;
  late EarningsCubit cubit;
  late _MockSellerProfileMgtCubit profileCubit;
  late List<String> sentKeys;
  late List<FutureOr<ApiResult<WithdrawalSubmission>> Function()> answers;
  late List<UserTransaction> walletRows;

  late SharedPreferences prefs;
  late WithdrawalAttemptStore store;

  setUp(() async {
    prefs = await stylistPrefs();
    store = WithdrawalAttemptStore(prefs);
    repo = _MockProfileRepository();
    var n = 0;
    cubit = EarningsCubit(
      repo,
      store,
      newIdempotencyKey: () => 'key-${++n}-0000',
    );
    profileCubit = _MockSellerProfileMgtCubit();
    sentKeys = [];
    answers = [];
    walletRows = [];
    // Lookup unavailable by default: the pre-lookup behaviour.
    when(() => repo.lookupWithdrawal(any())).thenAnswer(
      (_) async =>
          const ApiResult.failure(error: RemoteException.timeoutError()),
    );
    when(() => profileCubit.getProfileDetails(any())).thenAnswer((_) async {});
    when(repo.getEarnings).thenAnswer(
      (_) async => ApiResult.success(
        data: StylistEarnings.fromJson(problematicEarningsResponse()),
      ),
    );
    when(repo.getPaymentMethods).thenAnswer(
      (_) async => ApiResult.success(
        data: [
          PaymentMethod.fromJson(
            problematicEarningsResponse()['payment_method']
                as Map<String, dynamic>,
          ),
        ],
      ),
    );
    when(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer(
      (_) async => ApiResult.success(
        data: CustomerWalletTransactionList(data: walletRows),
      ),
    );
    when(
      () => repo.requestPayout(
        any(),
        any(),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).thenAnswer((invocation) async {
      sentKeys.add(invocation.namedArguments[#idempotencyKey] as String);
      return answers.removeAt(0)();
    });
  });

  tearDown(() => cubit.close());

  Future<void> pumpScreen(WidgetTester tester, {double height = 844}) async {
    tester.view
      ..physicalSize = Size(390 * 3, height * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
    _ignoreTestFontOverflows();

    unawaited(cubit.getEarnings());
    unawaited(cubit.getPaymentMethods());
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: cubit),
            BlocProvider<SellerProfileMgtCubit>.value(value: profileCubit),
          ],
          child: const MaterialApp(home: SellerEarningScreen()),
        ),
      ),
    );
    // As in the app: the screen is mounted before the lookup answers.
    unawaited(cubit.restorePendingWithdrawal());
    await _settle(tester);
  }

  final form = find.byType(RequestPayoutFormWidget);
  final submit = find.byKey(const Key('request_payout_submit'));
  final amountField = find.descendant(
    of: form,
    matching: find.byType(TextField),
  );

  /// The sheet scrolls: notices can push the button below the fold.
  Future<void> tapSubmit(WidgetTester tester) async {
    await tester.ensureVisible(submit);
    await tester.tap(submit);
  }

  Future<void> openForm(WidgetTester tester) async {
    await tester.tap(find.text('Request Payout').first);
    await _settle(tester);
    expect(form, findsOneWidget);
  }

  String submitLabel(WidgetTester tester) => tester
      .widget<AppText>(
          find.descendant(of: submit, matching: find.byType(AppText)))
      .text;

  String failDialogText(WidgetTester tester) => tester
      .widget<OnFailDialogContent>(find.byType(OnFailDialogContent))
      .subtext;

  Future<void> dismissDialog(WidgetTester tester) async {
    await tester.tap(find.text('Try Again'));
    await _settle(tester);
  }

  testWidgets('10. rapid repeated taps send a single request', (tester) async {
    final gate = Completer<ApiResult<WithdrawalSubmission>>();
    answers.add(() => gate.future);
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');

    await tapSubmit(tester);
    await tester.tap(submit, warnIfMissed: false);
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();
    await tester.tap(submit, warnIfMissed: false);
    await tester.pump();

    expect(sentKeys, ['key-1-0000']);
    // While in flight the button is a disabled spinner.
    expect(find.descendant(of: submit, matching: find.byType(AppText)),
        findsNothing);

    gate.complete(_accepted(250.5));
    await _settle(tester);

    verify(
      () => repo.requestPayout(
        any(),
        any(),
        idempotencyKey: any(named: 'idempotencyKey'),
      ),
    ).called(1);
    expect(form, findsNothing);
  });

  testWidgets(
      '11. a timeout keeps the form and its details; Retry reuses the key',
      (tester) async {
    answers
      ..add(() => _failed(const RemoteException.timeoutError()))
      ..add(() => _accepted(250.5));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);

    expect(tester.takeException(), isNull);
    expect(
        failDialogText(tester), SellerEarningScreen.withdrawalUncertainMessage);
    await dismissDialog(tester);

    // Still open, same amount and method, now offered as a retry.
    expect(form, findsOneWidget);
    expect(find.descendant(of: form, matching: find.text('250.50')),
        findsOneWidget);
    expect(
      tester
          .widget<DropdownButtonFormField<PaymentMethod>>(
            find.byType(DropdownButtonFormField<PaymentMethod>),
          )
          .initialValue
          ?.id,
      7,
    );
    expect(submitLabel(tester), 'Retry Request');
    expect(find.byKey(const Key('pending_withdrawal_notice')), findsOneWidget);

    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    expect(form, findsNothing);
    expect(find.text('Withdrawal Request Submitted'), findsOneWidget);
  });

  testWidgets('reopening the form after a timeout offers the same request',
      (tester) async {
    answers
      ..add(() => _failed(RemoteException.httpError(502)))
      ..add(() => _accepted(250.5));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);
    await dismissDialog(tester);

    await tester.ensureVisible(find.text('Cancel'));
    await tester.tap(find.text('Cancel'));
    await _settle(tester);
    expect(form, findsNothing);

    await openForm(tester);
    expect(find.descendant(of: form, matching: find.text('250.50')),
        findsOneWidget);
    expect(submitLabel(tester), 'Retry Request');

    await tapSubmit(tester);
    await _settle(tester);
    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
  });

  testWidgets(
      'after a timeout the details are locked, the risk is explained, and '
      'there is no way to discard the request', (tester) async {
    answers.add(() => _failed(const RemoteException.timeoutError()));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);
    await dismissDialog(tester);

    // Locked: the amount and method cannot be edited.
    expect(tester.widget<TextField>(amountField).readOnly, isTrue);
    expect(
      tester
          .widget<DropdownButton<PaymentMethod>>(
            find.byType(DropdownButton<PaymentMethod>),
          )
          .onChanged,
      isNull,
    );
    // The risk is spelled out, including that history may not show it yet.
    expect(
      find.textContaining('It may already have been accepted'),
      findsOneWidget,
    );
    expect(
      find.textContaining("even if it doesn't appear in your transactions"),
      findsOneWidget,
    );
    // The only actions: retry the same request, or contact support.
    expect(submitLabel(tester), 'Retry Request');
    expect(
      find.byKey(const Key('withdrawal_contact_support')),
      findsOneWidget,
    );
    expect(find.textContaining('Discard'), findsNothing);
    expect(find.textContaining("I've Checked"), findsNothing);
    expect(sentKeys, ['key-1-0000']);
    expect(store.load(), isA<FoundWithdrawalAttempt>());
  });

  testWidgets(
      'an unresolved attempt is restored when the screen is recreated and '
      'retried with the exact key and payload', (tester) async {
    answers
      ..add(() => _failed(const RemoteException.timeoutError()))
      ..add(() => _accepted(250.5));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);
    await dismissDialog(tester);

    // Leave the screen: its cubit is closed.
    await tester.pumpWidget(const SizedBox());
    await cubit.close();
    expect(store.load(), isA<FoundWithdrawalAttempt>());

    // Reopen it with a brand-new cubit (and key generator).
    cubit = EarningsCubit(repo, store, newIdempotencyKey: () => 'fresh-key');
    await pumpScreen(tester);
    await openForm(tester);

    expect(
      find.descendant(of: form, matching: find.text('250.50')),
      findsOneWidget,
    );
    expect(submitLabel(tester), 'Retry Request');
    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    verify(
      () => repo.requestPayout('7', 250.5, idempotencyKey: 'key-1-0000'),
    ).called(2);
    expect(find.text('Withdrawal Request Submitted'), findsOneWidget);
    expect(store.load(), isA<NoStoredWithdrawalAttempt>());
  });

  testWidgets(
      'an unreadable saved attempt keeps withdrawals blocked and is never '
      'cleared from the form', (tester) async {
    await prefs.setString(attemptStorageKey(), '{not json');
    await pumpScreen(tester);
    await openForm(tester);

    expect(
      find.byKey(const Key('unreadable_withdrawal_notice')),
      findsOneWidget,
    );
    expect(find.textContaining('new withdrawals are blocked'), findsOneWidget);
    expect(submitLabel(tester), 'Contact Support');
    expect(tester.widget<TextField>(amountField).readOnly, isTrue);
    expect(find.textContaining("I've Checked"), findsNothing);

    // The primary action opens support mail (unavailable in tests): it never
    // clears the record or sends anything.
    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, isEmpty);
    expect(prefs.getString(attemptStorageKey()), '{not json');
    expect(cubit.state.pendingWithdrawalUnreadable, isTrue);
  });

  testWidgets('amounts with more than two decimals are not sent',
      (tester) async {
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '10.555');
    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, isEmpty);
    expect(
      find.text('Enter an amount in rands with at most two decimal places.'),
      findsOneWidget,
    );
  });

  group('minimum withdrawal R10.00', () {
    List<double> sentAmounts() => verify(
          () => repo.requestPayout(
            any(),
            captureAny(),
            idempotencyKey: any(named: 'idempotencyKey'),
          ),
        ).captured.cast<double>();

    for (final amount in ['9.99', '9', '0.01']) {
      testWidgets('R$amount is not sent', (tester) async {
        await pumpScreen(tester);
        await openForm(tester);
        await tester.enterText(amountField, amount);
        await tapSubmit(tester);
        await _settle(tester);

        expect(sentKeys, isEmpty);
        expect(
          find.text('Minimum withdrawal amount is R10.00.'),
          findsOneWidget,
        );
        expect(form, findsOneWidget);
      });
    }

    for (final (typed, sent) in [
      ('10.00', 10.0),
      ('10', 10.0),
      ('10.01', 10.01),
      ('500', 500.0),
      ('500.00', 500.0),
    ]) {
      testWidgets('R$typed is sent', (tester) async {
        answers.add(() async => _accepted(sent));
        await pumpScreen(tester);
        await openForm(tester);
        await tester.enterText(amountField, typed);
        await tapSubmit(tester);
        await _settle(tester);

        expect(sentKeys, hasLength(1));
        expect(sentAmounts(), [sent]);
        expect(find.text('Minimum withdrawal amount is R10.00.'), findsNothing);
      });
    }

    testWidgets('non-numeric input is not sent', (tester) async {
      await pumpScreen(tester);
      await openForm(tester);
      for (final amount in ['abc', 'R10', '10,00', '1e3']) {
        await tester.enterText(amountField, amount);
        await tapSubmit(tester);
        await _settle(tester);
      }

      expect(sentKeys, isEmpty);
      expect(find.text('Minimum withdrawal amount is R10.00.'), findsNothing);
    });
  });

  testWidgets(
      '9. 204: says the request was submitted, not that the money arrived',
      (tester) async {
    answers.add(() => _accepted(250.5));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);

    expect(form, findsNothing);
    final dialog = tester
        .widget<OnSuccessDialogContent>(find.byType(OnSuccessDialogContent));
    expect(dialog.mainText, 'Withdrawal Request Submitted');
    expect(dialog.subtext, contains('has been submitted'));
    expect(dialog.subtext, contains('has not completed yet'));
  });

  final failures = <String, (RemoteException, String)>{
    '6. 503 withdrawals disabled': (
      _server(
        503,
        'Withdrawals are temporarily unavailable. Your balance is safe; '
        'please try again later.',
        code: 'PAYOUT_REQUESTS_DISABLED',
      ),
      SellerEarningScreen.withdrawalsUnavailableMessage,
    ),
    '7. 409 idempotency conflict': (
      _server(
        409,
        'Ooops.. This idempotency key was already used for a different '
        'withdrawal.',
        code: 'IDEMPOTENCY_KEY_REUSED',
      ),
      SellerEarningScreen.withdrawalConflictMessage,
    ),
    '8. 400 missing idempotency key': (
      _server(
        400,
        "Ooops.. This version of the app can't request withdrawals. "
        'Please update it and try again.',
        code: 'IDEMPOTENCY_KEY_REQUIRED',
      ),
      SellerEarningScreen.withdrawalKeyRejectedMessage,
    ),
    '8. 400 business refusal': (
      _server(400, 'Ooops.. Insufficient balance.'),
      'Insufficient balance.',
    ),
    '10. 422 validation error': (
      RemoteException.serverError(
        422,
        const ServerError(
          message: 'The amount field must be greater than 10. '
              '(and 1 more error)',
          errors: {
            'amount': ['The amount field must be greater than 10.'],
            'method': ['The method field must be an integer.'],
          },
        ),
      ),
      'The amount field must be greater than 10.\n'
          'The method field must be an integer.',
    ),
    '403 email not verified': (
      _server(
        403,
        'Please verify your email address to continue',
        code: 'VERIFY_EMAIL',
      ),
      'Please verify your email address to continue',
    ),
    '429 throttled': (
      RemoteException.httpError(429),
      SellerEarningScreen.withdrawalRateLimitedMessage,
    ),
  };

  failures.forEach((name, failure) {
    testWidgets('$name: clear message, one request, form kept', (tester) async {
      answers.add(() => _failed(failure.$1));
      await pumpScreen(tester);
      await openForm(tester);
      await tester.enterText(amountField, '250.50');
      await tapSubmit(tester);
      await _settle(tester);

      expect(tester.takeException(), isNull);
      expect(failDialogText(tester), failure.$2);
      expect(sentKeys, hasLength(1), reason: 'no automatic retry');
      await dismissDialog(tester);
      // 13. The form stays open with its values…
      expect(form, findsOneWidget);
      expect(
        find.descendant(of: form, matching: find.text('250.50')),
        findsOneWidget,
      );
      // …and a definite refusal is not presented as an unknown outcome.
      expect(submitLabel(tester), 'Request Payout');
      expect(
        find.byKey(const Key('pending_withdrawal_notice')),
        findsNothing,
      );
      expect(cubit.state.pendingWithdrawal?.outcomeUnknown ?? false, isFalse);
    });
  });

  testWidgets('9. a 409 refreshes the history and is not resent',
      (tester) async {
    answers.add(
      () => _failed(
        _server(
          409,
          'Ooops.. This idempotency key was already used for a different '
          'withdrawal.',
          code: 'IDEMPOTENCY_KEY_REUSED',
        ),
      ),
    );
    await pumpScreen(tester);
    clearInteractions(repo);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, hasLength(1));
    verify(
      () => repo.getWalletTransactions(
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).called(1);
    expect(find.textContaining('conflicts with a previous request'),
        findsOneWidget);
  });

  testWidgets('a 503 then an identical resubmission reuses the key',
      (tester) async {
    answers
      ..add(
        () => _failed(
          _server(
            503,
            'Withdrawals are temporarily unavailable.',
            code: 'PAYOUT_REQUESTS_DISABLED',
          ),
        ),
      )
      ..add(() => _accepted(250.5));
    await pumpScreen(tester);
    await openForm(tester);
    await tester.enterText(amountField, '250.50');
    await tapSubmit(tester);
    await _settle(tester);
    await dismissDialog(tester);

    await tapSubmit(tester);
    await _settle(tester);

    expect(sentKeys, ['key-1-0000', 'key-1-0000']);
    expect(form, findsNothing);
  });

  group('recovery after a restart', () {
    const key = '3b241101-e2bb-4255-8caf-4136c566a962';
    const saved = WithdrawalAttempt(
      idempotencyKey: key,
      paymentMethodId: '7',
      amount: 150,
      status: WithdrawalAttemptStatus.unknown,
    );

    WithdrawalRecord record(String status, {bool refunded = false}) =>
        WithdrawalRecord(
          id: 42,
          amountMinor: 15000,
          rawStatus: status,
          refunded: refunded,
          refund: refunded
              ? const WithdrawalRefund(
                  transactionId: 990,
                  reference: 'WDR-42-REFUND',
                  amount: 150,
                )
              : null,
        );

    void lookupAnswers(List<ApiResult<WithdrawalLookup>> results) {
      when(() => repo.lookupWithdrawal(any()))
          .thenAnswer((_) async => results.removeAt(0));
    }

    test('only `paid` is described as sent to the bank, never as received',
        () {
      for (final status in WithdrawalRecordStatus.values) {
        final raw = switch (status) {
          WithdrawalRecordStatus.underReview => 'under_review',
          _ => status.name,
        };
        final text =
            SellerEarningScreen.recoveredWithdrawalMessage(record(raw));
        expect(
          text.contains('has been sent to your bank account'),
          status == WithdrawalRecordStatus.paid,
          reason: raw,
        );
        // No status claims the bank has credited the money.
        for (final claim in [
          'has been paid',
          'received in your',
          'arrived',
          'credited',
        ]) {
          expect(text, isNot(contains(claim)), reason: '$raw: $claim');
        }
        expect(text, contains('R150.00'));
      }
      expect(
        SellerEarningScreen.recoveredWithdrawalMessage(record('paid')),
        'Your withdrawal of R150.00 has been sent to your bank account. '
        'Depending on your bank, it may take some time to reflect in your '
        'account. It will not be submitted again.',
      );
      expect(
        SellerEarningScreen.recoveredWithdrawalMessage(record('new_state')),
        isNot(contains('has been sent to your bank account')),
      );
    });

    test('pending, processing, under review, failed and reversed stay distinct',
        () {
      final texts = {
        for (final raw in [
          'pending',
          'processing',
          'under_review',
          'failed',
          'reversed',
          'paid',
        ])
          raw: SellerEarningScreen.recoveredWithdrawalMessage(record(raw)),
      };
      expect(texts.values.toSet(), hasLength(texts.length));
      expect(texts['pending'], contains('waiting to be sent to your bank'));
      expect(texts['processing'], contains('is being processed'));
      expect(texts['under_review'], contains('reviewed by our team'));
      expect(texts['failed'], contains('failed and was not paid'));
      expect(texts['reversed'], contains('reversed by the bank'));
      for (final raw in ['pending', 'processing', 'under_review']) {
        expect(texts[raw], contains('It has not been paid yet.'), reason: raw);
      }
    });

    test('refund information comes from `refunded` and `refund`', () {
      expect(
        SellerEarningScreen.recoveredWithdrawalMessage(
          record('failed', refunded: true),
        ),
        contains('R150.00 has been refunded to your Snipfair balance'),
      );
      expect(
        SellerEarningScreen.recoveredWithdrawalMessage(record('failed')),
        contains('No refund has been recorded yet'),
      );
    });

    testWidgets('found: the status is shown and the form unlocks',
        (tester) async {
      await store.save(saved);
      lookupAnswers([
        const ApiResult.success(
            data: WithdrawalLookupFound(
          WithdrawalRecord(
            id: 42,
            amountMinor: 15000,
            rawStatus: 'processing',
            refunded: false,
          ),
        )),
      ]);
      await pumpScreen(tester);

      expect(
          find.byKey(const Key('recovered_withdrawal_dialog')), findsOneWidget);
      expect(find.text('Earlier Withdrawal Found'), findsOneWidget);
      expect(
        find.textContaining('is being processed. It has not been paid yet'),
        findsOneWidget,
      );
      expect(sentKeys, isEmpty);
      expect(store.load(), isA<NoStoredWithdrawalAttempt>());
    });

    testWidgets('404: Retry Request resends the original key and payload',
        (tester) async {
      await store.save(saved);
      lookupAnswers(
          [const ApiResult.success(data: WithdrawalLookupNotFound())]);
      answers.add(() => _accepted(150));
      await pumpScreen(tester);
      await openForm(tester);

      expect(find.textContaining('has not been recorded'), findsOneWidget);
      expect(submitLabel(tester), 'Retry Request');
      expect(tester.widget<TextField>(amountField).readOnly, isTrue);
      expect(sentKeys, isEmpty, reason: 'nothing sent before the tap');

      await tapSubmit(tester);
      await _settle(tester);

      expect(sentKeys, [key]);
      verify(() => repo.requestPayout('7', 150, idempotencyKey: key)).called(1);
      expect(find.text('Withdrawal Request Submitted'), findsOneWidget);
    });

    testWidgets('busy: blocked, with Check Again', (tester) async {
      await store.save(saved);
      lookupAnswers([
        ApiResult.failure(
          error: _server(
            503,
            'Ooops.. Your withdrawal is still being processed.',
            code: 'WITHDRAWAL_LOOKUP_BUSY',
          ),
        ),
        const ApiResult.success(
            data: WithdrawalLookupFound(
          WithdrawalRecord(
            id: 42,
            amountMinor: 15000,
            rawStatus: 'pending',
            refunded: false,
          ),
        )),
      ]);
      await pumpScreen(tester);
      await openForm(tester);

      expect(find.textContaining('is still being processed'), findsOneWidget);
      expect(submitLabel(tester), 'Check Again');

      await tapSubmit(tester);
      await _settle(tester);

      expect(sentKeys, isEmpty);
      expect(find.text('Earlier Withdrawal Found'), findsOneWidget);
      expect(store.load(), isA<NoStoredWithdrawalAttempt>());
    });

    testWidgets('lookup unavailable: still blocked, retry stays safe',
        (tester) async {
      await store.save(saved);
      await pumpScreen(tester);
      await openForm(tester);

      expect(
        find.textContaining('It may already have been accepted'),
        findsOneWidget,
      );
      expect(submitLabel(tester), 'Retry Request');
      expect(find.byKey(const Key('withdrawal_check_status')), findsOneWidget);
      expect(store.load(), isA<FoundWithdrawalAttempt>());
    });
  });

  testWidgets('withdrawal statuses show what the API reports', (tester) async {
    walletRows.addAll([
      _row(1, 'withdraw', 'pending', 'WDR-11'),
      _row(2, 'withdraw', 'processing', 'WDR-12-PEACHPAYOUTID-a1'),
      _row(3, 'withdraw', 'completed', 'WDR-13-PEACHPAYOUTID-b2'),
      _row(4, 'withdraw', 'failed', 'WDR-14-PEACHPAYOUTID-c3'),
      _row(5, 'refund', 'completed', 'WDR-14-REFUND', amount: 75),
      _row(6, 'withdraw', 'failed', 'WDR-15'),
      _row(7, 'withdraw', 'reversed', 'WDR-16-PEACHPAYOUTID-d4'),
      // A refund whose reference does not follow the WDR pattern is still
      // money back to the stylist.
      _row(8, 'refund', 'completed', 'RF-UNPAIRED', amount: 30),
    ]);
    await pumpScreen(tester, height: 1800);
    await tester.tap(find.text('Transactions'));
    await _settle(tester);

    String status(int id) =>
        tester.widget<AppText>(find.byKey(Key('transaction_status_$id'))).text;

    expect(tester.takeException(), isNull);
    expect(status(1), 'Submitted');
    expect(status(2), 'Processing');
    expect(status(3), 'Sent to bank');
    expect(status(4), 'Failed · Refunded');
    expect(status(5), 'Refunded');
    // No refund row loaded for this one: not claimed as refunded.
    expect(status(6), 'Failed');
    expect(status(7), 'Reversed');
    // The refund is money back to the stylist.
    expect(find.text('+R75.00'), findsOneWidget);
    expect(status(8), 'Refunded');
    expect(find.text('+R30.00'), findsOneWidget);
    expect(find.text('-R100.00'), findsNWidgets(6));
  });
}
