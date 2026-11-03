import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(
    body: Center(child: SizedBox(width: 220, height: 110, child: child)),
  ),
);

void main() {
  testWidgets('halo overlay above a card builds without assertions', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(color: Colors.white),
            Positioned(
              top: -2,
              right: -2,
              bottom: -2,
              left: -2,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.orange, width: 2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('old negative-margin halo asserts (regression guard)', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Stack(
          children: [
            Container(color: Colors.white),
            Positioned.fill(
              child: IgnorePointer(
                child: Container(margin: const EdgeInsets.all(-2)),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });
}
