import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:saytarly/core/database/db_helper.dart';
import 'package:saytarly/core/services/lan_backup_server.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/utils/money.dart';
import 'package:saytarly/core/utils/theme/cubit/theme_cubit.dart';
import 'package:saytarly/saytarly.dart';
import 'package:saytarly/Features/activation/data/license_manager.dart';
import 'package:saytarly/Features/activation/presentation/screens/activation_screen.dart';

/// Should the app require a device activation code before opening?
///
/// When `true`, the license flow from the [Features/activation] feature runs
/// at startup: no license → ActivationScreen, expired → renewal screen.
/// When `false` (development/open build), startup continues straight to app.
const bool kRequireActivation = false;

/// App-level one-time initialization used by `_bootstrap()` in main.dart.
///
/// This file is the FEATURE APP bootstrap — everything app-specific
/// (SQLite init, data migrations, background servers, license gates)
/// lives here and stays out of the core.
abstract class AppBootstrap {
  static _ActivationGateInfo? _pendingGate;

  /// Runs all init steps. Returns `true` when the normal app [SaytarlyApp]
  /// should run, or `false` when the activation gate widget is pending.
  static Future<bool> init() async {
    // ── Desktop SQLite FFI ───────────────────────────────────────────────────
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    try {
      await DBHelper.initDB();
      await DBHelper.addRemoteActivationTable();
    } catch (e, s) {
      debugPrint('🔥 DB init error: $e');
      debugPrint('$s');
    }

    // ── Currency symbol from business settings (single load at startup) ─────
    try {
      await Money.load();
    } catch (e) {
      debugPrint('Money.load notice: $e');
    }

    // ── Local network backup server (desktop only) ──────────────────────────
    if (Platform.isWindows || Platform.isLinux) {
      try {
        await LanBackupServer.start();
      } catch (e) {
        debugPrint('LanBackupServer start notice: $e');
      }
    }

    // ── Legacy database migrations (kept for upgraded installs) ─────────────
    try {
      await DBHelper.addPaidColumnToSalaries();
      await DBHelper.addSupervisorIdColumn();
      await DBHelper.addSupervisorShiftIdColumn();
      await DBHelper.addTemperatureColumn();
    } catch (e, s) {
      debugPrint('🔥 DB migration error: $e');
      debugPrint('$s');
    }

    // ── Activation gate ──────────────────────────────────────────────────────
    if (kRequireActivation) {
      try {
        final deviceHash = await DeviceFingerprint.deviceId();
        final license = await LicenseManager.loadAndCheckLicense(deviceHash);
        if (license.status == LicenseStatus.none ||
            license.status == LicenseStatus.expired) {
          _pendingGate = _ActivationGateInfo(
            deviceId: deviceHash,
            isExpired: license.status == LicenseStatus.expired,
          );
          return false;
        }
      } catch (e) {
        debugPrint('Activation gate note (continuing): $e');
      }
    }

    return true;
  }

  /// Widget to run instead of [SaytarlyApp] when the activation gate is active.
  static Widget? get gateWidget {
    final info = _pendingGate;
    if (info == null) return null;
    return ActivationGateApp(
      deviceId: info.deviceId,
      isExpired: info.isExpired,
    );
  }
}

class _ActivationGateInfo {
  final String deviceId;
  final bool isExpired;
  const _ActivationGateInfo({required this.deviceId, required this.isExpired});
}

/// Root widget used when the app is locked by the activation gate.
///
/// Keeps the core [ThemeCubit] so the gate UI stays consistent; after a
/// successful activation the normal [SaytarlyApp] is launched in its place.
class ActivationGateApp extends StatelessWidget {
  final String deviceId;
  final bool isExpired;

  const ActivationGateApp({
    super.key,
    required this.deviceId,
    required this.isExpired,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ThemeCubit>(
      create: (_) => ThemeCubit(),
      child: Builder(builder: (context) {
        return BlocBuilder<ThemeCubit, ThemeMode>(builder: (context, mode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            themeMode: mode,
            theme: Theme.of(context),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: ActivationScreen(
                isExpired: isExpired,
                onActivated: () {
                  // Successful activation → launch the real app.
                  runApp(const SaytarlyApp());
                },
              ),
            ),
          );
        });
      }),
    );
  }
}
