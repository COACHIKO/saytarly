import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saytarly/core/localization/messages.dart';
import 'package:saytarly/core/updater/release_info.dart';
import 'package:saytarly/core/updater/update_dialog.dart';

void main() {
  testWidgets('update prompt renders and can be cancelled', (tester) async {
    Str.setLocale(const Locale('ar'));
    final release = GithubRelease(
      id: 1,
      tagName: 'windows-9.9.9.9',
      name: 'Saytarly Windows 9.9.9.9',
      notes: 'إصلاحات وتحسينات جديدة',
      htmlUrl: 'https://example.com',
      assets: [
        ReleaseAsset(
          id: 10,
          name: 'saytarly_windows_9.9.9.9.zip',
          url: 'https://example.com/zip',
          browserDownloadUrl: 'https://example.com/zip',
          size: 20 * 1024 * 1024,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showUpdatePrompt(
              context: context,
              currentVersion: '2.1.0.0',
              release: release,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('نسخة جديدة متاحة'), findsOneWidget);
    expect(find.text('9.9.9.9'), findsWidgets);
    expect(find.text('تحميل التحديث'), findsOneWidget);
    expect(find.text('20.0 MB'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('لاحقًا'));
    await tester.pumpAndSettle();
    expect(find.text('تحميل التحديث'), findsNothing);
  });

  testWidgets('rollback prompt lists older versions and confirms', (
    tester,
  ) async {
    Str.setLocale(const Locale('ar'));
    final older = [
      GithubRelease(
        id: 1,
        tagName: 'windows-1.0.0.1',
        name: 'Saytarly Windows 1.0.0.1',
        notes: 'fixes',
        htmlUrl: 'https://example.com',
        assets: [
          ReleaseAsset(
            id: 1,
            name: 'a.zip',
            url: 'https://example.com/a.zip',
            browserDownloadUrl: 'https://example.com/a.zip',
            size: 10 * 1024 * 1024,
          ),
        ],
        publishedAt: DateTime(2026, 11, 1),
      ),
      GithubRelease(
        id: 2,
        tagName: 'windows-1.0.0.0',
        name: 'Saytarly Windows 1.0.0.0',
        notes: 'first',
        htmlUrl: 'https://example.com',
        assets: const [],
        publishedAt: DateTime(2026, 10, 1),
      ),
    ];

    GithubRelease? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await showRollbackPrompt(
                context: context,
                currentVersion: '1.0.0.2',
                releases: older,
              );
            },
            child: const Text('rollback'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('rollback'));
    await tester.pumpAndSettle();

    expect(find.text('الرجوع لنسخة أقدم'), findsOneWidget);
    expect(find.text('1.0.0.1'), findsWidgets);
    expect(find.text('1.0.0.0'), findsWidgets);

    // اختار النسخة 1.0.0.0 وأكّد
    await tester.tap(find.text('1.0.0.0'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الرجوع للنسخة 1.0.0.0'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.tagName, 'windows-1.0.0.0');
    expect(tester.takeException(), isNull);
  });
}
