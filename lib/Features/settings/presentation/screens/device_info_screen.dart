import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saytarly/core/desktop/desktop.dart';
import 'package:saytarly/core/utils/DeviceFingerprint.dart';
import 'package:saytarly/core/localization/messages.dart';

// جسم الموبايل وجسم الويندوز في ملفين منفصلين — نفس الـ State ونفس المنطق.
part 'mobile/device_info_screen_mobile_body.dart';
part 'desktop/device_info_screen_windows_body.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  String _cpu = '...';
  String _board = '...';
  String _disk = '...';
  String _hash = '...';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cpu = await DeviceFingerprint.cpuId();
    final board = await DeviceFingerprint.motherboardId();
    final disk = await DeviceFingerprint.diskId();
    final hash = await DeviceFingerprint.deviceId();

    if (!mounted) return;
    setState(() {
      _cpu = cpu;
      _board = board;
      _disk = disk;
      _hash = hash;
      _loading = false;
    });
  }

  String get _fullReport => '''
CPU ID      : $_cpu
BOARD ID    : $_board
DISK ID     : $_disk
DEVICE HASH : $_hash
''';

  @override
  Widget build(BuildContext context) {
    return AppPlatform.isDesktop(context)
        ? _buildWindowsBody(context)
        : _buildMobileBody(context);
  }
}
