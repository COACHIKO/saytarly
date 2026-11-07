import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/widgets/currency_refresh_scope.dart';

void main() {
  tearDown(() {
    Money.setCustomSymbol('');
    Str.setLocale(const Locale('ar'));
  });

  test('currency tokens follow the configured symbol in Arabic', () {
    Str.setLocale(const Locale('ar'));
    Money.setCustomSymbol('ر.س');

    expect('{v1} ج'.tr({'v1': '10'}), '10 ر.س');
    expect('الإجمالي: {v1} ج'.tr({'v1': '10'}), 'الإجمالي: 10 ر.س');
    expect(
      '{v1} ج × {v2} = {v3} ج'.tr({'v1': '2', 'v2': '5', 'v3': '10'}),
      '2 ر.س × 5 = 10 ر.س',
    );
    // Words that merely contain «ج» must stay intact.
    expect('إجمالي'.tr(), 'إجمالي');
    // The default marker «ج.م» must stay intact too.
    expect('ج.م'.tr(), 'ج.م');
  });

  test('currency tokens follow the configured symbol in English', () {
    Str.setLocale(const Locale('en'));
    Money.setCustomSymbol('SAR');

    expect('{v1} ج'.tr({'v1': '10'}), '10 SAR');
    expect('الإجمالي: {v1} ج'.tr({'v1': '10'}), 'Total: 10 SAR');

    Money.setCustomSymbol('');
    expect('{v1} ج'.tr({'v1': '10'}), '10 EGP');
  });

  testWidgets('open screens rebuild when the currency changes', (tester) async {
    Str.setLocale(const Locale('ar'));
    Money.setCustomSymbol('');

    await tester.pumpWidget(
      const CurrencyRefreshScope(
        child: MaterialApp(home: Scaffold(body: _MoneyLabel())),
      ),
    );
    expect(find.text('10 ج.م'), findsOneWidget);

    Money.setCustomSymbol('ر.س');
    await tester.pump(); // post-frame callback marks the tree dirty
    await tester.pump(); // rebuild with the new symbol

    expect(find.text('10 ر.س'), findsOneWidget);
    expect(find.text('10 ج.م'), findsNothing);
  });

  testWidgets('pushed routes rebuild when the currency changes', (
    tester,
  ) async {
    Str.setLocale(const Locale('ar'));
    Money.setCustomSymbol('');

    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      CurrencyRefreshScope(
        child: MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('home')),
        ),
      ),
    );

    navKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: _MoneyLabel()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('10 ج.م'), findsOneWidget);

    Money.setCustomSymbol('ر.س');
    await tester.pump();
    await tester.pump();

    expect(find.text('10 ر.س'), findsOneWidget);
    expect(find.text('10 ج.م'), findsNothing);
  });
}

class _MoneyLabel extends StatelessWidget {
  const _MoneyLabel();

  @override
  Widget build(BuildContext context) {
    return Text('{v1} ج'.tr({'v1': '10'}));
  }
}
