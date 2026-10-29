import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Connection watcher backed by the connectivity_plus stream.
///
/// Exposes a [ValueNotifier<bool>][isConnected] that widgets can listen to.
class ConnectivityController {
  ConnectivityController._();

  static final ConnectivityController instance = ConnectivityController._();

  /// Notifier for connection status
  final ValueNotifier<bool> isConnected = ValueNotifier(true);

  /// Initialize connectivity monitoring
  Future<void> init() async {
    final results = await Connectivity().checkConnectivity();
    _handle(results);
    Connectivity().onConnectivityChanged.listen(_handle);
  }

  void _handle(List<ConnectivityResult> results) {
    isConnected.value =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }
}
