# Architecture

This repo is **Saytarly**: `lib/core/` provides infrastructure; the
cafe management system plugs in under `lib/Features/` and calls a couple of
bootstrap hooks. Feature apps should keep the same seams.

## Boot sequence

`lib/main.dart`:

1. `runZonedGuarded` traps uncaught async errors.
2. `FlutterError.onError` + `PlatformDispatcher.instance.onError` trap
   framework errors (verbose only in `kDebugMode`).
3. `Bloc.observer = AppBlocObserver();`
4. `SharedPref.init()` — SharedPreferences singleton.
5. `ConnectivityController.instance.init()` — best-effort, never blocks.
6. `setupInjector()` — `get_it` registration (`lib/core/di/`).
7. `AppBootstrap.run()` (`lib/app_bootstrap.dart`) — feature-facing
   initialization: DB migration chain, `Money` currency engine, LAN backup
   server, license/activation gate (Supabase), cafe-specific caches.
8. `runApp(SaytarlyApp())` (`lib/saytarly.dart`).

**Rule:** the template owns steps 1–6; a feature app only touches
`AppBootstrap`.

## lib/core layout

| Folder | Responsibility |
|---|---|
| `app/` | App-level plumbing: `BlocObserver`, connectivity controller, common init helpers. |
| `constants/` | App constants. |
| `database/` | SQLite access layer + migration chain (`sqflite`/`sqflite_common_ffi` for Windows). |
| `desktop/` | Windows-desktop specifics: DPI/window helpers, tray/sidebar integration. |
| `di/` | `get_it` injector setup. |
| `localization/` | Hand-rolled l10n runtime (below). |
| `models/` | Shared cross-feature models (e.g. audit log entries). |
| `networking/` | `Dio` factory with error mapping (`pretty_dio_logger` in debug), `error_handler` models, REST client. |
| `platform/` | Cross-platform platform-type detection. |
| `routing/` | Navigation helpers/routes registry. |
| `services/` | Concretely-scoped services (`shared_pref` singleton, etc.). |
| `widgets/` | The custom widget kit (see below). |
| `utils/`, `shared/`, `common/` | Pure helpers without side effects. |

`lib/saytarly.dart` is the single `MaterialApp` wiring point: injects
`GlobalMaterialLocalizations`/`Widgets`/`Cupertino` delegates,
`Str.supportedLocales`, `Str.localeResolutionCallback`, the theme+Bloc
providers, and the desktop shell.

## Localization runtime

- **Source-as-key:** the Arabic literal is the key. `lib/l10n/app_ar.arb` is
  the identity map (val = key) and defines key order; `app_en.arb` holds
  hand-written English (or Arabic identity for deliberately untranslated
  keys: SQL fragments, the customer menu HTML template).
- `lib/core/localization/generated/app_messages.dart` is **generated** by
  `dart run tool/l10n_extract.dart` from the ARBs into
  `kMessagesAr`/`kMessagesEn` Dart maps — don't edit it.
- `lib/core/localization/messages.dart` is the runtime: `Str` holds the
  current locale (no `BuildContext` involved) and exposes
  `supportedLocales` / `localeResolutionCallback` / `setLocale`;
  the `extension StrTranslationX on String` provides `.tr(args)`.
- `LocaleCubit` (`.../cubit/locale_cubit.dart`) persists the language choice
  and calls `Str.setLocale` on every change so lookups can't lag the rebuild.
- Fallback chain English entry missing → Arabic map → the key itself.

## State management

- `flutter_bloc`; views rebuild via `BlocBuilder`/`BlocConsumer`.
- The ported cafe screens originally used `Provider`/`ChangeNotifier`; all
  are Bloc/Cubit + freezed-free plain state classes now.
- Cross-screen side effects (DB reads, prints, LAN servers) stay inside
  repos/services; cubits orchestrate them.

## Cafe system specifics (feature app layer)

- **DB:** sqlite (FFI on Windows) with an ordered migration chain in
  `lib/core/database/`; the cafe's migrations append to it.
- **Licensing/activation:** devices hold a signed device fingerprint; the
  engineer screen (`Features/activation`) generates activation codes; Supabase
  stores activation requests (trial countdown gating the cashier).
- **LAN backup:** `LanBackupServer` (shelf/shelf_router) hosts encrypted
  backups for phone clients on the same Wi-Fi; Supabase is the
  anywhere-cloud restore source.
- **Printing:** `pdf`/`printing` render invoices/reports; the QR menu page is
  a big HTML template served by the embedded web server (`web_server.dart`).
- **Money:** currency-aware amounts (EGP) formatting + ledger arithmetic via
  `Money`.

## Widget kit

`lib/core/widgets/` holds the custom desktop-first kit (window chrome,
`DesktopPageScaffold`, `DesktopToolbarIconButton`, searchable lists, numeric
pads, state cards). Feature screens must use the kit instead of raw
Material components where a desktop variant exists, pairing
`*_windows_body.dart` with `*_mobile_body.dart` part files.

## Tooling (tool/)

- `l10n_extract.dart` — scanner/wrapper/ARB-machine; idempotent; never touches
  strings in unsafe contexts (case labels, `==`, ternary else branches, map
  keys, SQL/HTML args) and never adds imports to `part of` files.
- `l10n_en_translate.dart` + `l10n_en_dict/*.txt` — dictionary merge into
  `app_en.arb` (existing values win over the dictionary).
- `l10n_pending_dump.dart` / `l10n_en_dump.dart` — corpus dumps under
  `build/`.
- `_scrub_part_imports.dart`, `_dep_audit.dart` — one-off maintenance
  utilities kept for regression checks.

## Windows build notes

- Toolchain: Flutter master `3.50.0-0.1.pre`
- `windows/CMakeLists.txt` carries a small patch: it pairs `"/await"` with the
  legacy `<experimental/coroutine>` include path where required, otherwise
  MSVC 14.51 hard-fails with STL1011. Don't revert it while building
  locally with this toolchain.
