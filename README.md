# Saytarly

**Saytarly** — a Flutter desktop-first cafe management suite (Windows/Android)
created by **Saytarly**: cashier POS, tables, PlayStation sessions, top-up
machine, cards (internet cards), debts/credit reporting, staff shifts, users,
reports, PDF printing, and a Supabase-backed license/activation flow — built
on a reusable core template.

## Getting started

```bash
flutter pub get
flutter run -d windows          # or: flutter build windows --debug
flutter test                    # unit tests (localization runtime)
```

## Brand and preferences

- The SAYTARLY identity is fixed: deep navy `#0B1F3A`, Control Blue `#1677FF`,
  cool-gray working surfaces and semantic status colours.
- Users choose **light or dark mode** only; there is no arbitrary accent-colour
  override.
- Arabic and English are first-class languages. Switch from **Settings →
  Language**, or from the language chip on the login screen. The choice is
  persisted and the whole app rebuilds in the selected direction and font.
- Desktop typography: Inter for Latin, Alexandria for Arabic.

## Feature structure (conventions)

Every feature lives under `lib/Features/<feature>/`:

```
lib/Features/<feature>/
  data/          # models, repos, local datasources, SQL helpers
  presentation/
    screens/     # screens + <screen>_windows_body.dart / _mobile_body.dart parts
    cubits/      # Bloc/Cubit + states (ported away from ChangeNotifier)
```

`part of` bodies may not contain `import` directives — imports belong to the
parent screen library file.

## Localization (source-as-key, no gen-l10n)

There is **no gen-l10n and no `flutter_localizations` lookup**. Arabic is
the source language: its literal is the string AND the lookup key. English is
written by hand.

```dart
// anywhere — no BuildContext needed:
Text('إضافة مشروبات'.tr())
Text('فاتورة #{v1}'.tr({'v1': invoiceId}))   // {name} placeholders
```

Workflow when you add a new string:

1. Write the Arabic literal with `.tr()` (placeholders become `{v1}`, `{v2}`…).
2. Run the extractor — it registers new keys and regenerates ARBs + the
   compiled map; it is idempotent (already-`.tr()`-wrapped literals are not
   re-wrapped):
   ```bash
   dart run tool/l10n_extract.dart
   ```
3. Fill English values in `lib/l10n/app_en.arb` (or append to
   `tool/l10n_en_dict/*.txt` and re-run the translate tool, then the
   extractor again to recompile):
   ```bash
   dart run tool/l10n_en_translate.dart
   dart run tool/l10n_extract.dart
   ```

Tooling cheat-sheet:

| Tool | Purpose |
|---|---|
| `tool/l10n_extract.dart` | Scans sources, wraps new `.tr()` keys, rebuilds `app_ar.arb`/`app_en.arb` and `lib/core/localization/generated/app_messages.dart`. Skips unsafe contexts (case labels, `==` comparisons, ternary else-branches, map keys, SQL/HTML args). |
| `tool/l10n_en_translate.dart` | Merges hand-written Arabic→English dictionary `tool/l10n_en_dict/*.txt` (tab-separated) into `app_en.arb`, preserving `app_ar.arb` key order and validates placeholders. |
| `tool/l10n_pending_dump.dart` | Lists untranslated keys to `build/l10n_pending.txt` for translation work. |
| `tool/l10n_en_dump.dart` | Dumps the full corpus (`build/l10n_en_compact.json`). |
| `tool/_scrub_part_imports.dart` | Removes tool-added `import` lines from `part of` files (illegal Dart; imports live in the parent). |
| `tool/_db_check.dart` | Prints the sqflite databases path and the current `xo_cafe57.db` state (users + all tables). Handy for the "login/user missing" debugging. |

Notes:

- Existing `app_en.arb` values always win over the dictionary — hand fixes
  survive re-runs.
- Untranslatable keys (SQL fragments, the HTML menu template, raw symbol rows)
  keep Arabic identity in English; the runtime falls back to Arabic text when
  an English entry is missing.

## State management

`flutter_bloc`. Screens consume `BlocBuilder/BlocConsumer`; `LocaleCubit`
pushes locale changes into the l10n runtime (`Str.setLocale`) so `.tr()` never
lags the UI. See `ARCHITECTURE.md` for the full wiring (DI, bootstrap,
connectivity, error traps).

## Tests

`test/widget_test.dart` exercises the localization runtime (fallback rules,
placeholder substitution, locale resolution) without booting the real app —
`main.dart` runs DB migrations and an activation gate and must not do work
inside tests.

## Release building & self-update

**SaytarlyMind** is the release control center — a local website (PowerShell server
+ web UI). Launch it by double-clicking `release.bat` (or
`powershell -File tool\megaming.ps1`) — it opens the browser on
`http://127.0.0.1:<port>` with the Megamind-styled dashboard.

- Pick Mobile (Android) or Windows, edit the version, increment or set the
  build number (`+1` button).
- Outputs: APK (+ optional ZIP) for mobile; build / Inno Setup installer /
  installer + ZIP for Windows. Artifacts land in `build_export\`.
- Optional GitHub upload: creates or updates a release
  (`windows-<version>` / `mobile-<version>` tags) in the repository from
  `.env` (`RELEASES_REPO`), uploads the ZIP, and includes an inline release
  manager (edit notes / delete releases / test connection) right in the page.
- The underlying engine is still `tool\release.ps1` (WinForms GUI + CLI).

The app checks `RELEASES_REPO` on startup (release builds) — Windows downloads
and replaces itself from the release ZIP then relaunches; Android opens the
release page in the browser.

`.env` (not secret-safe — do not commit real tokens):

- `MOBILE_VERSION_NUMBER`, `MOBILE_BUILD_NUMBER`
- `WINDOWS_VERSION_NUMBER`, `WINDOWS_BUILD_NUMBER`
- `GITHUB_TOKEN`, `RELEASES_REPO`, `RELEASES_TOKEN`

The build script writes these values into `pubspec.yaml`,
`windows/runner/Runner.rc`, `lib/core/updater/version_info.dart` and
`lib/core/updater/update_config.dart` before every build.
