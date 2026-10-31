import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/design/saytarly_theme.dart';
import 'package:saytarly/core/desktop/desktop.dart';

void main() {
  testWidgets('sidebar page choices stay inside the shell', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    var legacyOnTapCalls = 0;
    var actionCalls = 0;

    // Mirrors the admin dashboard's action map (including the runtime cast
    // that turns its `page` entry into a WidgetBuilder).
    final action = <String, dynamic>{
      'id': 'reports',
      'onTap': () => legacyOnTapCalls++,
      'page':
          (BuildContext _) =>
              const Scaffold(body: Center(child: Text('Shell reports'))),
    };

    await tester.pumpWidget(
      MaterialApp(
        theme: SaytarlyTheme.light(fontFamily: 'Inter'),
        home: MediaQuery(
          // Keep the built-in test font (Ahem) from overflowing the sidebar.
          data: const MediaQueryData(textScaler: TextScaler.linear(0.5)),
          child: DesktopShell(
            navigatorKey: navigatorKey,
            placeName: 'Test place',
            groups: [
              DesktopNavGroup(
                items: [
                  const DesktopNavItem(
                    id: 'home',
                    label: 'Home',
                    icon: Icons.home_outlined,
                  ),
                  DesktopNavItem(
                    id: action['id'] as String,
                    label: 'Reports',
                    icon: Icons.bar_chart_outlined,
                    // A page item may keep a legacy onTap (used by dashboard
                    // tiles); the sidebar must still route through the shell
                    // and prefer pageBuilder instead of opening it fullscreen.
                    onTap: action['onTap'] as VoidCallback,
                    pageBuilder: action['page'] as WidgetBuilder?,
                  ),
                  DesktopNavItem(
                    id: 'action',
                    label: 'Action',
                    icon: Icons.bolt_outlined,
                    onTap: () => actionCalls++,
                  ),
                ],
              ),
            ],
            activeId: 'home',
            title: 'Home title',
            child: const Center(child: Text('Home body')),
          ),
        ),
      ),
    );

    expect(find.text('Home body'), findsOneWidget);

    await tester.tap(find.text('Reports'));
    await tester.pumpAndSettle();

    expect(legacyOnTapCalls, 0);
    expect(find.text('Shell reports'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Home title'), findsNothing);
    expect(navigatorKey.currentState!.canPop(), isTrue);

    // Plain actions still run through the shell without opening a page.
    await tester.tap(find.text('Action'));
    await tester.pumpAndSettle();
    expect(actionCalls, 1);
    expect(find.text('Shell reports'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Home body'), findsOneWidget);
    expect(find.text('Home title'), findsOneWidget);
    expect(navigatorKey.currentState!.canPop(), isFalse);
  });
}
