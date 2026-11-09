import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax/iconsax.dart';
import 'package:snip_fair/core/domain/entities/withdrawal/withdrawal_submission.dart';
import 'package:snip_fair/core/presentation/widgets/dialogs.dart';
import 'package:snip_fair/core/utils/app_helper.dart';
import 'package:snip_fair/features/account/seller/earnings/views/seller_earning_screen.dart';

const _heading = 'Withdrawal Request Submitted';

/// Logical screen sizes: the design reference, then smaller phones.
const _screens = <String, Size>{
  'iPhone 14 (design size)': Size(390, 844),
  'iPhone SE 2nd/3rd gen': Size(375, 667),
  'iPhone SE 1st gen': Size(320, 568),
  'small Android': Size(360, 640),
};

void main() {
  /// Opens the withdrawal success dialog exactly as the earnings screen does
  /// (`AppHelper.showAppDialog` + `OnSuccessDialogContent`). Overflow errors
  /// are NOT suppressed here: any overflow fails the test.
  Future<List<BuildContext>> openDialog(
    WidgetTester tester, {
    required Size screen,
    double textScale = 1,
    bool compactIcon = true,
  }) async {
    tester.view
      ..physicalSize = screen * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final continued = <BuildContext>[];

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => AppHelper.showAppDialog<void>(
                    context,
                    OnSuccessDialogContent(
                      compactIcon: compactIcon,
                      mainText: _heading,
                      subtext: SellerEarningScreen.withdrawalSubmittedMessage(
                        const WithdrawalSubmission(amount: 1250.5),
                      ),
                      onDoneCallback: continued.add,
                    ),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return continued;
  }

  final icon = find.byKey(const Key('success_dialog_icon'));
  final check = find.byIcon(Icons.check_rounded);
  final heading = find.text(_heading);

  _screens.forEach((name, size) {
    for (final textScale in [1.0, 1.3]) {
      testWidgets('$name, text ×$textScale: layout', (tester) async {
        await openDialog(tester, screen: size, textScale: textScale);

        expect(tester.takeException(), isNull, reason: 'no overflow');

        // A small check in a circle; the old square glyph is gone.
        expect(icon, findsOneWidget);
        expect(check, findsOneWidget);
        expect(find.byIcon(Iconsax.tick_square), findsNothing);
        expect(tester.getSize(icon), const Size(56, 56));
        expect(tester.widget<Icon>(check).size, 32);
        final decoration = tester
            .widget<Container>(
              find.descendant(of: icon, matching: find.byType(Container)),
            )
            .decoration! as BoxDecoration;
        expect(decoration.shape, BoxShape.circle);

        // The check stays inside its circle, which sits above the heading.
        final iconRect = tester.getRect(icon);
        final checkRect = tester.getRect(check);
        final headingRect = tester.getRect(heading);
        expect(iconRect.contains(checkRect.topLeft), isTrue);
        expect(iconRect.contains(checkRect.bottomRight - const Offset(1, 1)),
            isTrue);
        expect(iconRect.bottom, lessThanOrEqualTo(headingRect.top));
        expect(headingRect.top - iconRect.bottom, greaterThanOrEqualTo(8));

        // Centred horizontally in the dialog.
        final dialogRect = tester.getRect(find.byType(Dialog));
        expect(
          (iconRect.center.dx - dialogRect.center.dx).abs(),
          lessThan(1),
        );
        expect(dialogRect.contains(iconRect.topLeft), isTrue);

        // Heading, message and button are all there.
        expect(heading, findsOneWidget);
        expect(find.textContaining('R1,250.50'), findsOneWidget);
        expect(find.textContaining('has not completed yet'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      });
    }

    testWidgets('$name: Continue closes the dialog and runs its callback',
        (tester) async {
      final continued = await openDialog(tester, screen: size, textScale: 1.3);

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(continued, hasLength(1));
      expect(find.byType(Dialog), findsNothing);
    });
  });

  testWidgets('other success dialogs keep their existing icon', (tester) async {
    // The legacy layout is unchanged (and may overflow under the test font).
    final original = FlutterError.onError;
    FlutterError.onError = (details) {
      if (!details.exceptionAsString().contains('overflowed')) {
        original?.call(details);
      }
    };
    addTearDown(() => FlutterError.onError = original);

    await openDialog(tester, screen: const Size(390, 844), compactIcon: false);

    expect(find.byIcon(Iconsax.tick_square), findsOneWidget);
    expect(icon, findsNothing);
  });
}
