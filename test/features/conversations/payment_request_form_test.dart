import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mocktail/mocktail.dart';
import 'package:snip_fair/core/di/injector.dart';
import 'package:snip_fair/core/network/api_result.dart';
import 'package:snip_fair/core/data/repositories/appointment_repository.dart';
import 'package:snip_fair/core/data/repositories/profile_repository.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment.dart';
import 'package:snip_fair/core/domain/entities/apointment/appointment_list.dart';
import 'package:snip_fair/core/domain/entities/payment_request/payment_request.dart';
import 'package:snip_fair/core/domain/entities/chat_message_list/chat_message_list.dart';
import 'package:snip_fair/features/conversations/cubit/conversations_cubit.dart';
import 'package:snip_fair/features/conversations/conversation/widgets/payment_request_form_bottom_sheet.dart';

class _MockAppointmentRepository extends Mock
    implements AppointmentRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

const _kRecipientId = 42;

void _stubAppointments(
  _MockAppointmentRepository repo,
  List<StylistAppointment> appointments,
) {
  when(
    () => repo.getStylistAppointments(
      query: any(named: 'query'),
      categoryId: any(named: 'categoryId'),
      page: any(named: 'page'),
      perPage: any(named: 'perPage'),
      customerId: any(named: 'customerId'),
      portfolioId: any(named: 'portfolioId'),
      status: any(named: 'status'),
      sort: any(named: 'sort'),
    ),
  ).thenAnswer(
    (_) async => ApiResult.success(
      data: StylistAppointmentList(data: appointments),
    ),
  );
}

/// Captures the arguments the cubit forwards to the repository so the test
/// can assert on `appointmentId` — the whole point of issue #3.
void _stubCreate(_MockProfileRepository repo) {
  when(
    () => repo.createPaymentRequest(
      recipientId: any(named: 'recipientId'),
      title: any(named: 'title'),
      items: any(named: 'items'),
      description: any(named: 'description'),
      appointmentId: any(named: 'appointmentId'),
      expiresInHours: any(named: 'expiresInHours'),
    ),
  ).thenAnswer(
    (_) async => ApiResult.success(
      data: PaymentRequest(id: 1, conversationId: 7),
    ),
  );
  when(() => repo.getChatMessages(any())).thenAnswer(
    (_) async => ApiResult.success(data: ChatMessageList(data: const [])),
  );
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required ConversationsCubit cubit,
  int? appointmentId,
}) async {
  // Phone-sized surface: the sheet is laid out with ScreenUtil against a
  // 390pt design width, and the default 800x600 test window scales every
  // fixed dimension ~2x, which overflows unrelated rows.
  tester.view
    ..physicalSize = const Size(390 * 3, 844 * 3)
    ..devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showPaymentRequestForm(
                    context,
                    recipientId: _kRecipientId,
                    conversationId: '7',
                    appointmentId: appointmentId,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

Future<void> _fillRequiredFields(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('payment_request_title')),
    'Extra products',
  );
  await tester.enterText(
    find.byKey(const Key('payment_request_item_name_0')),
    'Hair serum',
  );
  await tester.enterText(
    find.byKey(const Key('payment_request_item_price_0')),
    '120.50',
  );
  await tester.pump();
}

Future<void> _submit(WidgetTester tester) async {
  final button = find.byKey(const Key('payment_request_submit_button'));
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  late _MockAppointmentRepository appointmentRepo;
  late _MockProfileRepository profileRepo;
  late ConversationsCubit cubit;

  setUpAll(() {
    registerFallbackValue(<Map<String, dynamic>>[]);
  });

  setUp(() {
    appointmentRepo = _MockAppointmentRepository();
    profileRepo = _MockProfileRepository();
    cubit = ConversationsCubit(profileRepo);
    _stubCreate(profileRepo);

    if (getIt.isRegistered<AppointmentRepository>()) {
      getIt.unregister<AppointmentRepository>();
    }
    getIt.registerSingleton<AppointmentRepository>(appointmentRepo);
  });

  tearDown(() async {
    await cubit.close();
    if (getIt.isRegistered<AppointmentRepository>()) {
      getIt.unregister<AppointmentRepository>();
    }
  });

  testWidgets(
    'sends a payment request with no appointment when the customer has none',
    (tester) async {
      _stubAppointments(appointmentRepo, const []);

      await _pumpForm(tester, cubit: cubit);
      await _fillRequiredFields(tester);

      // Issue #3: Send must be enabled with zero appointments available.
      expect(
        find.byKey(const Key('payment_request_submit_button')),
        findsOneWidget,
      );
      await _submit(tester);

      final captured = verify(
        () => profileRepo.createPaymentRequest(
          recipientId: captureAny(named: 'recipientId'),
          title: any(named: 'title'),
          items: any(named: 'items'),
          description: any(named: 'description'),
          appointmentId: captureAny(named: 'appointmentId'),
          expiresInHours: any(named: 'expiresInHours'),
        ),
      ).captured;

      // recipient = the conversation's other participant; no appointment.
      expect(captured[0], _kRecipientId);
      expect(captured[1], isNull);
    },
  );

  testWidgets(
    'does not auto-link the only open appointment',
    (tester) async {
      _stubAppointments(appointmentRepo, [
        StylistAppointment(id: 900, status: 'approved', amount: 60),
      ]);

      await _pumpForm(tester, cubit: cubit);

      // The "No appointment" option must exist and be the default.
      expect(
        find.text('No appointment — additional service'),
        findsOneWidget,
      );

      await _fillRequiredFields(tester);
      await _submit(tester);

      final captured = verify(
        () => profileRepo.createPaymentRequest(
          recipientId: any(named: 'recipientId'),
          title: any(named: 'title'),
          items: any(named: 'items'),
          description: any(named: 'description'),
          appointmentId: captureAny(named: 'appointmentId'),
          expiresInHours: any(named: 'expiresInHours'),
        ),
      ).captured;

      expect(captured.single, isNull);
    },
  );

  testWidgets(
    'keeps linking to the appointment the stylist arrived from',
    (tester) async {
      _stubAppointments(appointmentRepo, [
        StylistAppointment(id: 900, status: 'approved', amount: 60),
      ]);

      await _pumpForm(tester, cubit: cubit, appointmentId: 900);
      await _fillRequiredFields(tester);

      await _submit(tester);

      final captured = verify(
        () => profileRepo.createPaymentRequest(
          recipientId: any(named: 'recipientId'),
          title: any(named: 'title'),
          items: any(named: 'items'),
          description: any(named: 'description'),
          appointmentId: captureAny(named: 'appointmentId'),
          expiresInHours: any(named: 'expiresInHours'),
        ),
      ).captured;

      expect(captured.single, 900);
    },
  );

  testWidgets(
    'an ineligible pre-selected appointment falls back to no appointment',
    (tester) async {
      // Passed-in id 900 is not in the eligible list — previously this was a
      // dead end that disabled Send entirely.
      _stubAppointments(appointmentRepo, [
        StylistAppointment(id: 111, status: 'approved', amount: 60),
      ]);

      await _pumpForm(tester, cubit: cubit, appointmentId: 900);
      await _fillRequiredFields(tester);

      await _submit(tester);

      final captured = verify(
        () => profileRepo.createPaymentRequest(
          recipientId: any(named: 'recipientId'),
          title: any(named: 'title'),
          items: any(named: 'items'),
          description: any(named: 'description'),
          appointmentId: captureAny(named: 'appointmentId'),
          expiresInHours: any(named: 'expiresInHours'),
        ),
      ).captured;

      expect(captured.single, isNull);
    },
  );

  testWidgets('sends the per-item quantity the stylist entered',
      (tester) async {
    _stubAppointments(appointmentRepo, const []);

    await _pumpForm(tester, cubit: cubit);
    await _fillRequiredFields(tester);
    await tester.enterText(
      find.byKey(const Key('payment_request_item_qty_0')),
      '3',
    );
    await tester.pump();

    await _submit(tester);

    final captured = verify(
      () => profileRepo.createPaymentRequest(
        recipientId: any(named: 'recipientId'),
        title: any(named: 'title'),
        items: captureAny(named: 'items'),
        description: any(named: 'description'),
        appointmentId: any(named: 'appointmentId'),
        expiresInHours: any(named: 'expiresInHours'),
      ),
    ).captured;

    final items = captured.single as List<Map<String, dynamic>>;
    expect(items.single['quantity'], 3);
    expect(items.single['unit_price'], 120.5);
    expect(items.single['name'], 'Hair serum');
  });
}
