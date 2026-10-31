import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/design/saytarly_theme.dart';
import 'package:saytarly/core/desktop/desktop.dart';

void main() {
  testWidgets('sidebar does not overflow while collapsing or expanding', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: SaytarlyTheme.light(fontFamily: 'Inter'),
        home: DesktopShell(
          placeName: 'Saytarly Test Restaurant',
          roleLabel: 'مدير النظام',
          userName: 'Test User',
          userRole: 'مدير النظام',
          groups: const [
            DesktopNavGroup(
              title: 'نظرة عامة',
              items: [
                DesktopNavItem(
                  id: 'home',
                  label: 'لوحة التحكم',
                  icon: Icons.space_dashboard_outlined,
                ),
              ],
            ),
            DesktopNavGroup(
              title: 'المتابعة',
              items: [
                DesktopNavItem(
                  id: 'reports',
                  label: 'تقارير مفصلة',
                  icon: Icons.bar_chart,
                ),
                DesktopNavItem(
                  id: 'materials',
                  label: 'خامات الناقصه',
                  icon: Icons.local_drink,
                  badge: 12,
                ),
              ],
            ),
          ],
          activeId: 'home',
          title: 'لوحة التحكم',
          child: const Center(child: Text('Home body')),
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('طي القائمة'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.takeException(), isNull);
    // The collapsed rail's expand handle has a deliberately endless breathing
    // glow, so drive fixed frames instead of pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('فتح القائمة'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
  });
}
