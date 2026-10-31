import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/design/saytarly_theme.dart';
import 'package:saytarly/core/desktop/desktop.dart';

void main() {
  testWidgets('command palette supports arrow navigation and Enter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    DesktopNavItem? selected;

    await tester.pumpWidget(
      MaterialApp(
        theme: SaytarlyTheme.light(fontFamily: 'Inter'),
        home: Builder(
          builder:
              (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      selected = await DesktopCommandPalette.show(
                        context,
                        groups: const [
                          DesktopNavGroup(
                            items: [
                              DesktopNavItem(
                                id: 'one',
                                label: 'First',
                                icon: Icons.looks_one_outlined,
                              ),
                              DesktopNavItem(
                                id: 'two',
                                label: 'Second',
                                icon: Icons.looks_two_outlined,
                              ),
                              DesktopNavItem(
                                id: 'three',
                                label: 'Third',
                                icon: Icons.looks_3_outlined,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(selected?.id, 'three');
  });
}
