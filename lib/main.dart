import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app/bloc_observer.dart';
import 'core/app/connectivity_controller.dart';
import 'core/desktop/windows_tray.dart';
import 'core/di/dependency_injection.dart';
import 'core/services/shared_pref/shared_pref.dart';
import 'app_bootstrap.dart';
import 'saytarly.dart';

/// Process start time — useful for instrumentation in feature apps.
final DateTime appStartedAt = DateTime.now();

/// Zone is used so all uncaught async errors are routed to one handler.
Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    () async {
      await _bootstrap();
    },
    (error, stackTrace) async {
      // This handler must NEVER throw.
      try {
        debugPrint('🔴 UNCAUGHT ASYNC ERROR: $error');
        debugPrint('Stack: $stackTrace');
      } catch (_) {}
    },
  );
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework error traps.
  FlutterError.onError = (FlutterErrorDetails details) {
    try {
      debugPrint('🟠 FLUTTER ERROR: ${details.exceptionAsString()}');
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    } catch (_) {}
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    try {
      debugPrint('🟠 PLATFORM ERROR: $error');
    } catch (_) {}
    return true;
  };

  Bloc.observer = AppBlocObserver();

  await SharedPref.init();

  // Date/time formatting is used by reports, shifts, receipts and the
  // dashboard. Load both supported locales once so DateFormat never throws.
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');

  // Best-effort connection watcher; must never block startup.
  unawaited(ConnectivityController.instance.init());

  await setupInjector();

  // App-level bootstrap (databases, migrations, servers, gates).
  await AppBootstrap.init();
  final gate = AppBootstrap.gateWidget;

  runApp(gate ?? const SaytarlyApp());

  // The tray icon is created after the first frame so the native plugins and
  // the saved language are fully ready.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(WindowsTray.instance.setupTray());
  });
}
