import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saytarly/core/design/saytarly_theme.dart';
import 'package:saytarly/core/desktop/widgets/desktop_controls.dart';
import 'package:saytarly/core/desktop/widgets/hover_builder.dart';

// 🖱️ انحدار: ماوس واحد = هوفر واحد. لازم صف واحد بس يتظلل حتى لو حدث
// خروج الماوس من صف سابق اتفوّت (بيحصل على ويندوز عند فقدان الفوكس).
void main() {
  Widget hoverRow(String id) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: HoverBuilder(
      builder:
          (context, hovering) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {},
            child: AnimatedContainer(
              key: ValueKey(id),
              duration: const Duration(milliseconds: 150),
              height: 56,
              decoration: BoxDecoration(
                color:
                    hovering
                        ? const Color(0xFFEEF2F7)
                        : const Color(0x00EEF2F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(id),
            ),
          ),
    ),
  );

  Color colorOf(WidgetTester tester, String id) {
    final box = tester.widget<AnimatedContainer>(find.byKey(ValueKey(id)));
    return (box.decoration! as BoxDecoration).color!;
  }

  testWidgets('only one hover row tints at a time', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SaytarlyTheme.light(),
        home: Scaffold(
          body: Column(
            children: [
              hoverRow('menu'),
              const Divider(height: 1),
              hoverRow('cashier'),
            ],
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('menu'))));
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'menu').a, greaterThan(0));
    expect(colorOf(tester, 'cashier').a, equals(0));

    // الانتقال لصف تاني لازم يصفّر الأول فورًا.
    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('cashier'))),
    );
    await tester.pumpAndSettle();
    expect(colorOf(tester, 'menu').a, equals(0));
    expect(colorOf(tester, 'cashier').a, greaterThan(0));

    await gesture.removePointer();
  });

  testWidgets('toolbar icon buttons hover independently', (tester) async {
    Widget button(String key, IconData icon) => DesktopToolbarIconButton(
      key: ValueKey(key),
      icon: icon,
      tooltip: key,
      onPressed: () {},
    );

    Color? boxColor(String key) {
      final animated = find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(AnimatedContainer),
      );
      final deco =
          tester.widget<AnimatedContainer>(animated.first).decoration;
      return deco is BoxDecoration ? deco.color : null;
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: SaytarlyTheme.light(),
        home: Scaffold(
          body: Row(
            children: [
              button('view', Icons.grid_view_rounded),
              button('refresh', Icons.refresh),
            ],
          ),
        ),
      ),
    );

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(5, 5));
    await tester.pump();

    await gesture.moveTo(tester.getCenter(find.byKey(const ValueKey('view'))));
    await tester.pumpAndSettle();
    expect(boxColor('view')!.a, greaterThan(0));
    expect(boxColor('refresh')!.a, equals(0));

    await gesture.moveTo(
      tester.getCenter(find.byKey(const ValueKey('refresh'))),
    );
    await tester.pumpAndSettle();
    expect(boxColor('view')!.a, equals(0));
    expect(boxColor('refresh')!.a, greaterThan(0));

    await gesture.removePointer();
  });
}
