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

## Environment files

`.env` / `.env.example` are leftovers from the original VoIP template
(config + `flutter_dotenv`, which has been pruned). The cafe system does not
read them; delete both if you don't plan to reintroduce env-file config.
